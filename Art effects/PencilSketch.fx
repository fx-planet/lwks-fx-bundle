// @Maintainer jwrl
// @Released 2023-01-23
// @Author khaver
// @Author Daniel Taylor
// @Created 2018-05-24

/**
 Pencil Sketch (PencilSketchFx.fx) is a really nice effect that creates a pencil sketch
 from your image.  As well as the ability to adjust saturation, gamma, brightness and
 gain, it's possible to overlay the result over a background layer.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PencilSketch.fx
//
// Original Shadertoy author:
// Daniel Taylor (culdevu) (2017-06-09) https://www.shadertoy.com/view/ldXfRj
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// PencilSketchFx.fx for Lightworks was adapted by user khaver 24 May 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/ldXfRj
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// note: code comments are from the original author(s).
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Update 2023-01-23 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Pencil Sketch", "Stylize", "Art Effects", "Pencil sketch effect with sat/gamma/cont/bright/gain/overlay/alpha controls", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Color", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Saturation, "Saturation", kNoGroup, kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (Gamma, "Gamma", kNoGroup, kNoFlags, 1.0, 0.1, 4.0);
DeclareFloatParam (Contrast, "Contrast", kNoGroup, kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (Brightness, "Brightness", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Gain, "Gain", kNoGroup, kNoFlags, 1.0, 0.0, 4.0);
DeclareFloatParam (Range, "Range", kNoGroup, kNoFlags, 10.0, 0.0, 20.0);
DeclareFloatParam (EPS, "Stroke", kNoGroup, kNoFlags, 1.0, 1e-10, 5.0);
DeclareFloatParam (Threshold, "Gradient Threshold", kNoGroup, kNoFlags, 0.01, 0.0, 0.1);
DeclareFloatParam (Sensitivity, "Sensitivity", kNoGroup, kNoFlags, 1.0, 0.0, 50.0);

DeclareBoolParam (AddAlpha, "Add Alpha", kNoGroup, false);

DeclareBoolParam (Greyscale, "Greyscale", "Source Video", false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI2      6.28318530717959
#define RANGE    16.0
#define STEP     2.0
#define ANGLENUM 4.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float getVal (sampler S, float2 pos)
{
   float4 Col = tex2D (S, pos / float2 (_OutputWidth, _OutputHeight));

   return dot (Col.rgb, float3 (0.2126, 0.7152, 0.0722));
}

float2 getGrad (sampler S, float2 pos, float eps)
{
   float2 d = float2 (eps, 0.0);
   float2 e = d.yx;

   return float2 (getVal (S, pos + d) - getVal (S, pos - d),
                  getVal (S, pos + e) - getVal (S, pos - e)) / (eps * 2.0);
}

float2 pR (float2 p, float a)
{
   float s, c;

   sincos (a, s, c);

   return (c * p) + (s * float2 (p.y, -p.x));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (PencilSketch)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float2 res = float2 (_OutputWidth, _OutputHeight);
   float2 pos = uv1 * res;

   float weight = 1.0;

   for (float j = 0.0; j < ANGLENUM; j += 1.0) {
      float2 dir = pR (float2 (1.0, 0.0), j * PI2 / (EPS * ANGLENUM));
      float2 grad = float2 (-dir.y, dir.x);

      for (float i = -RANGE; i <= RANGE; i += STEP) {
         float2 pos2 = pos + (normalize (dir) * i);

         // video texture wrap can't be set to anything other than clamp  (-_-)

         if (pos2.y < 0.0 || pos2.x < 0.0 || pos2.x > res.x || pos2.y > res.y) continue;

         float2 g = getGrad (Input, pos2, 1.0);

         if (length (g) < Threshold) continue;

         weight -= pow (abs (dot (normalize (grad), normalize (g))), Sensitivity) / floor ((2.0 * ceil (Range) + 1.0) / STEP) / ANGLENUM;
      }
   }

   float4 result, fg = tex2D (Input, uv1);
   float4 color = Greyscale ? getVal (Input, pos).xxxx : tex2D (Input, pos / float2 (_OutputWidth, _OutputHeight));

   color = lerp (kTransparentBlack, color, weight);
   color = ((((pow (color, 1.0 / Gamma) * Gain) + Brightness) - 0.5) * Contrast) + 0.5;

   result.r = color.r < 0.5 ? 2.0 * fg.r * color.r : 1.0 - (2.0 * (1.0 - fg.r) * (1.0 - color.r));
   result.g = color.g < 0.5 ? 2.0 * fg.g * color.g : 1.0 - (2.0 * (1.0 - fg.g) * (1.0 - color.g));
   result.b = color.b < 0.5 ? 2.0 * fg.b * color.b : 1.0 - (2.0 * (1.0 - fg.b) * (1.0 - color.b));

   result.rgb = lerp (color.rgb, result.rgb, fg.a * Amount);

   float avg = (result.r + result.g + result.b) / 3.0;

   result.a = AddAlpha ? 1.0 - avg : fg.a;
   result.rgb = avg.xxx + ((result.rgb - avg.xxx) * Saturation);

   return lerp (fg, result, tex2D (Mask, uv1).x);
}

