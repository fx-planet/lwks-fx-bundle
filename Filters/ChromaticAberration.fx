// @Maintainer jwrl
// @Released 2023-01-19
// @Author josely
// @Created 2012-06-29

/**
 Generates or removes chromatic aberration.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaticAberration.fx
//
// Chromatic Abberation Copyright (c) Johannes Bausch (josely). All rights reserved.
//
// Version history:
//
// Updated 2023-01-19 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chromatic aberration", "Stylize", "Filters", "Generates or removes chromatic aberration", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Mode, "Chromatic Band", kNoGroup, 0, "Half|Full");

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 0.1, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define STEPS   12
#define STEPS_2 24               // STEPS * 2
#define STEPS_3 36               // STEPS * 3
#define STEP_RB 1.846            // STEPS / (1 - 0.5 * (STEPS + 1) + STEPS)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (ChromaticAberration)
{
   float4 source    = tex2D (Input, uv1);
   float4 fragColor = float4 (0.0.xxx, 1.0);

   float2 xy, color, coord = uv2 - 0.5.xx;

   float multiplier = length (coord) * Amount * float (1 + Mode) / 100.0;
   float Scale;

   coord *= multiplier;

   for (int i = 0; i < STEPS; i++) {
      xy = uv2 - (i * coord);
      Scale = (float) i / STEPS;
      color = tex2D (Inp, xy).rg / STEPS;
      color *= float2 (1.0 - Scale, Scale);
      fragColor.rg += color;
   }

   for (int i = STEPS; i <= STEPS_2; i++) {
      xy = uv2 - (i * coord);
      Scale = (float) (i - STEPS) / STEPS;
      color = tex2D (Inp, xy).gb / STEPS;
      color *= float2 (1.0 - Scale, Scale);
      fragColor.gb += color;
   }

   if (Mode) {
      for (int i = STEPS_2; i < STEPS_3; i++) {
         xy = uv2 - (i * coord);
         Scale = (float) (i - STEPS_2) / STEPS;
         color = tex2D (Inp, xy).br / STEPS;
         color *= float2 (1.0 - Scale, Scale);
         fragColor.br += color;
      }
   }
   else { fragColor.rb *= STEP_RB; }   // Half cycle correction

   fragColor = lerp (kTransparentBlack, fragColor, ReadPixel (Input, uv1).a);

   return lerp (source, fragColor, tex2D (Mask, uv1));
}

