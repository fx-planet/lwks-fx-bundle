// @Maintainer jwrl
// @Released 2023-11-05
// @Author khaver
// @Author schrauber
// @Author jwrl
// @Created 2023-11-05

/**
 This effect attempts to remove colour contouring artefacts by a range of techniques.  It
 first dithers colour pixels around colour boundaries.  The sample radius and dither amount
 can be adjusted to get the best subjective result, and the sample mask can be viewed to
 adjust sampling.  A second pass then uses the positional dithering to add intermediate
 colours using spline interpolation.  During this pass edge sharpness can be adjusted to
 compensate for any image blurring that may have happened with the interpolation.

 Note that this effect does exactly what it says that it will do.  Unfortunately additional
 processing by delivery systems such as YouTube and the like can reintroduce the very
 artefacts that you've worked so hard to remove.  In a case like that the best that you can
 do is test your export settings after you have uploaded your sequence and if not satisfied
 adjust them and try again.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSmooth.fx
//
// This effect is based on two separate effects.  The first is khaver's excellent spline
// tool Tenderizer.fx, and the second is an experimental dithering effect by schrauber.
// They were cobbled together by me, jwrl.  The original effects did exactly what they
// were designed to do and did it well.  I have restructured both to produce this effect.
//
// Schrauber's reconstruction was initially to invert the radius setting and change its
// linearity.  The radius setting is now also fully range limited.  I also decided to
// rename both colour masking parameters and make them swing between 0 and 100%, to be
// more consistent with other Lightworks effects.
//
// Khaver's effect has undergone most restructuring.  This doesn't mean that there was
// anything wrong with the original effect - there certainly wasn't.  The restructuring
// was to help me understand what was going on, so that I knew what I could safely alter
// if necessary.  My original plan had been to reduce the number of samples used, but I
// subsequently decided to leave it alone.  As it turned out the only thing that I had
// to do was provide a means of adjusting chroma interpolation and sharpness which I
// could have done with the original effect as supplied.
//
// Both effects have had parameters removed.  In schrauber's effect it's no longer
// possible to lock the noise generator seed.  It is now permanently triggered by the
// effect's progress.  In khaver's effect the horizontal and vertical resolution are
// automatically set by the project resolution and cannot be adjusted.  Neither of
// these changes appear to have any impact on the overall performance.
//
// Version history:
//
// Conversion 2023-11-05 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Colour smoother", "Colour", "Technical", "Interpolates colours to correct contouring", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp, Point);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (ColourMask, "Show mask in red", "Colour masking", false);

DeclareFloatParam (Threshold, "Threshold", "Colour masking", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Radius, "Dither radius", "Colour masking", kNoFlags, 0.5, 0.0, 1.0);

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

DeclarePass (Dither)
{
   float2 progress = float2 (_Progress, _Progress + 0.3);
   float2 radius = pow (1.22 - saturate (Radius), 4.0).xx * 0.3;        // Applies a curve to the radius setting to make adjustment feel more natural
   float2 noise = fn_noise (progress, uv1) - 0.5.xx;

   float maxNoise = max (abs (noise.x), abs (noise.y));
   float threshold = Threshold * 0.0390625;
   float correction = length (maxNoise) / max (length (noise), 1.0E-9); // Correction is needed in the following to create a round diffusion surface from a rectangular one.

   radius *= float2 (1.0, _OutputAspectRatio);                          // Corrects for the aspect ratio
   radius *= noise * correction;                                        // Creates a statistically round diffusion radius

   float4 sample1 = tex2D (Inp, uv1);
   float4 sample2 = mirror2D (Inp, uv1 + radius);

   bool masked = ((abs (sample1.r - sample2.r) > threshold) ||
                  (abs (sample1.g - sample2.g) > threshold) ||
                  (abs (sample1.b - sample2.b) > threshold));

   if (ColourMask) sample2 = RED_MASK;

   return masked ? sample1 : sample2;
}

DeclareEntryPoint (ColourSmooth)
{
   if (IsOutOfBounds (uv1)) return 0.0.xxxx;

   float4 vidref = tex2D (Inp, uv1);
   float4 seporg = tex2D (Dither, uv2);

   float amt;

   if (ColourMask) { amt = 1.0; }
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

