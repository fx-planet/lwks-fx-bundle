// @Maintainer jwrl
// @Released 2023-11-06
// @Author khaver
// @Author schrauber
// @Author jwrl
// @Created 2023-11-06

/**
 This effect first performs a very clean sharpen on the incoming video.  The sample
 offset amount is adjustable, and the edge component derived from this process is then
 clamped to control its visibility.  This is similar in operation to a standard unsharp
 mask but can give much finer edges.

 The next stage removes colour contouring using a range of techniques.  It first dithers
 any pixels at colour boundaries.  The sample radius and dither amount can be adjusted
 to get the best subjective result, and the sample mask can be viewed to help adjust
 sampling.  A second pass then uses the positional dithering to add intermediate
 colours using spline interpolation.

 What will this not do?  Well, it isn't designed to remove JPEG artifacts.  It may help
 but it really was never intended to do that.  Try it - you could be lucky.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Enhancement.fx
//
// This effect is a combination of three original effects: khaver's Tenderizer.fx, an
// experimental dithering effect by shrauber, and YAsharpen.fx by jwrl.  The effects
// were combined by jwrl.
//
// Version history.
//
// Created 2023-11-06 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Enhancement", "User", "Technical", "A video enhancer that sharpens the video while reducing colour banding", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp, Point);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (Bypass, "Bypass sharpening", "Sharpness", false);
DeclareFloatParam (Strength, "Strength", "Sharpness", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Offset, "Sample offset", "Sharpness", kNoFlags, 2.0, 0.0, 6.0);
DeclareFloatParam (EdgeClamp, "Edge clamp", "Sharpness", kNoFlags, 0.125, 0.0, 1.0);

DeclareBoolParam (ColourMask, "Show mask in red", "Colour masking", false);
DeclareFloatParam (Threshold, "Threshold", "Colour masking", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Radius, "Dither radius", "Colour masking", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (NoSmooth, "Bypass smoothing", "Colour smoothing", false);
DeclareFloatParam (Interpolate, "Interpolation", "Colour smoothing", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Sharpen, "Luma sharpness", "Colour smoothing", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA float3(0.897, 1.761, 0.342)

#define RED_MASK    float2(1.0, 0.0).xyyx

#define PixelWidth  (1.0 / _OutputWidth)
#define PixelHeight (1.0 / _OutputHeight)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_noise (float2 progress, float2 xy)
// float2 texture noise (two different values per pixel and frame)
{
   float2 noise1 = frac (sin (1.0 + progress + (xy.x * 82.3)) * (xy.x + 854.5421));

   return frac (sin ((1.0 + noise1 + xy.y) * 92.7) * (noise1 + xy.y + 928.4837));
}

float4 fn_combine (float4 A, float4 B, float4 C, float4 D)
// Originally Hermite (), returns a weighted combination of the four samples A, B, C, D.
{
   float4 a = ((3.0 * (B - C)) + D - A) * 0.0625;
   float4 b = A * 0.25 + C * 0.5 - (5.0 * B + D) * 0.125;
   float4 c = (C - A) * 0.25;

   return (a + b + c + B);
}

float fn_closest (float test, float orig)
{
   float range = abs (test - orig);

   return (range < 0.001302083333) ? orig :
          (range < 0.002604166667) ? test : (test + orig) / 2.0;
}

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Sharp)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Input = tex2D (Inp, uv1);

   if (Bypass) return Input;

   float2 sampleX = float2 (Offset / _OutputWidth, 0.0);
   float2 sampleY = float2 (0.0, Offset / _OutputHeight);

   float clamp = max (1.0e-6, EdgeClamp);

   float4 luma_val = float4 (LUMA * Strength / clamp, 0.5);
   float4 edges = tex2D (Inp, uv1 + sampleY);
   float4 retval = Input;

   edges += tex2D (Inp, uv1 - sampleX);
   edges += tex2D (Inp, uv1 + sampleX);
   edges += tex2D (Inp, uv1 - sampleY);
   edges = retval - (edges / 4.0);
   edges.a = 1.0;

   retval.rgb += ((saturate (dot (edges, luma_val)) * clamp * 2.0) - clamp).xxx;

   return retval;
}

DeclarePass (Dither)
{
   float2 progress = float2 (_Progress, _Progress + 0.3);
   float2 radius = pow (1.22 - saturate (Radius), 4.0).xx * 0.3;        // Applies a curve to the radius setting to make adjustment feel more natural
   float2 noise = fn_noise (progress, uv2) - 0.5.xx;

   float maxNoise = max (abs (noise.x), abs (noise.y));
   float threshold = Threshold * 0.0390625;
   float correction = length (maxNoise) / max (length (noise), 1.0E-9); // Correction is needed in the following to create a round diffusion surface from a rectangular one.

   radius *= float2 (1.0, _OutputAspectRatio);                          // Corrects for the aspect ratio
   radius *= noise * correction;                                        // Creates a statistically round diffusion radius

   float4 sample1 = tex2D (Sharp, uv2);
   float4 sample2 = mirror2D (Sharp, uv2 + radius);

   bool masked = ((abs (sample1.r - sample2.r) > threshold) ||
                  (abs (sample1.g - sample2.g) > threshold) ||
                  (abs (sample1.b - sample2.b) > threshold));

   if (ColourMask) sample2 = RED_MASK;

   return masked || NoSmooth ? sample1 : sample2;
}

DeclareEntryPoint (Enhancement)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 vidref = tex2D (Inp, uv1);
   float4 seporg = tex2D (Dither, uv2);

   float amt;

   if (ColourMask || NoSmooth) {
      amt = 1.0;

      if (NoSmooth) vidref = seporg;
   }
   else {
      float luma_ref = min (seporg.r, min (seporg.g, seporg.b));

      seporg.rgb -= luma_ref.xxx;
      seporg.a    = luma_ref;

      float2 xy0 = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
      float2 xy1 = float2 (xy0.x, 0.0);
      float2 xy2 = float2 (0.0, xy0.y);
      float2 xy3 = xy1 * 2.0;       // float2 (xy0.x * 2.0, 0.0)

      float4 samp1 = mirror2D (Dither, uv2 - xy3);
      float4 samp2 = mirror2D (Dither, uv2 - xy1);
      float4 samp3 = mirror2D (Dither, uv2 + xy1);
      float4 samp4 = mirror2D (Dither, uv2 + xy3);
      float4 samp  = fn_combine (samp1, samp2, samp3, samp4);

      xy3.y = xy0.y;                // float2 (xy0.x * 2.0, xy0.y)

      samp1 = mirror2D (Dither, uv2 - xy3);
      samp2 = (mirror2D (Dither, uv2 - xy1) + mirror2D (Dither, uv2 - xy0)) / 2.0;
      samp3 = (mirror2D (Dither, uv2 + xy1) + mirror2D (Dither, uv2 + xy0)) / 2.0;
      samp4 = mirror2D (Dither, uv2 + xy3);
      samp += fn_combine (samp1, samp2, samp3, samp4);

      xy3.y += xy0.y;               //  xy0 * 2.0

      samp1 = mirror2D (Dither, uv2 - xy3);
      samp2 = mirror2D (Dither, uv2 - xy0);
      samp3 = mirror2D (Dither, uv2 + xy0);
      samp4 = mirror2D (Dither, uv2 + xy3);
      samp += fn_combine (samp1, samp2, samp3, samp4);

      xy1.y = xy3.y;                // float2 (xy0.x, xy0.y * 2.0)
      xy3 = float2 (0.0, xy0.y);

      samp1 = mirror2D (Dither, uv2 - xy1);
      samp2 = (mirror2D (Dither, uv2 - xy0) + mirror2D (Dither, uv2 - xy2)) / 2.0;
      samp3 = (mirror2D (Dither, uv2 + xy0) + mirror2D (Dither, uv2 + xy2)) / 2.0;
      samp4 = mirror2D (Dither, uv2 + xy1);
      samp += fn_combine (samp1, samp2, samp3, samp4);

      xy1.x = 0.0;                  // float2 (0.0, xy0.y * 2.0)

      samp1 = mirror2D (Dither, uv2 - xy1);
      samp2 = mirror2D (Dither, uv2 - xy2);
      samp3 = mirror2D (Dither, uv2 + xy2);
      samp4 = mirror2D (Dither, uv2 + xy1);
      samp += fn_combine (samp1, samp2, samp3, samp4);

      xy1.x = -xy0.x;               // float2 (-xy0.x, xy0.y * 2.0)
      xy3 = float2 (-xy0.x, xy0.y);

      samp1 = mirror2D (Dither, uv2 - xy1);
      samp2 = (mirror2D (Dither, uv2 - xy3) + mirror2D (Dither, uv2 - xy2)) / 2.0;
      samp3 = (mirror2D (Dither, uv2 + xy3) + mirror2D (Dither, uv2 + xy2)) / 2.0;
      samp4 = mirror2D (Dither, uv2 + xy1);
      samp += fn_combine (samp1, samp2, samp3, samp4);

      xy1 = xy3 * 2.0;              // float2 (-xy0.x, xy0.y) * 2.0

      samp1 = mirror2D (Dither, uv2 - xy1);
      samp2 = mirror2D (Dither, uv2 - xy3);
      samp3 = mirror2D (Dither, uv2 + xy3);
      samp4 = mirror2D (Dither, uv2 + xy1);
      samp += fn_combine (samp1, samp2, samp3, samp4);

      xy1.y = xy0.y;                // float2 (-xy0.x * 2.0, xy0.y)
      xy2 = float2 (-xy0.x, 0.0);

      samp1 = mirror2D (Dither, uv2 + xy1);
      samp2 = (mirror2D (Dither, uv2 + xy3) + mirror2D (Dither, uv2 + xy2)) / 2.0;
      samp3 = (mirror2D (Dither, uv2 - xy3) + mirror2D (Dither, uv2 - xy2)) / 2.0;
      samp4 = mirror2D (Dither, uv2 - xy1);
      samp += fn_combine (samp1, samp2, samp3, samp4);

      if (samp.a > 0.0) {
         samp /= 8.0;

         float luma_proc = min (samp.r, min (samp.g, samp.b));

         samp.rgb -= luma_proc.xxx;

         if (Interpolate > 0.0) {
            samp.r = fn_closest (samp.r, seporg.r);
            samp.g = fn_closest (samp.g, seporg.g);
            samp.b = fn_closest (samp.b, seporg.b);

            seporg.rgb = lerp (seporg.rgb, samp.rgb, Interpolate * 2.0);
         }

         if (Sharpen <= 1.0) luma_ref = lerp (luma_ref, fn_closest (luma_proc, luma_ref), (1.0 - Sharpen));
      }

      seporg.rgb += luma_ref.xxx;
      seporg.a = vidref.a;
      amt = Amount;
   }

   return lerp (vidref, seporg, tex2D (Mask, uv1).x * amt);
}

