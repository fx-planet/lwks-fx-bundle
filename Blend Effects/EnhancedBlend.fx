// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Created 2023-01-23

/**
 "Enhanced blend" is a variant of the Lightworks blend effect with the option to boost the
 alpha channel (transparency) to match the blending used by title effects.  It can help
 when using titles with their inputs disconnected and used with other effects such as DVEs.
 It also closely emulates most of the Photoshop blend modes.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// User effect EnhancedBlend.fx
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Enhanced blend", "Mix", "Blend Effects", "This is a customised blend for use in conjunction with other effects.", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 2, "Crawl/Roll/Title/Image key|Video/External image|Extracted foreground");

DeclareFloatParam (Amount, "Fg Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Blend mode", kNoGroup, 0, "Normal|Export foreground only|____________________|Darken|Multiply|Colour Burn|Linear Burn|Darker Colour|____________________|Lighten|Screen|Colour Dodge|Linear Dodge (Add)|Lighter Colour|____________________|Overlay|Soft Light|Hard Light|Vivid Light|Linear Light|Pin Light|Hard Mix|____________________|Difference|Exclusion|Subtract|Divide|____________________|Hue|Saturation|Colour|Luminosity");

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

#define LUMA  float4(0.2989, 0.5866, 0.1145, 0.0)

#define DELTA_KEY 2

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

float4 initFg (float2 xy1, float2 xy2)
{
   if (IsOutOfBounds (xy1)) return kTransparentBlack;

   float4 Fgd = tex2D (Fg, xy1);

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = ReadPixel (Bg, xy2);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Normal)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (ExportAlpha)
{ return lerp (kTransparentBlack, initFg (uv1, uv2), tex2D (Mask, uv1).x); }

DeclareEntryPoint (Dummy_1)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 1 -----------------------------------------//

DeclareEntryPoint (Darken)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Multiply)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb *= Bgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (ColourBurn)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   if (Fgnd.r > 0.0) Fgnd.r = 1.0 - ((1.0 - Bgnd.r) / Fgnd.r);
   if (Fgnd.g > 0.0) Fgnd.g = 1.0 - ((1.0 - Bgnd.g) / Fgnd.g);
   if (Fgnd.b > 0.0) Fgnd.b = 1.0 - ((1.0 - Bgnd.b) / Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, min (Fgnd.rgb, 1.0.xxx), alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LinearBurn)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = max (Fgnd.rgb + Bgnd.rgb - 1.0.xxx, 0.0.xxx);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (DarkerColour)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   float luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) > luma) Fgnd.rgb = Bgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_2)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 2 -----------------------------------------//

DeclareEntryPoint (Lighten)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Screen)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (ColourDodge)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   Fgnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   Fgnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, min (Fgnd.rgb, 1.0.xxx), alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LinearDodge)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LighterColour)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;
   float luma  = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) < luma) Fgnd.rgb = Bgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_3)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 3 -----------------------------------------//

DeclareEntryPoint (Overlay)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = 1.0.xxx - 2.0 * (1.0.xxx - Fgnd.rgb) * (1.0.xxx - Bgnd.rgb);

   float alpha = Fgnd.a * Amount;

   Fgnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   float4 retval = float4 (lerp (Bgnd.rgb, saturate (Fgnd.rgb), alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (SoftLight)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMax = (2.0 * Fgnd.rgb) - 1.0.xxx;
   float3 retMin = Bgnd.rgb * (retMax * (1.0.xxx - Bgnd.rgb) + 1.0.xxx);

   float alpha = Fgnd.a * Amount;

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   Fgnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   float4 retval = float4 (lerp (Bgnd.rgb, saturate (Fgnd.rgb), alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (HardLight)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (1.0.xxx - 2.0 * (1.0.xxx - Bgnd.rgb) * (1.0.xxx - Fgnd.rgb));

   float alpha = Fgnd.a * Amount;

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (VividLight)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMax, retMin;

   float alpha = Fgnd.a * Amount;

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

   float4 retval = float4 (lerp (Bgnd.rgb, saturate (Fgnd.rgb), alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (LinearLight)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 retMin = max ((2.0 * Fgnd) + Bgnd - 1.0.xxxx, kTransparentBlack);
   float4 retMax = min ((2.0 * Fgnd) + Bgnd - 1.0.xxxx, 1.0.xxxx);

   float alpha = Fgnd.a * Amount;

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (PinLight)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 retMax = 2.0 * Fgnd.rgb;
   float3 retMin = retMax - 1.0.xxx;

   float alpha = Fgnd.a * Amount;

   Fgnd.r = (Bgnd.r > retMax.r) ? retMax.r : (Bgnd.r < retMin.r) ? retMin.r : Bgnd.r;
   Fgnd.g = (Bgnd.g > retMax.g) ? retMax.g : (Bgnd.g < retMin.g) ? retMin.g : Bgnd.g;
   Fgnd.b = (Bgnd.b > retMax.b) ? retMax.b : (Bgnd.b < retMin.b) ? retMin.b : Bgnd.b;

   float4 retval = float4 (lerp (Bgnd.rgb, saturate (Fgnd.rgb), alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (HardMix)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float3 ref = 1.0.xxx - Bgnd.rgb;

   float alpha = Fgnd.a * Amount;

   Fgnd.r = (Fgnd.r < ref.r) ? 0.0 : 1.0;
   Fgnd.g = (Fgnd.g < ref.g) ? 0.0 : 1.0;
   Fgnd.b = (Fgnd.b < ref.b) ? 0.0 : 1.0;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_4)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 4 -----------------------------------------//

DeclareEntryPoint (Difference)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Exclusion)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (1.0.xxx - (2.0 * Fgnd.rgb)));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Subtract)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, 0.0.xxx);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Divide)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float alpha = Fgnd.a * Amount;

   Fgnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   Fgnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   Fgnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Dummy_5)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 5 -----------------------------------------//

DeclareEntryPoint (Hue)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 blnd = fn_rgb2hsv (Bgnd);

   float alpha = Fgnd.a * Amount;

   blnd.xw = (fn_rgb2hsv (Fgnd)).xw;

   float4 retval = float4 (lerp (Bgnd.rgb, fn_hsv2rgb (blnd).rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Saturation)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 blnd = fn_rgb2hsv (Bgnd);

   float alpha = Fgnd.a * Amount;

   blnd.yw = fn_rgb2hsv (Fgnd).yw;

   float4 retval = float4 (lerp (Bgnd.rgb, fn_hsv2rgb (blnd).rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Colour)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 blnd = fn_rgb2hsv (Fgnd);

   float alpha = Fgnd.a * Amount;

   blnd.x = (fn_rgb2hsv (Bgnd)).x;

   float4 retval = float4 (lerp (Bgnd.rgb, fn_hsv2rgb (blnd).rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (Luminosity)
{
   float4 Fgnd = initFg (uv1, uv2);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 blnd = fn_rgb2hsv (Bgnd);

   float alpha = Fgnd.a * Amount;

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   float4 retval = float4 (lerp (Bgnd.rgb, fn_hsv2rgb (blnd).rgb, alpha), max (Bgnd.a, alpha));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

