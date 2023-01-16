// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect emulates the classic analog vision mixer non-add mix.  It uses an algorithm
 that mimics reasonably closely what the electronics used to do.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAdd_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Non-additive mix", "Mix", "Blend transitions", "Emulates the classic analog vision mixer non-add mix", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (NonAdd_Dx)
{
   float4 Fgnd = lerp (ReadPixel (Fg, uv1), kTransparentBlack, Amount);
   float4 Bgnd = lerp (kTransparentBlack, ReadPixel (Bg, uv2), Amount);
   float4 Mix  = max (Bgnd, Fgnd);

   float Gain = (1.0 - abs (Amount - 0.5)) * 2.0;

   return saturate (Mix * Gain);
}

