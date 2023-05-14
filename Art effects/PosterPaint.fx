// @Maintainer jwrl
// @Released 2023-05-14
// @Author jwrl
// @Created 2018-11-28

/**
 Poster paint (PosterPaintFx) is an effect that posterizes the image.  The adjustment runs
 from 2 to 16, with two providing two steps of posterization (black and white) and sixteen
 giving almost normal video.  The input video can be graded before the posterization process.
 The input image can be used as-is giving the posterisation a hard edge, or blurred to allow
 it to blend more smoothly.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PosterPaint.fx
//
// Version history:
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Poster paint", "Colour", "Art Effects", "A fully adjustable posterize effect", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Amount, "Posterize amount", kNoGroup, 3, "2|3|4|5|6|7|8|9|10|11|12|13|14|15|16");

DeclareFloatParam (Smoothness, "Preblur", "Major input adjustment", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Saturation, "Saturation", "Major input adjustment", "DisplayAsPercentage", 1.0, 0.0, 4.0);
DeclareFloatParam (Gamma, "Gamma", "Major input adjustment", kNoFlags, 1.0, 0.1, 4.0);
DeclareFloatParam (Brightness, "Brightness", "Minor input adjustment", "DisplayAsPercentage", 0.0, -1.0, 1.0);
DeclareFloatParam (Contrast, "Contrast", "Minor input adjustment", "DisplayAsPercentage", 1.0, 0.0, 5.0);
DeclareFloatParam (Gain, "Gain", "Minor input adjustment", "DisplayAsPercentage", 1.0, 0.0, 4.0);
DeclareFloatParam (HueAngle, "Hue (degrees)", "Minor input adjustment", kNoFlags, 0.0, -180.0, 180.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define ONE_THIRD  0.3333333333

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_HSLtoRGB (float3 HSL)
{
   float3 RGB;

   float dif = HSL.y - HSL.z;

   RGB.r = HSL.x + ONE_THIRD;
   RGB.b = HSL.x - ONE_THIRD;

   RGB.r = (RGB.r < 0.0) ? RGB.r + 1.0 : (RGB.r > 1.0) ? RGB.r - 1.0 : RGB.r;
   RGB.g = (HSL.x < 0.0) ? HSL.x + 1.0 : (HSL.x > 1.0) ? HSL.x - 1.0 : HSL.x;
   RGB.b = (RGB.b < 0.0) ? RGB.b + 1.0 : (RGB.b > 1.0) ? RGB.b - 1.0 : RGB.b;

   RGB *= 6.0;

   RGB.r = (RGB.r < 1.0) ? (RGB.r * dif) + HSL.z :
           (RGB.r < 3.0) ? HSL.y :
           (RGB.r < 4.0) ? ((4.0 - RGB.r) * dif) + HSL.z : HSL.z;

   RGB.g = (RGB.g < 1.0) ? (RGB.g * dif) + HSL.z :
           (RGB.g < 3.0) ? HSL.y :
           (RGB.g < 4.0) ? ((4.0 - RGB.g) * dif) + HSL.z : HSL.z;

   RGB.b = (RGB.b < 1.0) ? (RGB.b * dif) + HSL.z :
           (RGB.b < 3.0) ? HSL.y :
           (RGB.b < 4.0) ? ((4.0 - RGB.b) * dif) + HSL.z : HSL.z;

   return RGB;
}

float3 fn_RGBtoHSL (float3 RGB)
{
   float high  = max (RGB.r, max (RGB.g, RGB.b));
   float lows  = min (RGB.r, min (RGB.g, RGB.b));
   float range = high - lows;
   float Lraw  = high + lows;

   float Luma  = Lraw * 0.5;
   float Hue   = 0.0;
   float Satn  = 0.0;

   if (range != 0.0) {
      Satn = (Lraw < 1.0) ? range / Lraw : range / (2.0 - Lraw);

      if (RGB.r == high) { Hue = (RGB.g - RGB.b) / range; }
      else if (RGB.g == high) { Hue = 2.0 + (RGB.b - RGB.r) / range; }
      else { Hue = 4.0 + (RGB.r - RGB.g) / range; }

      Hue /= 6.0;
   }

   return float3 (Hue, Satn, Luma);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Video)
{ return ReadPixel (Inp, uv1); }

DeclarePass (PreBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval = tex2D (Video, uv2);

   // What follows is the horizontal component of a standard box blur.  The maths used
   // takes advantage of the fact that the shader language can do float2 operations as
   // efficiently as floats.  This way we save on having to manufacture a new float2
   // every time that we need a new address for the next tap.

   float2 xy0 = float2 (Smoothness / _OutputWidth, 0.0);
   float2 xy1 = uv2 + xy0;
   float2 xy2 = uv2 - xy0;

   retval += tex2D (Video, xy1); xy1 += xy0;
   retval += tex2D (Video, xy1); xy1 += xy0;
   retval += tex2D (Video, xy1); xy1 += xy0;
   retval += tex2D (Video, xy1); xy1 += xy0;
   retval += tex2D (Video, xy1); xy1 += xy0;
   retval += tex2D (Video, xy1);
   retval += tex2D (Video, xy2); xy2 -= xy0;
   retval += tex2D (Video, xy2); xy2 -= xy0;
   retval += tex2D (Video, xy2); xy2 -= xy0;
   retval += tex2D (Video, xy2); xy2 -= xy0;
   retval += tex2D (Video, xy2); xy2 -= xy0;
   retval += tex2D (Video, xy2);

   // Divide retval by 13 because there are 12 sampling taps plus the original image

   return retval / 13.0;
}

DeclareEntryPoint (PosterPaint)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval = tex2D (Video, uv2);
   float4 RGB = tex2D (PreBlur, uv2);

   float alpha = RGB.a;

   // This is the vertical component of the box blur.

   float2 xy0 = float2 (0.0, Smoothness / _OutputHeight);
   float2 xy1 = uv2 + xy0;
   float2 xy2 = uv2 - xy0;

   RGB += tex2D (PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (PreBlur, xy1);
   RGB += tex2D (PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (PreBlur, xy2);

   RGB /= 13.0;

   float posterize = Amount + 2.0;

   // We now adjust the brightness, contrast, gamma and gain of the preblurred image.

   float3 proc = (((pow (RGB.rgb, 1.0 / Gamma) * Gain) + (Brightness - 0.5).xxx) * Contrast) + 0.5.xxx;
   float3 HSL = fn_RGBtoHSL (proc);

   HSL.y = saturate (HSL.y * Saturation);
   HSL.x = HSL.x + frac (HueAngle / 360.0);

   if (HSL.x < 0.0) HSL.x += 1.0;
   if (HSL.x > 1.0) HSL.x -= 1.0;

   HSL.yz = saturate (round (HSL.yz * posterize) / posterize);

   if (HSL.y == 0.0) return float4 (HSL.zzz, RGB.a);

   posterize *= 6.0;
   HSL.x = saturate (round (HSL.x * posterize) / posterize);

   float S = HSL.y * HSL.z;

   HSL.y = (HSL.z < 0.5) ? HSL.z + S : (HSL.y + HSL.z) - S;
   HSL.z = (2.0 * HSL.z) - HSL.y;

   RGB = float4 (fn_HSLtoRGB (HSL), alpha);

   return lerp (retval, RGB, tex2D (Mask, uv2).x);
}
