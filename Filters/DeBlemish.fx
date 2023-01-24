// @Maintainer jwrl
// @Released 2023-01-24
// @Author jwrl
// @Created 2023-01-24

/**
 This is a skin blemish removal tool similar in concept to "Skin smooth".  It uses a
 different technique than that effect to mask skin tones, which should make it easier
 to set up.  The default skin colour has been tested to work quite well with European
 and Asian flesh tones but will need adjustment with darker skins or poorly lit ones.

 The blur technique used is a variant of my radial blur, which also differs from the
 skin smooth effect.  The mask produced can be quite hard edged, as the mask will be
 blurred along with video ensuring a smooth blend.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeBlemish.fx
//
// Version history:
//
// Built 2023-01-24 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("De-blemish", "Stylize", "Filters", "Smooths skin tones to reduce visible skin blemishes using a radial blur", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Size, "Blur strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Amount, "Blur mix", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (ShowMask, "Show mask", "Mask settings", false);

DeclareColourParam (MaskColour, "Skin colour", "Mask settings", kNoFlags, 0.945, 0.7765, 0.663);

DeclareFloatParam (MaskClip, "Mask clip", "Mask settings", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (MaskSep, "Mask separation", "Mask settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (MaskGamma, "Mask linearity", "Mask settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (MaskWhite, "White clip", "Mask settings", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (MaskBlack, "Black crush", "Mask settings", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define MIN_GAMMA 0.316227766
#define MAX_GAMMA 1.683772234

#define LEVELS    0.9
#define OFFSET    1.0 - LEVELS

#define LOOP      12
#define DIVIDE    49
#define ANGLE     0.2617993878
#define RADIUS    0.002

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_hsv (float3 rgb)
{
   // This is a standard HSV converter, so it isn't commented except where it
   // differs from normal practice

   float val = max (rgb.r, max (rgb.g, rgb.b));
   float rng = val - min (rgb.r, min (rgb.g, rgb.b));
   float hue, sat = rng / val;

   if (sat == 0.0) { hue = 0.0; }
   else {
      if (rgb.r == val) {
         hue = (rgb.g - rgb.b) / rng;

         if (hue < 0.0) hue += 6.0;
      }
      else if (rgb.g == val) { hue = 2.0 + ((rgb.b - rgb.r) / rng); }
      else hue = 4.0 + ((rgb.r - rgb.g) / rng);

      // Normally we would have hue /= 6.0 here, but not doing that gives us
      // a steeper slope when we actually generate the key in the main code.
   }

   return float3 (hue, sat, val);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input)
{
   float4 Fgnd = ReadPixel (Inp, uv1);       // First get the input to process

   // Before we do anything set up the crop, allowing for Inp rotation.

   float3 Fhsv = fn_hsv (Fgnd.rgb);          // Convert it to our modified HSV
   float3 Chsv = fn_hsv (MaskColour.rgb);    // Do the same for the ref colour

   // Calculate the chroma difference.  Since what we want is actually the dark
   // sections of the mask, we double and clip it before any further processing.

   float cDiff = min (distance (Fhsv, Chsv) * 2.0, 1.0);

   // Now we generate the mask, adjusting clip and slope first then inverting it

   float mask  = 1.0 - smoothstep (MaskClip, MaskClip + MaskSep, cDiff);

   // Mask linearity is actually a gamma setting and runs from 0.01 to 4.0.  It's
   // also inverted at this stage, so that the power is actually from 100 to 0.25

   float gamma = 1.0 / pow (MIN_GAMMA + (MAX_GAMMA * MaskGamma), 2.0);

   // The black crush factor is limited to the range 0.0 - 0.9

   float black = saturate (MaskBlack) * LEVELS;

   // The mask is adjusted for gamma and black crush.

   mask = (pow (mask, gamma) - black) / (1.0 - black);

  // It is now white clipped and applied to the alpha channel of our image.

   Fgnd.a = saturate (mask / ((MaskWhite * LEVELS) + OFFSET));

   return Fgnd;
}

DeclareEntryPoint (DeBlemish)
{
   float4 source = ReadPixel (Inp, uv1);        // First get the input to process
   float4 retval = tex2D (Input, uv2);          // Get the masked input

   if (ShowMask) return retval.aaaa;            // Show it if we need to

   float4 Fgnd = ReadPixel (Inp, uv1);          // Now get the raw input

   if ((Size > 0.0) && (Amount > 0.0)) {        // Process the image if required

      float angle = 0.0;                        // Set the blur rotation to zero

      // Calculate the blur radius based on size and aspect ratio.

      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;

      // In the blur loop we do two samples at 180 degree offsets, then another
      // two in which the sample offset is doubled, for a total of four samples
      // for each iteration of the loop.  Rather than multiply the angle by i
      // each time we go round we do a simple addition for the same result.

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         retval += tex2D (Input, uv2 + xy);
         retval += tex2D (Input, uv2 - xy);
         xy += xy;
         retval += tex2D (Input, uv2 + xy);
         retval += tex2D (Input, uv2 - xy);
         angle  += ANGLE;
      }

      retval /= DIVIDE;

      // The blurred flesh tones are now keyed into the original footage
      // using the blurred mask.  The original alpha value is preserved.

      Fgnd.rgb = lerp (Fgnd.rgb, retval.rgb, retval.a * Amount);
   }

   Fgnd = lerp (kTransparentBlack, Fgnd, source.a);

   return lerp (source, Fgnd, tex2D (Mask, uv1).x);
}

