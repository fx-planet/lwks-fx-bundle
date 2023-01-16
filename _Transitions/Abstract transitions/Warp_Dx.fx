// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is a dissolve that warps.  The warp is driven by the background image, and so will be
 different each time that it's used.  It supports both normal media as well as titles and
 other blended effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Warp_Dx_2022.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Warp transition 2022+", "Mix", "Abstract transitions", "Warps between two shots or into or out of effects", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Distortion, "Distortion", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

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

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint ()
{
   float4 Warp = tex2D (Fgd, uv3);

   float warpFactor = sin (Amount * PI) * Distortion * 4.0;

   float2 xy1 = uv3 - float2 (Warp.b - Warp.r, Warp.g) * warpFactor;

   float4 Fgnd = tex2D (Fgd, xy1);

   Warp = tex2D (Bgd, uv3);
   xy1 = uv3 - float2 (Warp.b - Warp.r, Warp.g) * warpFactor;

   return lerp (Fgnd, tex2D (Bgd, xy1), Amount);
}

