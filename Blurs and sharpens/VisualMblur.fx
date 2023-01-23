// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Created 2023-01-23

/**
 A directional blur that can be used to simulate fast motion, whip pans and the like.  This
 differs from other blur effects in that it is set up by visually dragging a central pin
 point in the record viewer to adjust the angle and strength of the blur.  This effect will
 break LW resolution independence.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualMblur.fx
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Visual motion blur", "Stylize", "Blurs and sharpens", "A directional blur that can be quickly set up by visually dragging a central pin point.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Blur amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Blur_X, "Blur", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Blur_Y, "Blur", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (VisualMblur)
{
   float4 Fgnd = ReadPixel (Inp, uv1);

   // Centre the cursor X-Y coordiantes around zero.

   float2 xy1 = uv1;
   float2 xy2 = float2 (0.5 - Blur_X, (Blur_Y - 0.5) * _OutputAspectRatio);

   // If the amount is zero or less, or if xy2 is zero quit without doing anything.

   if (distance (0.0.xx, xy2) == 0.0) return Fgnd;

   // Initialise the mix value, initial pixel address and blur sample.

   float mix = 0.0327868852;

   float4 Blur = Fgnd * mix;

   // Scale xy2 so that the derived blur length is reasonable and easily controlled.

   xy2 *= 0.005;

   // Do a directional blur by progressively sampling pixels at increasing 6 degree
   // offsets, and reducing their mix amount to zero linearly to fade the blur out.

   for (int i = 0; i < 60; i++) {
      mix -= 0.0005464481;
      xy1 += xy2;
      Blur += mirror2D (Inp, xy1) * mix;
   }

   // Finally mix the blur back into the original foreground video.

   return lerp (Fgnd, Blur, tex2D (Mask, uv1).x * Fgnd.a);
}

