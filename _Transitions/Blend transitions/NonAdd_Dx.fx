// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect emulates the classic analog vision mixer non-add mix.  It uses an algorithm
 that mimics reasonably closely what the electronics used to do.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAdd_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
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

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAdd_Dx)
{
   float4 Fgnd = lerp (tex2D (Outgoing, uv3), kTransparentBlack, Amount);
   float4 Bgnd = lerp (kTransparentBlack, tex2D (Incoming, uv3), Amount);
   float4 Mix  = max (Bgnd, Fgnd);

   float Gain = (1.0 - abs (Amount - 0.5)) * 2.0;

   return saturate (Mix * Gain);
}

