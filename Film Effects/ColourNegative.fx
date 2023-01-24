// @Maintainer jwrl
// @Released 2023-01-24
// @Author jwrl
// @Created 2023-01-24

/**
 This simulates the look of 35 mm colour masked negative film.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourNegative.fx
//
// Version history:
//
// Built 2023-01-24 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Colour negative", "Colour", "Film Effects", "Simulates the look of 35 mm colour film dye-masked negative", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ColourNegative)
{
   float4 source = ReadPixel (Input, uv1);
   float4 retval = source;

   retval.rgb = (float3 (2.0, 1.33, 1.0) - retval.rgb) / 2.0;

   retval = lerp (kTransparentBlack, retval, retval.a);

   return lerp (source, retval, tex2D (Mask, uv1).x);
}

