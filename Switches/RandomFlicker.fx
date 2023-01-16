// @Maintainer jwrl
// @Released 2023-01-10
// @Author jwrl
// @Created 2023-01-10

/**
 This effect is a pseudo random switch between two inputs.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RandomFlicker.fx
//
// Version history:
//
// Built 2023-01-10 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Random flicker", "User", "Switches", "Does a pseudo random switch between two inputs.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In1, In2);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Speed, "Speed", "Switch settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Random, "Randomness", "Switch settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define OFFS_1  1.8571428571
#define OFFS_2  1.3076923077

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RandomFlicker)
{
   float freq = floor ((_LengthFrames * _Progress) + 0.5) * max (Speed, 0.01) * 19.0;
   float frq1 = max (0.5, Random + 0.5);
   float frq2 = pow (frq1, 3.0) * freq * OFFS_2;

   frq1 *= freq * OFFS_1;

   float strobe = max (sin (freq) + sin (frq1) + sin (frq2), 0.0);

   float4 Bgnd = ReadPixel (In2, uv2);
   float4 retval = strobe == 0.0 ? lerp (Bgnd, ReadPixel (In1, uv1), Opacity) : Bgnd;

   return lerp (Bgnd, retval, tex2D (Mask, uv1));
}

