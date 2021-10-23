// @Maintainer jwrl
// @Released 2021-09-09
// @Author jwrl
// @Created 2021-09-09
// @see https://www.lwks.com/media/kunena/attachments/6375/DVE_repeat_640.png

/**
 This is a 2D DVE that has been engineered from the ground up to support Lightworks
 2021.1's resolution independence.  It will also compile on version 14.5 and 2020.1
 without that ability.  It performs in the same way as the Lightworks version does,
 but with some significant differences.  First, there is no drop shadow support.
 Second, instead of the drop shadow you get a border. And third and most importantly,
 the image can be duplicated as you zoom out either directly or as a mirrored image.
 Mirroring can be horizontal or vertical only, or both axes.

 Fourth, all size adjustment now follows a square law.  The range you will see in your
 sequence is identical to what you see in the Lightworks effect, but the adjustment
 settings are from zero to the square root of ten - a little over three.  This has been
 done to make size reduction more easily controllable.

 The image that leaves the effect has a composite alpha channel built from a combination
 of the background and foreground.  If the background has transparency it will be
 preserved wherever the foreground isn't present.

 There is one final difference when compared with the Lightworks 2D DVE: the background
 can be faded to opaque black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2dDVEwithRepeats.fx
//
// Version history:
//
// Updated jwrl 2021-09-09.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "2D DVE with repeats";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "A 2D DVE that can duplicate the foreground image as you zoom out";
   bool CanSize       = true;
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

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_Background);

DefineTarget (RawFg, s_Foreground);
DefineTarget (Crop, s_Cropped);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Repeats
<
   string Description = "Repeat mode";
   string Enum = "No repeats,Repeat mirrored,Repeat duplicated,Horizontal mirror,Vertical mirror";
> = 0;

float PosX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float MasterScale
<
   string Description = "Master";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float XScale
<
   string Description = "X";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float YScale
<
   string Description = "Y";
   string Group = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float CropL
<
   string Description = "Left";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropT
<
   string Description = "Top";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropR
<
   string Description = "Right";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CropB
<
   string Description = "Bottom";
   string Group = "Crop";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Border
<
   string Description = "Width";
   string Group = "Border";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Group = "Border";
   string Description = "Border colour";
   bool SupportsAlpha = true;
> = { 0.49, 0.561, 1.0, 1.0 };

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Background
<
   string Description = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Blanking
<
   string Description = "Crop foreground to background";
   string Enum = "No,Yes";
> = 1;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return Overflow (uv) ? BLACK : tex2D (s_RawFg, uv); }

float4 ps_crop (float2 uv : TEXCOORD3) : COLOR
{
   // We first get the crop settings by scaling uv between 0 and 1 over the crop range
   // and storing it in xy.  We then adjust the range to allow for the border thickness.
   // The result is stored in xy0.

   float2 xy1 = uv - float2 (CropL, CropT);
   float2 xy2 = 1.0.xx - float2 (CropL + CropR, CropB + CropT);
   float2 xy3 = float2 (1.0, _OutputAspectRatio) * Border * 0.25;
   float2 xy4 = xy2 + xy3 + xy3;

   xy3 += xy1;

   float2 xy  = any (xy2 < 0.0) ? 2.0.xx : xy1 / xy2;
   float2 xy0 = any (xy4 < 0.0) ? 2.0.xx : xy3 / xy4;

   // With the crop range in xy we then check it for overflow and get the
   // border colour if so, otherwise we get the foreground pixel we need.

   float4 retval = Overflow (xy) ? Colour : tex2D (s_Foreground, uv);

   // If we're outside the border thickness return transparent black.

   return Overflow (xy0) ? EMPTY : retval;
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   // In the main shader we square the scale parameters to make size reduction
   // simpler.  This has the added benefit of making the area change linearly.

   float scaleX = MasterScale * MasterScale;
   float scaleY = max (1.0e-6, scaleX * YScale * YScale);

   scaleX = max (1.0e-6, scaleX * XScale * XScale);

   // Now adjust the Fg image position and store the result in xy1.

   float2 xy1 = uv3 + float2 (0.5 - PosX, PosY - 0.5);

   // Scale xy1 by the previously calculated X and Y scale factors.

   xy1.x = ((xy1.x - 0.5) / scaleX) + 0.5;
   xy1.y = ((xy1.y - 0.5) / scaleY) + 0.5;

   // If Repeats isn't set to zero (false) we perform the required image duplication.

   if (Repeats) {
      float2 xy2 = frac (xy1);               // xy2 wraps to duplicate the image.

      if (Repeats != 2) {
         float2 xy3 = 1.0.xx - abs (2.0 * (frac (xy1 / 2.0) - 0.5.xx));

         if (Repeats <= 3) xy2.x = xy3.x;    // xy2 now has horizontal mirroring.
         if (Repeats != 3) xy2.y = xy3.y;    // xy2 now has vertical mirroring.
      }

      xy1 = xy2;
   }

   // The value in xy1 is now used to index into the foreground, which is cropped
   // to transparent black outside background bounds if rerequired.  The background
   // is also recovered and mixed with opaque black inside background frame bounds.

   float4 Fgnd = Blanking && Overflow (uv2) ? EMPTY : GetPixel (s_Cropped, xy1);
   float4 noir = Overflow (uv2) ? EMPTY : BLACK;
   float4 Bgnd = lerp (noir, GetPixel (s_Background, uv2), Background);

   // The duplicated foreground is finally blended with the background.

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DVEwithRepeats
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = Crop;"; > ExecuteShader (ps_crop)
   pass P_2 ExecuteShader (ps_main)
}

