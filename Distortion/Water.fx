// @Maintainer jwrl
// @Released 2023-07-13
// @Author khaver
// @Created 2011-04-21

/**
 Water makes waves as well as refraction, and provides X and Y adjustment of the
 parameters.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Water.fx
//
// Version history:
//
// Updated 2023-07-13 jwrl.
// Corrected creation date.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-08 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Water", "Stylize", "Distortion", "This makes waves as well as refraction, and provides X and Y adjustment of the parameters", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Speed, "Speed", kNoGroup, kNoFlags, 0.0, 0.0, 1000.0);
DeclareFloatParam (WavesX, "X Frequency", kNoGroup, kNoFlags, 0.0, 0.0, 100.0);
DeclareFloatParam (StrengthX, "X Strength", kNoGroup, kNoFlags, 0.0, 0.0, 0.1);
DeclareFloatParam (WavesY, "Y Frequency", kNoGroup, kNoFlags, 0.0, 0.0, 100.0);
DeclareFloatParam (StrengthY, "Y Strength", kNoGroup, kNoFlags, 0.0, 0.0, 0.1);

DeclareBoolParam (Flip, "Waves", kNoGroup, false);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Water)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float wavesx = WavesX * 2.0;
   float wavesy = WavesY * 2.0;

   float2 xy = uv1;

   if (Flip) {
      xy.x += sin ((_Progress * Speed) + xy.y * wavesy) * StrengthY;
      xy.y += cos ((_Progress * Speed) + xy.x * wavesx) * StrengthX;
   }
   else {
      xy.x += sin ((_Progress * Speed) + xy.x * wavesx) * StrengthX;
      xy.y += cos ((_Progress * Speed) + xy.y * wavesy) * StrengthY;
   }

   float4 Color = tex2D (Input, xy);
   float4 Fgnd  = tex2D (Input, uv1);

   return lerp (Fgnd, Color, tex2D (Mask, uv1).x);
}

