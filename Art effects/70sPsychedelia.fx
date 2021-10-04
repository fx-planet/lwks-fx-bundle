// @Maintainer jwrl
// @Released 2021-07-26
// @Author jwrl
// @Created 2021-07-26
// @see https://www.lwks.com/media/kunena/attachments/6375/70s_psych_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Contours_7_2016-08-16.png

/**
 70s Psychedelia (70sPsychedelia.fx) creates a wide range of contouring effects from your
 original image.  Mixing over the original image can be adjusted from 0% to 100%, and the
 hue, saturation, and contour pattern can be tweaked.  The contours can also be smudged
 by a variable amount.

 This is an entirely original effect, but feel free to do what you will with it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 70sPsychedelia.fx
//
// Version history:
//
// Rewrite 2021-07-26jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "70s Psychedelia";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "An extreme highly adjustable posterization effect";
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
texture TEXTURE;                      \
                                      \
sampler SAMPLER = sampler_state       \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
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
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY      0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LUMA_VAL   float3 (0.3, 0.59, 0.11)
#define HUE        float3 (1.0, 2.0 / 3.0, 1.0 / 3.0)

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Contours, s_Contours);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Pattern mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Contouring
<
   string Description = "Contour level";
   float MinVal = 0.0;
   float MaxVal = 12.0;
> = 12.0;

float Smudge
<
   string Description = "Smudger";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

float4 ColourOne
<
   string Group = "Colours";
   string Description = "Colour one";
   bool SupportsAlpha = true;
> = { 1.0, 0.0, 0.0, 1.0 };

float4 ColourTwo
<
   string Group = "Colours";
   string Description = "Colour two";
   bool SupportsAlpha = true;
> = { 0.0, 1.0, 0.0, 1.0 };

float4 ColourBase
<
   string Group = "Colours";
   string Description = "Base colour";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 1.0, 1.0 };

float HueShift
<
   string Group = "Colours";
   string Description = "Hue";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Saturation
<
   string Group = "Colours";
   string Description = "Saturation";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Gain
<
   string Group = "Colours";
   string Description = "Gain";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_contour (float2 uv : TEXCOORD1) : COLOR
{
   float angle = 0.0;

   // The first thing that is done is to blur the image slightly.  This is done to
   // minimise any noise, aliassing, or other video artefacts before contouring.

   float2 halftex = float2 (1.0, _OutputAspectRatio) / (_OutputWidth + _OutputWidth);
   float2 scale   = halftex * 4.25;
   float2 xy, xy1 = uv + halftex;

   float4 retval = GetPixel (s_Input, uv);

   for (int i = 0; i < 12; i++) {
      sincos (angle, xy.y, xy.x);
      xy *= scale;
      retval += GetPixel (s_Input, xy + xy1);
      angle += 30.0;
   }

   retval /= 13.0;

   // The next block of code creates the contours, mixing the three colours

   float amtC = max (Contouring, 0.0) + 0.325;
   float Col1 = frac ((0.5 + retval.r + retval.b) * 2.242 * amtC);
   float Col2 = frac ((0.5 + retval.g) * amtC);

   float3 rgb = max (ColourBase, max ((ColourOne * Col1), (ColourTwo * Col2))).rgb;

   rgb += min (ColourBase, min (ColourOne * Col1, ColourTwo * Col2)).rgb;
   rgb /= 2.0;

   // This is a synthetic luminance value to preserve contrast when using
   // heavily saturated colours.

   float luma  = saturate (Col1 * 0.333333 + Col2 * 0.666667);

   // From here on we use a modified version of RGB-HSV-RGB conversion to process
   // the hue and saturation adjustments.  The V component is replaced with the
   // synthetic luma value, which enhances the contouring produced by the effect.

   float4 p = lerp (float4 (rgb.bg, -1.0, 2.0 / 3.0),
                    float4 (rgb.gb, 0.0, -1.0 / 3.0), step (rgb.b, rgb.g));
   float4 q = lerp (float4 (p.xyw, rgb.r), float4 (rgb.r, p.yzx), step (p.x, rgb.r));

   float d = q.x - min (q.w, q.y);

   float3 hsv = float3 (abs (q.z + (q.w - q.y) / (6.0 * d)), d / q.x, luma);

   // Hue shift and saturation is now adjusted using frac() to control overflow in
   // the hue.  Range limiting for saturation only needs to ensure it's positive.

   hsv.x += (clamp (HueShift, -180.0, 180.0) / 360.0) + 1.0;
   hsv.x  = frac (hsv.x);
   hsv.y *= max (Saturation, 0.0);

   // Finally we convert back to RGB, adjust the gain and get out.

   rgb = saturate (abs (frac (hsv.xxx + HUE) * 6.0 - 3.0.xxx) - 1.0.xxx);
   rgb = hsv.z * lerp (1.0.xxx, rgb, hsv.y);
   rgb = saturate (((rgb - 0.5.xxx) * Gain) + 0.5.xxx);

   return float4 (rgb, retval.a);
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd   = GetPixel (s_Input, uv1);
   float4 retval = tex2D (s_Contours, uv2);

   // The smudger is implemented as a variation on a radial blur first.  The range
   // of adjustment is limited to run between zero and an arbitrary value of 0.002.

   float2 xy1, xy2 = float2 (1.0, _OutputAspectRatio) * max (Smudge, 0.0) * 0.002;

   float angle = 0.0;

   for (int i = 0; i < 15; i++) {
      sincos (angle, xy1.x, xy1.y);    // Put sin into x component, cos into y.
      xy1 *= xy2;                      // Scale xy1 by aspect ratio and smudge amount.

      retval += tex2D (s_Contours, uv2 + xy1);   // Sample at 0 radians first, then
      retval += tex2D (s_Contours, uv2 - xy1);   // at Pi radians (180 degrees).

      xy1 *= 1.5;                      // Offset xy1 by 50% for a second sample pass.

      retval += tex2D (s_Contours, uv2 + xy1);
      retval += tex2D (s_Contours, uv2 - xy1);

      angle += 12.0;                   // Add 12 radians to the angle and go again.
   }

   // Divide the smudger result by four times the number of loop passes plus one.  This
   // value is because of the number of samples inside the loop plus the initial one.

   retval /= 61.0;

   // We then composite the result with the input image and quit.

   return lerp (Fgnd, retval, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Psychedelia
{
   pass P_1 < string Script = "RenderColorTarget0 = Contours;"; > ExecuteShader (ps_contour)
   pass P_2 ExecuteShader (ps_main)
}
