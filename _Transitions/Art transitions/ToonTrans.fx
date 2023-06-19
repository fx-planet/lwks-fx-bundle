// @Maintainer jwrl
// @Released 2023-06-13
// @Author jwrl
// @Created 2022-06-01

/**
 This transition posterises the mixed video and develops outlines from its edges as it
 transitions the blend in or out.  The intention is to mimic khaver's Toon effect, but
 apply it to a keyed transition.  While it's similar, there's an extra parameter provided
 that allows adjustment of the white levels of the posterised colours.  If you're using
 a flat coloured title over a plain background you may not see much difference between
 this and a normal dissolve.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ToonTrans.fx
//
// Version history:
//
// Updated 2023-06-13 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Toon transition", "Mix", "Art transitions", "A stylised cartoon transition", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

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

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

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

float4 fn_technique (sampler M, sampler T, float2 uv, float amount)
{
   float Amt = max ((abs (amount - 0.5) * 2.0) - 0.5, 0.0) * 2.0;
   float Thr = Threshold * Threshold;
   float W_X = 100.0 + ((1.0 - LineWeightX) * 2048.0);
   float W_Y = 100.0 + ((1.0 - LineWeightY) * 2048.0);

   Thr *= Thr;

   float2 LwX = float2 (1.0 / W_X, 0.0);
   float2 LwY = float2 (0.0, 1.0 / W_Y);
   float2 xy1 = uv - LwY;
   float2 xy2 = uv + LwY;

   // Convolution

   float4 vidX = ReadPixel (M, (xy1 - LwX));
   float4 vidY = vidX;
   float4 conv = ReadPixel (M, (xy1 + LwX));

   vidX += conv - (ReadPixel (M, xy1));
   vidY -= (conv - ReadPixel (M, (uv - LwX)) + ReadPixel (M, (uv + LwX)));

   conv  = ReadPixel (M, (xy2 - LwX));
   vidX -= (conv - ReadPixel (M, xy2));
   vidY += conv;
   conv  = ReadPixel (M, (xy2 + LwX));
   vidX -= conv;
   vidY -= conv;
   conv  = (vidX * vidX) + (vidY * vidY);

   // Add and apply threshold

   float outlines = ((conv.x <= Thr) + (conv.y <= Thr) + (conv.z <= Thr)) / 3.0;
   float sinAmt = sin (amount * PI);

   float4 Bgnd = ReadPixel (M, uv);
   float4 retval = lerp (float4 (outlines.xxx, 1.0), Bgnd, Amt);
   float4 Fgnd = ReadPixel (T, uv);

   float3 pp = fn_RGBtoHSL (Fgnd.rgb);

   pp.x  = pp.x > 0.5 ? pp.x - 0.5 : pp.x + 0.5;
   pp.yz = 1.0.xx - pp.yz;
   pp    = lerp (fn_HSLtoRGB (pp), 1.0.xxx, sinAmt * 0.5);
   Fgnd  = lerp (Fgnd, float4 (pp, Fgnd.a), sinAmt);

   Amt = saturate (1.0 - Amt);
   Bgnd = lerp (Bgnd, saturate (Fgnd), Amt);

   retval.rgb = min (retval.rgb, Bgnd.rgb);
   retval.a   = Bgnd.a;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclarePass (Mixed)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);

   float amt = saturate ((Blended && SwapDir ? Amount - 0.25 : 0.75 - Amount) * 2.0);

   return lerp (Bgnd, Fgnd, amt);
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

DeclarePass (ToonSub)
{
   float4 RGB = tex2D (Blur_X, uv3);

   float alpha = RGB.a;

   // This is the vertical component of the box blur.

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

DeclareEntryPoint (ToonTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         retval = fn_technique (Mixed, ToonSub, uv3, 0.5);
         maskBg = Bgnd;

         if (SwapDir) {
            retval = lerp (Bgnd, retval, saturate (Amount * 2.0));
            retval = lerp (retval, Fgnd, saturate ((Amount - 0.5) * 2.0));
         }
         else {
            retval = lerp (Fgnd, retval, saturate (Amount * 2.0));
            retval = lerp (retval, Bgnd, saturate ((Amount - 0.5) * 2.0));
         }
      }

      retval = lerp (maskBg, retval, Fgnd.a);
   }
   else {
      retval = fn_technique (Mixed, ToonSub, uv3, Amount) * Fgnd.a;
      maskBg = Fgnd;
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

