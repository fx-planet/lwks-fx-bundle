// @Maintainer jwrl
// @Released 2023-01-30
// @Author jwrl
// @Created 2023-01-30

/**
 This is a dissolve that warps.  The warp is driven by the background image, and so will be
 different each time that it's used.  It supports both normal media as well as titles and
 other blended effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 Unlike with LW transitions there is no mask.  Instead the ability to crop the effect
 to the background is provided, which dissolves between the cropped areas during the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Warp_Dx.fx
//
// Version history:
//
// Built 2023-01-30 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Warp transition", "Mix", "Abstract transitions", "Warps between two shots or into or out of effects", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Distortion, "Distortion", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Warp_Dx)
{
   float4 Warp = tex2D (Outgoing, uv3);

   float warpFactor = sin (Amount * PI) * Distortion * 4.0;

   float2 xy1 = uv3 - float2 (Warp.b - Warp.r, Warp.g) * warpFactor;

   float4 Fgnd = tex2D (Outgoing, xy1);

   Warp = tex2D (Incoming, uv3);
   xy1 = uv3 - float2 (Warp.b - Warp.r, Warp.g) * warpFactor;

   float4 retval = lerp (Fgnd, tex2D (Incoming, xy1), Amount);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Warp = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Warp, Amount);
   }

   return retval;
}

