// @Maintainer jwrl
// @Released 2021-09-17
// @Author jwrl
// @Created 2021-09-17
// @see https://www.lwks.com/media/kunena/attachments/6375/TripleDVE_640.png

/**
 This is a new version of an earlier effect with the same name.  It's a combination of
 three DVEs.  The foreground DVE and bacground DVE 2 operate independently of each other.
 The foreground can be cropped with rounded corners and given a bi-colour border.  Both
 the edges and borders can be feathered, and a drop shadow can be applied.

 The master DVE takes the cropped, bordered output of DVE 1 as its input.  This means
 that it's possible to scale the background and foreground independently, then adjust
 the position and size of the cropped foreground.  New in this version is the ability
 to crop the output of the effect to sit inside the boundaries of the background video.
 This means that if your background is letterboxed, the effect can be too.

 Apart from the above, this effect is functionally identical to the earlier one but has
 another major difference.  Scaling is now done quite differently.  The settings for that
 now follow a square law, which means that although the range covered is still 0 to 10,
 the settings range from 0 to just over 3.  This has two advantages.  The first is that
 there is more control over size reduction.  The second is more subtle.  Doubling the
 scale setting doubles the area of the image.  This makes a keyframed zoom feel linear.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TripleDVE.fx
//
// Version history:
//
// Rewrite 2021-09-17 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Triple DVE";
   string Category    = "DVE";
   string SubCategory = "DVE Extras";
   string Notes       = "Foreground, background and the overall effect each have independent DVE adjustment.";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
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
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define HALF_PI       1.5707963

#define BORDER_SCALE  0.05
#define FEATHER_SCALE 0.05
#define RADIUS_SCALE  0.1

#define SHADOW_DEPTH  0.1
#define SHADOW_SCALE  0.05
#define SHADOW_SOFT   0.025
#define TRANSPARENCY  0.75

#define MINIMUM       0.0001.xx

#define CENTRE        0.5.xx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (Msk, s_Mask);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropT
<
   string Group = "Crop";
   string Description = "Top";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropB
<
   string Group = "Crop";
   string Description = "Bottom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropL
<
   string Group = "Crop";
   string Description = "Left";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float CropR
<
   string Group = "Crop";
   string Description = "Right";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

float CropRadius
<
   string Group = "Crop";
   string Description = "Rounding";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BorderFeather
<
   string Group = "Crop";
   string Description = "Edge softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float4 BorderColour_1
<
   string Group = "Border";
   string Description = "Colour 1";
   bool SupportsAlpha = false;
> = { 0.855, 0.855, 0.855, 1.0 };

float4 BorderColour_2
<
   string Group = "Border";
   string Description = "Colour 2";
   bool SupportsAlpha = false;
> = { 0.345, 0.655, 0.926, 1.0 };

float Shadow
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float ShadowSoft
<
   string Group = "Shadow";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float ShadowX
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float ShadowY
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.5;

float PosX_1
<
   string Group = "Fill DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY_1
<
   string Group = "Fill DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Scale_1
<
   string Group = "Fill DVE";
   string Description = "Master scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float ScaleX_1
<
   string Group = "Fill DVE";
   string Description = "Scale X";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float ScaleY_1
<
   string Group = "Fill DVE";
   string Description = "Scale Y";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float PosX_2
<
   string Group = "Background DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY_2
<
   string Group = "Background DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Scale_2
<
   string Group = "Background DVE";
   string Description = "Master scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float ScaleX_2
<
   string Group = "Background DVE";
   string Description = "Scale X";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float ScaleY_2
<
   string Group = "Background DVE";
   string Description = "Scale Y";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float PosX_3
<
   string Group = "Foreground DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float PosY_3
<
   string Group = "Foreground DVE";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Scale_3
<
   string Group = "Foreground DVE";
   string Description = "Master scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float ScaleX_3
<
   string Group = "Foreground DVE";
   string Description = "Scale X";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float ScaleY_3
<
   string Group = "Foreground DVE";
   string Description = "Scale Y";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float Amt_3
<
   string Group = "Foreground DVE";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Blanking
<
   string Description = "Crop image to background";
   string Enum = "No,Yes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return BdrPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_crop (float2 uv : TEXCOORD0) : COLOR
{
   float adjust = max (0.0, max (CropL - CropR, CropT - CropB));

   float2 aspect  = float2 (1.0, _OutputAspectRatio);
   float2 center  = float2 (CropL + CropR, CropT + CropB) / 2.0;
   float2 border  = max (0.0, BorderWidth * BORDER_SCALE - adjust) * aspect;
   float2 feather = max (0.0, BorderFeather * FEATHER_SCALE - adjust) * aspect;
   float2 F_scale = max (MINIMUM, feather * 2.0);
   float2 S_scale = F_scale + max (0.0, ShadowSoft * SHADOW_SOFT - adjust) * aspect;
   float2 outer_0 = float2 (CropR, CropB) - center;
   float2 outer_1 = max (0.0.xx, outer_0 + feather);
   float2 outer_2 = outer_1 + border;

   float radius_0 = CropRadius * RADIUS_SCALE;
   float radius_1 = min (radius_0 + feather.x, min (outer_1.x, outer_1.y / _OutputAspectRatio));
   float radius_2 = radius_1 + border.x;

   float2 inner   = max (0.0.xx, outer_1 - radius_1 * aspect);
   float2 xy = abs (uv - center);
   float2 XY = (xy - inner) / aspect;

   float scope = distance (XY, 0.0.xx);

   float4 Mask = EMPTY;

   if (all (xy < outer_1)) {
      Mask.r = min (1.0, min ((outer_1.y - xy.y) / F_scale.y, (outer_1.x - xy.x) / F_scale.x));

      if (all (xy >= inner)) {
         if (scope < radius_1) { Mask.r = min (1.0, (radius_1 - scope) / F_scale.x); }
         else Mask.r = 0.0;
      }
   }

   outer_0  = max (0.0.xx, outer_0 + border);
   radius_0 = min (radius_0 + border.x, min (outer_0.x, outer_0.y / _OutputAspectRatio));
   border   = max (MINIMUM, max (border, feather));
   adjust   = sin (min (1.0, CropRadius * 20.0) * HALF_PI);

   if (all (xy < outer_2)) {
      Mask.g = min (1.0, min ((outer_0.y - xy.y) / border.y, (outer_0.x - xy.x) / border.x));
      Mask.b = min (1.0, min ((outer_2.y - xy.y) / F_scale.y, (outer_2.x - xy.x) / F_scale.x));
      Mask.a = min (1.0, min ((outer_2.y - xy.y) / S_scale.y, (outer_2.x - xy.x) / S_scale.x));

      if (all (xy >= inner)) {
         if (scope < radius_2) {
            Mask.g = lerp (Mask.g, min (1.0, (radius_0 - scope) / border.x), adjust);
            Mask.b = lerp (Mask.b, min (1.0, (radius_2 - scope) / F_scale.x), adjust);
            Mask.a = lerp (Mask.a, min (1.0, (radius_2 - scope) / S_scale.x), adjust);
         }
         else Mask.gba = lerp (Mask.gba, 0.0.xxx, adjust);
      }
   }

   adjust  = sin (min (1.0, BorderWidth * 10.0) * HALF_PI);
   Mask.gb = lerp (0.0.xx, Mask.gb, adjust);
   Mask.a  = lerp (0.0, Mask.a, Shadow * TRANSPARENCY);

   return Mask;
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 posn_Factor = float2 (PosX_3, 1.0 - PosY_3);
   float2 scaleFactor = max (MINIMUM, Scale_3 * float2 (ScaleX_3, ScaleY_3));

   float2 xy1 = (uv3 - posn_Factor) / scaleFactor + CENTRE;
   float2 xy2 = (uv3 - float2 (PosX_2, 1.0 - PosY_2)) / max (MINIMUM, Scale_2 * float2 (ScaleX_2, ScaleY_2)) + CENTRE;
   float2 xy3 = (uv3 - posn_Factor) / scaleFactor + CENTRE;
   float2 xy4 = xy3 - (float2 (ShadowX / _OutputAspectRatio, -ShadowY) * scaleFactor * SHADOW_DEPTH);

   xy1 = (xy1 - float2 (PosX_1, 1.0 - PosY_1)) / max (MINIMUM, Scale_1 * float2 (ScaleX_1, ScaleY_1)) + CENTRE;

   float4 Fgnd = BdrPixel (s_Foreground, xy1);
   float4 Bgnd = GetPixel (s_Background, xy2);
   float4 Mask = GetPixel (s_Mask, xy3);

   float3 Bgd = Overflow (xy4) ? Bgnd.rgb : Bgnd.rgb * (1.0 - GetPixel (s_Mask, xy4).w);

   float4 Colour = lerp (BorderColour_2, BorderColour_1, Mask.y);
   float4 retval = lerp (float4 (Bgd, Bgnd.a), Colour, Mask.z);

   retval = lerp (retval, Fgnd, Mask.x);

   return Blanking && Overflow (uv2) ? EMPTY : lerp (Bgnd, retval, Amt_3);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Triple_DVE
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 < string Script = "RenderColorTarget0 = Msk;"; > ExecuteShader (ps_crop)
   pass P_4 ExecuteShader (ps_main)
}

