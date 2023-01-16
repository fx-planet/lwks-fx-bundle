// @Maintainer jwrl
// @Released 2023-01-09
// @Author khaver
// @Created 2011-04-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Technicolor_640.png

/**
 Simulates the look of the classic 2-strip and 3-strip Technicolor film processes.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Technicolor.fx
//
// Version history:
//
// Updated 2023-01-09 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Technicolor", "Colour", "Film Effects", "Simulates the look of the classic 2-strip and 3-strip Technicolor film processes", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Emulation", kNoGroup, 0, "Two_Strip|Three_Strip");

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (TechnicolorTwoStrip)
{
   float4 source = ReadPixel (Input, uv1);
   float4 output = source;

   output.g += source.b / 2.0;
   output.b += source.g / 2.0;

   return lerp (source, lerp (kTransparentBlack, output, source.a), tex2D (Mask, uv1));
}

DeclareEntryPoint (TechnicolorThreeStrip)
{
   float4 source = ReadPixel (Input, uv1);
   float4 output = source;

   output.r += (source.b - source.g) / 2.0;
   output.g += (source.b - source.r) / 2.0;
   output.b += (source.g - source.r) / 2.0;

   return lerp (source, lerp (kTransparentBlack, output, source.a), tex2D (Mask, uv1));
}


