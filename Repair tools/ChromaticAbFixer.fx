// @Maintainer jwrl
// @Released 2023-01-10
// @Author khaver
// @Created 2011-05-18

/**
 This effect is pretty self explanatory.  When you need it, you need it.  It zooms in and
 out of the red, green and blue channels independently to help remove the colour fringing
 (chromatic aberration) in areas near the edges of the frame often produced by cheaper
 lenses.  To see the fringing better while adjusting click the saturation check box.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaticAbFixer.fx
//
// Version history:
//
// Updated 2023-01-10 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chromatic aberration fixer", "Stylize", "Repair tools", "Generates or removes chromatic aberration", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (V);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (radjust, "Red adjust", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (gadjust, "Green adjust", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (badjust, "Blue adjust", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareBoolParam (saton, "Saturation", "Saturation", false);

DeclareFloatParam (sat, "Adjustment", "Saturation", kNoFlags, 2.0, 0.0, 4.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ChromaticAbFixer)
{
   float satad = (!saton) ? 1.0 : sat;
   float rad = ((radjust * 2.0 + 4.0) / 100.0) + 0.96;
   float gad = ((gadjust * 2.0 + 4.0) / 100.0) + 0.96;
   float bad = ((badjust * 2.0 + 4.0) / 100.0) + 0.96;

   float2 xy = uv1 - 0.5.xx;

   float3 source;

   float4 Fgd = ReadPixel (V, uv1);

   source.r = ReadPixel (V, (xy / rad) + 0.5.xx).r;
   source.g = ReadPixel (V, (xy / gad) + 0.5.xx).g;
   source.b = ReadPixel (V, (xy / bad) + 0.5.xx).b;

   float3 lum  = dot (source, float3 (0.299, 0.587, 0.114)).xxx;
   float3 dest = lerp (lum, source, satad);

   return lerp (Fgd, lerp (kTransparentBlack, float4 (dest, 1.0), Fgd.a), tex2D (Mask, uv1));
}

