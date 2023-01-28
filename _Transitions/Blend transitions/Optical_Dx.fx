// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This is an attempt to simulate the look of the classic film optical dissolve.  To do this
 it applies a non-linear curve to the transition, and at the centre mixes in a stretched
 blend with a touch of black crush.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Optical_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Optical dissolve", "Mix", "Blend transitions", "Simulates the burn effect of a film optical dissolve", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Optical_Dx)
{
   float cAmount = sin (Amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (Amount * PI)) / 2.0;

   float4 fgPix = tex2D (Outgoing, uv3);
   float4 bgPix = tex2D (Incoming, uv3);
   float4 retval = lerp (min (fgPix, bgPix), bgPix, Amount);

   fgPix = lerp (fgPix, min (fgPix, bgPix), Amount);
   retval = lerp (fgPix, retval, aAmount);

   cAmount += 1.0;

   return saturate ((retval * cAmount) - bAmount.xxxx);
}

