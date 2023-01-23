// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Created 2023-01-23

/**
 This is is the analogue equivalent of a digital logic gate.  AND, OR, NAND, NOR
 and XOR have been implemented while the analogue levels of the alpha channel have
 been maintained.  The video is always just OR-ed while the logic is fully
 implemented only in the alpha channel.  Also included is a means of masking B
 with A.  In that case the same operation as with AND is performed on the alpha
 channels, but the video is taken only from the B channel.

 In all modes the default is to premultiply the RGB by the alpha channel.  This is
 done to ensure that transparency displays as black as far as the gating is
 concerned.  However in this effect RGB can also be simply set to zero when alpha
 is zero.  This can be done independently for each channel.

 The levels of the A and B inputs can also be adjusted independently.  In mask mode
 reducing the A level to zero will fade the mask, revealing the background video in
 its entirety.  In that mode reducing the B level to zero fades the effect to black.

 There is also a means of using the highest value of A and B video's RGB components
 to create an artificial alpha channel for each channel.  The alpha value, however
 it is produced, is output for possible use by the blending logic.  Where the final
 output alpha channel is zero the video is blanked to allow for the boolean result
 to be used in external blend and DVE effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BoolBlendPlus.fx
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Boolean blend plus", "Mix", "Blend Effects", "Combines two images using an analogue equivalent of boolean logic then blends the result over background video", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (A, B, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Logic, "Boolean function", kNoGroup, 0, "AND|OR|NAND|NOR|XOR|Mask B with A");
DeclareIntParam (SetTechnique, "Blend mode", kNoGroup, 0, "Normal|Export boolean only|____________________|Darken|Multiply|Colour Burn|Linear Burn|Darker Colour|____________________|Lighten|Screen|Colour Dodge|Linear Dodge (Add)|Lighter Colour|____________________|Overlay|Soft Light|Hard Light|Vivid Light|Linear Light|Pin Light|Hard Mix|____________________|Difference|Exclusion|Subtract|Divide|____________________|Hue|Saturation|Colour|Luminosity");
DeclareFloatParam (Amount, "Blend opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Amount_A, "Amount", "A video", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (Alpha_A, "Transparency", "A video", 1, "Standard|Premultiply|Alpha from RGB");

DeclareFloatParam (Amount_B, "Amount", "B video", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (Alpha_B, "Transparency", "B video", 1, "Standard|Premultiply|Alpha from RGB)";

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define CrR   0.439
#define CrG   0.368
#define CrB   0.071

#define CbR   0.148
#define CbG   0.291
#define CbB   0.439

#define Rr_R  1.596
#define Rg_R  0.813
#define Rg_B  0.391
#define Rb_B  2.018

#define BLACK float4 (0.0.xxx, 1.0)
#define WHITE 1.0.xxxx

#define AND   0
#define OR    1
#define NAND  2
#define NOR   3
#define XOR   4
#define MASK  5

#define LUMA  float4(0.2989, 0.5866, 0.1145, 0.0)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

float4 fn_logic (float2 xy1, float2 xy2)
{
   if (IsOutOfBounds (xy1) && IsOutOfBounds (xy2))
      return (Logic == NAND) || (Logic == NOR) ? BLACK : kTransparentBlack;

   float4 vidA = ReadPixel (A, xy1);
   float4 vidB = ReadPixel (B, xy2);
   float4 retval;

   // If premultiply is not set, alpha at zero causes the RGB values to be replaced
   // with zero (absolute black).  If alpha is not available, RGB values can be used
   // instead but premutliply is not available in that mode.

   if (Alpha_A == 1) { vidA.rgb *= vidA.a; }
   else if (Alpha_A == 2) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
   }
   else if (vidA.a == 0.0) vidA = kTransparentBlack;

   if (Logic == MASK) {
      // The mask operation differs slightly from a simple boolean, in that only
      // the B video will be displayed after it's masked and not a mix of A and B.

      if (Alpha_B == 2) {
         vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
         vidB.a *= vidB.a;
      }

      vidB *= Amount_B;

      retval = float4 (vidB.rgb, min (vidA.a, vidB.a));

      // The premultiply for B is done now to clean up the video after masking.

      if (Alpha_B == 1) { retval.rgb *= retval.a; }
      else if (retval.a == 0.0) retval = kTransparentBlack;

      return lerp (vidB, retval, Amount_A);
   }

   if (Alpha_B == 1) { vidB.rgb *= vidB.a; }
   else if (Alpha_B == 2) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
   }
   else if (vidB.a == 0.0) vidB = kTransparentBlack;

   vidA *= Amount_A;
   vidB *= Amount_B;

   // In all boolean modes the video is initially OR-ed.  This is so that whatever is
   // subsequently done to the alpha channel, appropriate video will be output.

   retval = max (vidA, vidB);

   // The boolean logic is now applied to the alpha channel only.  Nothing needs to be
   // done if the logic setting is OR, because we already have that result.

   if (Logic == AND) retval.a = min (vidA.a, vidB.a);
   if (Logic == NAND) retval.a = 1.0 - min (vidA.a, vidB.a);
   if (Logic == NOR) retval.a = 1.0 - retval.a;
   if (Logic == XOR) retval.a *= 1.0 - min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = kTransparentBlack;         // Blanks the video if alpha is zero

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Normal)
{
   float4 Fgnd = fn_logic (uv1, uv2);

   float4 retval = lerp (ReadPixel (Bg, uv3), Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Export)
{
   float4 retval = fn_logic (uv1, uv2);

   return lerp (0.0.xxxx, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_0)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 1 -----------------------------------------//

DeclareEntryPoint (Darken)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Multiply)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb *= Bgnd.rgb;

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (ColourBurn)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   if (Fgnd.r > 0.0) Fgnd.r = 1.0 - ((1.0 - Bgnd.r) / Fgnd.r);
   if (Fgnd.g > 0.0) Fgnd.g = 1.0 - ((1.0 - Bgnd.g) / Fgnd.g);
   if (Fgnd.b > 0.0) Fgnd.b = 1.0 - ((1.0 - Bgnd.b) / Fgnd.b);

   float4 retval = lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LinearBurn)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = max (Fgnd.rgb + Bgnd.rgb - 1.0.xxx, 0.0.xxx);

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (DarkerColour)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) > luma) Fgnd.rgb = Bgnd.rgb;

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_1)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 2 -----------------------------------------//

DeclareEntryPoint (Lighten)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Screen)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (ColourDodge)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   Fgnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   Fgnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   float4 retval = lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LinearDodge)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LighterColour)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float  luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) < luma) Fgnd.rgb = Bgnd.rgb;

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_2)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 3 -----------------------------------------//

DeclareEntryPoint (Overlay)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = 1.0.xxx - 2.0 * (1.0.xxx - Fgnd.rgb) * (1.0.xxx - Bgnd.rgb);

   Fgnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   float4 retval = lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (SoftLight)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float3 retMax = (2.0 * Fgnd.rgb) - 1.0.xxx;
   float3 retMin = Bgnd.rgb * (retMax * (1.0.xxx - Bgnd.rgb) + 1.0.xxx);

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   Fgnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   float4 retval = lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (HardLight)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (1.0.xxx - 2.0 * (1.0.xxx - Bgnd.rgb) * (1.0.xxx - Fgnd.rgb));

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (VividLight)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float3 retMax, retMin;

   retMin.r = (Fgnd.r == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.r) / (2.0 * Fgnd.r)), 0.0);
   retMin.g = (Fgnd.g == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.g) / (2.0 * Fgnd.g)), 0.0);
   retMin.b = (Fgnd.b == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.b) / (2.0 * Fgnd.b)), 0.0);

   retMax.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (2.0 * (1.0 - Fgnd.r));
   retMax.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (2.0 * (1.0 - Fgnd.g));
   retMax.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (2.0 * (1.0 - Fgnd.b));

   retMin = min (retMin, (1.0).xxx);
   retMax = min (retMax, (1.0).xxx);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   float4 retval = lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LinearLight)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);
   float4 retMin = max ((2.0 * Fgnd) + Bgnd - WHITE, kTransparentBlack);
   float4 retMax = min ((2.0 * Fgnd) + Bgnd - WHITE, WHITE);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (PinLight)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float3 retMax = 2.0 * Fgnd.rgb;
   float3 retMin = retMax - 1.0.xxx;

   Fgnd.r = (Bgnd.r > retMax.r) ? retMax.r : (Bgnd.r < retMin.r) ? retMin.r : Bgnd.r;
   Fgnd.g = (Bgnd.g > retMax.g) ? retMax.g : (Bgnd.g < retMin.g) ? retMin.g : Bgnd.g;
   Fgnd.b = (Bgnd.b > retMax.b) ? retMax.b : (Bgnd.b < retMin.b) ? retMin.b : Bgnd.b;

   float4 retval = lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (HardMix)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   float3 ref = 1.0.xxx - Bgnd.rgb;

   Fgnd.r = (Fgnd.r < ref.r) ? 0.0 : 1.0;
   Fgnd.g = (Fgnd.g < ref.g) ? 0.0 : 1.0;
   Fgnd.b = (Fgnd.b < ref.b) ? 0.0 : 1.0;

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_3)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 4 -----------------------------------------//

DeclareEntryPoint (Difference)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Exclusion)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (1.0.xxx - (2.0 * Fgnd.rgb)));

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Subtract)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, 0.0.xxx);

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Divide)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);

   Fgnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   Fgnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   Fgnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_4)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 5 -----------------------------------------//

DeclareEntryPoint (Hue)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.xw = (fn_rgb2hsv (Fgnd)).xw;

   float4 retval = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Saturation)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.yw = fn_rgb2hsv (Fgnd).yw;

   float4 retval = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Colour)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);
   float4 blnd = fn_rgb2hsv (Fgnd);

   blnd.x = (fn_rgb2hsv (Bgnd)).x;

   float4 retval = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Luminosity)
{
   float4 Fgnd = fn_logic (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   float4 retval = lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x);
}

