// @Maintainer jwrl
// @Released 2021-02-11
// @Author jwrl
// @Created 2020-06-03
// @see https://www.lwks.com/media/kunena/attachments/6375/WitnessProtection_640.png

/**
 This is a witness protection-style blurred or mosaic image obscuring pattern.  The mask
 used can be either oval or rectangular.  It can be adjusted in area and position and can
 be keyframed.

 The blur amount can be varied using the "Blur strength" control, and the mosaic size can
 be independently varied with the "Mosaic size" control.  This gives you the ability to
 have any mixture of the two that you could want.  The "Master pattern" control adjusts
 both simultaneously.

 Because the crop and position adjustment is done before the blur or mosaic generation,
 the edges of the blur will always blend smoothly into the background image.  For the same
 reason, mosaic tiles will never be partially cut at the edges.

 Because this effect potentially may require manually tracking motion, I'll add a few tips
 that should help.  First it's absolutely fatal to manually track frames sequentially.  If
 you do that you will inevitably produce jitter as you track.  Instead, jump to the end of
 your clip, adjust the mask position, then enable vertical and horizontal keyframing.  That
 will place a keyframe at the end of your clip.

 Now jump to the start of your clip and drag the mask in your sequence viewer to where you
 now need it to be.  That will place a keyframe at the start of your clip.  Now jump to the
 middle of the clip and again adjust the mask position.  Continue step-wise refining the
 mask position at various points in your timeline.

 At this point you should not be too precise.  Experiment.  A little experience will quickly
 guide you.  Once you are satisfied with what you have play through the clip and check for
 discrepancies.  Correct the position where necessary.  You may also choose to enable curved
 keyframe paths to help path smoothing in the effect graph display, but this can often be
 unnecessary when using this technique.

 NOTE: This effect won't handle resolution independence perfectly.  As with Lightworks'
 standard blur effects, it produces the blur and/or mosaic at the sequence resolution.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WitnessProtection.fx
//
// Version history:
//
// Updated 2021-02-11 jwrl:
// Rewrite to handle resolution independence for version 2021 and higher.
//
// Modified jwrl 2020-06-05
// Added a choice of rectangular or oval mask shapes.
// Added the ability track the mosaic sampling with the mask position.
// Fixed positional error in mosaic sampling caused by use of floor() instead of round().
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Witness protection";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "A classic witness protection effect.";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DeclareInput(TEXTURE, SAMPLER) \
 \
texture TEXTURE; \
 \
sampler SAMPLER = sampler_state \
{ \
   Texture   = <TEXTURE>; \
   AddressU  = ClampToEdge; \
   AddressV  = ClampToEdge; \
   MinFilter = Linear; \
   MagFilter = Linear; \
   MipFilter = Linear; \
}

#define DeclareTarget(TARGET, SAMPLER) \
 \
texture TARGET : RenderColorTarget; \
 \
sampler SAMPLER = sampler_state \
{ \
   Texture   = <TARGET>; \
   AddressU  = ClampToEdge; \
   AddressV  = ClampToEdge; \
   MinFilter = Linear; \
   MagFilter = Linear; \
   MipFilter = Linear; \
}

#define Execute(SHADER) {PixelShader = compile PROFILE SHADER ();}

#define EMPTY   (0.0).xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp, s_Input);

DeclareTarget (Ps_1, s_PassOne);
DeclareTarget (Ps_2, s_PassTwo);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Tracking
<
   string Group = "Protection mask";
   string Description = "Mosaic mask tracking";
   string Enum = "Off,On";
> = 0;

float Mosaic
<
   string Group = "Protection mask";
   string Description = "Mosaic size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Blurriness
<
   string Group = "Protection mask";
   string Description = "Blur strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Master
<
   string Group = "Protection mask";
   string Description = "Master pattern";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int SetTechnique
<
   string Group = "Mask size";
   string Description = "Mask shape";
   string Enum = "Rectangular,Oval";
> = 0;

float MasterSize
<
   string Group = "Mask size";
   string Description = "Master";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float SizeX
<
   string Group = "Mask size";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float SizeY
<
   string Group = "Mask size";
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosX
<
   string Description = "Mask position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float PosY
<
   string Description = "Mask position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if ((xy.x > 0.5) || (xy.y > 0.5)) return EMPTY;

   return tex2D (s, uv);
}

float2 fn_size (float M, float X, float Y)
{
   return (_OutputAspectRatio > 1.0) ? M * float2 (X / _OutputAspectRatio, Y)
                                     : M * float2 (X, Y * _OutputAspectRatio);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_rectangle_crop (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = fn_tex2D (s_Input, uv);

   float2 xy  = abs (uv - float2 (PosX, 1.0 - PosY));

   xy -= fn_size (MasterSize, SizeX, SizeY) * 0.5;

   if ((xy.x > 0.0) || (xy.y > 0.0)) retval.a = 0.0;

   return retval;
}

float4 ps_ellipse_crop (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float2 xy = (uv - float2 (PosX, 1.0 - PosY)) * 1.77245;

   xy /= fn_size (MasterSize, SizeX, SizeY);

   if (dot (xy, xy) > 1.0) retval.a = 0.0;

   return retval;
}

float4 ps_mosaic (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Master * Mosaic;

   float2 xy;

   if (amount > 0.0) {
      float2 xy1 = (Tracking == 0) ? 0.5.xx : float2 (PosX, 1.0 - PosY);

      xy = fn_size (amount * 0.1, 1.0, 1.0);
      xy = (floor ((uv - xy1) / xy) * xy) + xy1;
   }
   else xy = uv;

   return fn_tex2D (s_PassOne, xy);
}

float4 ps_blur_sub (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Master * Blurriness * 0.00772;

   float4 retval = tex2D (s_PassTwo, uv);

   if (amount <= 0.0) return retval;

   float2 xy, radius = fn_size (amount, 1.0, 1.0);

   for (int i = 0; i < 12; i++) {
      sincos ((i * 0.2617993878), xy.x, xy.y);
      xy *= radius;
      retval += fn_tex2D (s_PassTwo, uv + xy);
      retval += fn_tex2D (s_PassTwo, uv - xy);
      xy += xy;
      retval += fn_tex2D (s_PassTwo, uv + xy);
      retval += fn_tex2D (s_PassTwo, uv - xy);
   }

   return retval / 49.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgd = fn_tex2D (s_Input, uv);
   float4 retval = fn_tex2D (s_PassOne, uv);

   float amount = Master * Blurriness * 0.0193;

   if (amount > 0.0) {
      float2 xy, radius = fn_size (amount, 1.0, 1.0);

      for (int i = 0; i < 12; i++) {
         sincos ((i * 0.2617993878), xy.x, xy.y);
         xy *= radius;
         retval += fn_tex2D (s_PassOne, uv + xy);
         retval += fn_tex2D (s_PassOne, uv - xy);
         xy += xy;
         retval += fn_tex2D (s_PassOne, uv + xy);
         retval += fn_tex2D (s_PassOne, uv - xy);
      }

      retval /= 49.0;
   }
   else if ((Master * Mosaic) <= 0.0) return Bgd;

   return lerp (Bgd, retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WitnessProtection_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ps_1;"; > Execute (ps_rectangle_crop)

   pass P_2
   < string Script = "RenderColorTarget0 = Ps_2;"; > Execute (ps_mosaic)

   pass P_3
   < string Script = "RenderColorTarget0 = Ps_1;"; > Execute (ps_blur_sub)

   pass P_4 Execute (ps_main)
}

technique WitnessProtection_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Ps_1;"; > Execute (ps_ellipse_crop)

   pass P_2
   < string Script = "RenderColorTarget0 = Ps_2;"; > Execute (ps_mosaic)

   pass P_3
   < string Script = "RenderColorTarget0 = Ps_1;"; > Execute (ps_blur_sub)

   pass P_4 Execute (ps_main)
}
