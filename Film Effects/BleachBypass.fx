// @Maintainer jwrl
// @Released 2023-02-17
// @Author msi
// @Created 2011-05-27

/**
 This effect emulates the altered contrast and saturation obtained by skipping the bleach
 step in classical colour film processing.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BleachBypass.fx
//
// Licensed Creative Commons [BY-NC-SA]
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//
// Updated 2023-01-24 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bleach bypass", "Colour", "Film Effects", "Emulates the altered contrast and saturation obtained by skipping the bleach step in classical colour film processing", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Red, "Red Channel", "Luminosity", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Green, "Green Channel", "Luminosity", kNoFlags, 0.65, 0.0, 1.0);
DeclareFloatParam (Blue, "Blue Channel", "Luminosity", kNoFlags, 0.11, 0.0, 1.0);

DeclareFloatParam (BlendOpacity, "Blend Opacity", "Overlay", kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (BleachBypass)
{
   float4 source = ReadPixel (Input, uv1);

   // BEGIN Bleach bypass routine by NVidia
   // (http://developer.download.nvidia.com/shaderlibrary/webpages/hlsl_shaders.html#post_bleach_bypass)

   float lum = dot (float3 (Red, Green, Blue), source.rgb);

   float3 result1 = 2.0 * source.rgb * lum;
   float3 result2 = 1.0.xxx - 2.0 * (1.0 - lum) * (1.0.xxx - source.rgb);
   float3 newC = lerp (result1, result2, saturate (10.0 * (lum - 0.45)));
   float3 mixRGB = (BlendOpacity * source.a) * newC.rgb;

   mixRGB += ((1.0 - (BlendOpacity * source.a)) * source.rgb);

   // END Bleach bypass routine by NVidia

   float4 retval = float4 (lerp (kTransparentBlack, mixRGB, source.a), source.a);

   return lerp (source, retval, tex2D (Mask, uv1).x);
}

