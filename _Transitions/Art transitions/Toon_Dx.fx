// @Maintainer jwrl
// @Released 2023-01-30
// @Author jwrl
// @Created 2023-01-30

/**
 This transition posterizes the outgoing image then develops outlines from the image edges
 while dissolving to the incoming image.  With the incoming image the process is reversed.
 The intention is to mimic khaver's Toon effect, but apply it to a transition.  While it's
 similar, there's an extra parameter provided that allows adjustment of the white levels of
 the posterised colours.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 Unlike with LW transitions there is no mask.  Instead the ability to crop the effect
 to the background is provided, which dissolves between the cropped areas during the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Toon_Dx.fx
//
// Version history:
//
// Built 2023-01-30 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Toon transition", "Mix", "Art transitions", "A cartoon-like transition between the two images", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Threshold, "Threshold", "Edge detection", "DisplayAsPercentage", 0.3, 0.0, 2.0);
DeclareFloatParam (LineWeightX, "Line weight X", "Edge detection", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (LineWeightY, "Line weight Y", "Edge detection", kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (PosterizeDepth, "Posterize depth", "Posterize preprocess", 3, "2|3|4|5|6|7|8");

DeclareFloatParam (Preblur, "Preblur", "Posterize preprocess", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Saturation, "Saturation", "Posterize preprocess", "DisplayAsPercentage", 2.5, 0.0, 4.0);
DeclareFloatParam (Gamma, "Gamma", "Posterize preprocess", kNoFlags, 0.6, 0.1, 4.0);

DeclareFloatParam (Brightness, "Brightness", "Posterize postprocess", "DisplayAsPercentage", 0.0, -1.0, 1.0);
DeclareFloatParam (Contrast, "Contrast", "Posterize postprocess", "DisplayAsPercentage", 1.0, 0.0, 5.0);
DeclareFloatParam (Gain, "Gain", "Posterize postprocess", "DisplayAsPercentage", 1.0, 0.0, 4.0);
DeclareFloatParam (HueAngle, "Hue (degrees)", "Posterize postprocess", kNoFlags, 0.0, -180.0, 180.0);

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define ONE_THIRD  0.3333333333
#define PI         3.1415926536

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

DeclarePass (Mixed)
{
   float Amt = saturate ((Amount - 0.25) * 2.0);

   return lerp (ReadPixel (Fg, uv1), ReadPixel (Bg, uv2), Amt);
}

DeclarePass (Blur_X)
{
   float4 retval = tex2D (Mixed, uv3);

   // What follows is the horizontal component of a standard box blur.  The maths used
   // takes advantage of the fact that the shader language can do float2 operations as
   // efficiently as floats.  This way we save on having to manufacture a completely
   // new float2 every time that we need a new address for the next tap.

   float2 xy0 = float2 (Preblur / _OutputWidth, 0.0);
   float2 xy1 = uv3 + xy0;
   float2 xy2 = uv3 - xy0;

   retval += tex2D (Mixed, xy1); xy1 += xy0;
   retval += tex2D (Mixed, xy1); xy1 += xy0;
   retval += tex2D (Mixed, xy1); xy1 += xy0;
   retval += tex2D (Mixed, xy1); xy1 += xy0;
   retval += tex2D (Mixed, xy1); xy1 += xy0;
   retval += tex2D (Mixed, xy1);
   retval += tex2D (Mixed, xy2); xy2 -= xy0;
   retval += tex2D (Mixed, xy2); xy2 -= xy0;
   retval += tex2D (Mixed, xy2); xy2 -= xy0;
   retval += tex2D (Mixed, xy2); xy2 -= xy0;
   retval += tex2D (Mixed, xy2); xy2 -= xy0;
   retval += tex2D (Mixed, xy2);

   // Divide retval by 13 because there are 12 sampling taps plus the original image

   return retval / 13.0;
}

DeclarePass (Blur_Y)
{
   float4 RGB = tex2D (Blur_X, uv3);

   float alpha = RGB.a;

   // This is the vertical component of the box blur - same maths approach applies.

   float2 xy0 = float2 (0.0, Preblur / _OutputHeight);
   float2 xy1 = uv3 + xy0;
   float2 xy2 = uv3 - xy0;

   RGB += tex2D (Blur_X, xy1); xy1 += xy0;
   RGB += tex2D (Blur_X, xy1); xy1 += xy0;
   RGB += tex2D (Blur_X, xy1); xy1 += xy0;
   RGB += tex2D (Blur_X, xy1); xy1 += xy0;
   RGB += tex2D (Blur_X, xy1); xy1 += xy0;
   RGB += tex2D (Blur_X, xy1);
   RGB += tex2D (Blur_X, xy2); xy2 -= xy0;
   RGB += tex2D (Blur_X, xy2); xy2 -= xy0;
   RGB += tex2D (Blur_X, xy2); xy2 -= xy0;
   RGB += tex2D (Blur_X, xy2); xy2 -= xy0;
   RGB += tex2D (Blur_X, xy2); xy2 -= xy0;
   RGB += tex2D (Blur_X, xy2);

   RGB /= 13.0;

   float posterize = PosterizeDepth + 2.0;

   // We now adjust the brightness, contrast, gamma and gain of the blurred image.

   float3 proc = (((pow (RGB.rgb, 1.0 / Gamma) * Gain * 0.5) + (Brightness - 0.5).xxx) * Contrast) + 0.5.xxx;
   float3 HSL = fn_RGBtoHSL (proc);

   HSL.y = saturate (HSL.y * Saturation);
   HSL.x = HSL.x + frac (HueAngle / 360.0);

   if (HSL.x < 0.0) HSL.x += 1.0;
   if (HSL.x > 1.0) HSL.x -= 1.0;

   HSL.yz = saturate (round (HSL.yz * posterize) / posterize);

   if (HSL.y == 0.0) return float4 (HSL.zzz, RGB.a);

   posterize *= 6.0;
   HSL.x = round (HSL.x * posterize) / posterize;

   if (HSL.x < 0.0) HSL.x += 1.0;
   if (HSL.x > 1.0) HSL.x -= 1.0;

   float S = HSL.y * HSL.z * (1.0 + (sin (Amount * PI) * 2.0));

   HSL.y = (HSL.z < 0.5) ? HSL.z + S : (HSL.y + HSL.z) - S;
   HSL.z = (2.0 * HSL.z) - HSL.y;

   return float4 (fn_HSLtoRGB (HSL), 1.0);
}

DeclareEntryPoint (Toon_Dx)
{
   float Amt = max ((abs (Amount - 0.5) * 2.0) - 0.5, 0.0) * 2.0;
   float Thr = Threshold * Threshold;
   float W_X = 100.0 + ((1.0 - LineWeightX) * 2048.0);
   float W_Y = 100.0 + ((1.0 - LineWeightY) * 2048.0);

   Thr *= Thr;

   float2 LwX = float2 (1.0 / W_X, 0.0);
   float2 LwY = float2 (0.0, 1.0 / W_Y);
   float2 xy1 = uv3 - LwY;
   float2 xy2 = uv3 + LwY;

   // Convolution

   float4 vidX = ReadPixel (Mixed, xy1 - LwX);
   float4 vidY = vidX;
   float4 conv = ReadPixel (Mixed, xy1 + LwX);

   vidX += conv - (ReadPixel (Mixed, xy1));
   vidY -= (conv - ReadPixel (Mixed, uv3 - LwX) + ReadPixel (Mixed, uv3 + LwX));

   conv  = ReadPixel (Mixed, xy2 - LwX);
   vidX -= (conv - ReadPixel (Mixed, xy2));
   vidY += conv;
   conv  = ReadPixel (Mixed, xy2 + LwX);
   vidX -= conv;
   vidY -= conv;
   conv  = (vidX * vidX) + (vidY * vidY);

   // Add and apply threshold

   float outlines = ((conv.x <= Thr) + (conv.y <= Thr) + (conv.z <= Thr)) / 3.0;
   float sinAmt = sin (Amount * PI);

   float4 Bgnd = ReadPixel (Mixed, uv3);
   float4 retval = lerp (float4 (outlines.xxx, 1.0), Bgnd, Amt);
   float4 Fgnd = ReadPixel (Blur_Y, uv3);

   float3 pp = fn_RGBtoHSL (Fgnd.rgb);

   float alpha = saturate (Bgnd.a * 3.0);

   pp.x  = pp.x > 0.5 ? pp.x - 0.5 : pp.x + 0.5;
   pp.yz = 1.0.xx - pp.yz;
   pp    = lerp (fn_HSLtoRGB (pp), 1.0.xxx, sinAmt * 0.5);
   Fgnd  = lerp (Fgnd, float4 (pp, Fgnd.a), sinAmt);

   Amt = 1.0 - max ((Amt - 0.5) * 2.0, 0.0);
   Bgnd = lerp (Bgnd, saturate (Fgnd), Amt);

   retval.rgb = min (retval.rgb, Bgnd.rgb) * alpha;

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

