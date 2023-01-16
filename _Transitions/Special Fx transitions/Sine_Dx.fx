// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is a dissolve/wipe that uses a sine distortion to do a left-right or right-left
 transition between the inputs.  The phase can also be offset by 180 degrees.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sine_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sinusoidal mix", "Mix", "Special Fx transitions", "Uses a sine distortion to do a left-right or right-left transition between the inputs", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Direction, "Direction", kNoGroup, 0, "Left to right|Right to left");

DeclareIntParam (Mode, "Distortion", "Ripples", 0, "Normal|Inverted");

DeclareFloatParam (Width, "Softness", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples, "Spread", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Spread, "Amount", "Ripples", kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Sine_Dx)
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = Amount * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? uv3.x : 1.0 - uv3.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv3.x, uv3.y + offset) : float2 (uv3.x, uv3.y - offset);

   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = ReadPixel (Bgd, xy);

   return lerp (Fgnd, Bgnd, amount);
}

