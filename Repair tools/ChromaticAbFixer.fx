// @Maintainer jwrl
// @Released 2023-05-16
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
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chromatic aberration fixer", "Stylize", "Repair tools", "Generates or removes chromatic aberration", CanSize);

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

DeclarePass (Inp)
{ return ReadPixel (V, uv1); }

DeclareEntryPoint (ChromaticAbFixer)
{
   float satad = (!saton) ? 1.0 : sat;
   float rad = ((radjust * 2.0 + 4.0) / 100.0) + 0.96;
   float gad = ((gadjust * 2.0 + 4.0) / 100.0) + 0.96;
   float bad = ((badjust * 2.0 + 4.0) / 100.0) + 0.96;

   float2 xy = uv2 - 0.5.xx;

   float3 source;

   source.r = tex2D (Inp, (xy / rad) + 0.5.xx).r;
   source.g = tex2D (Inp, (xy / gad) + 0.5.xx).g;
   source.b = tex2D (Inp, (xy / bad) + 0.5.xx).b;

   float4 Fgd = tex2D (Inp, uv2);

   float3 lum  = dot (source, float3 (0.299, 0.587, 0.114)).xxx;
   float3 dest = lerp (lum, source, satad);

   float4 retval = lerp (kTransparentBlack, float4 (dest, Fgd.a), Fgd.a);

   return lerp (Fgd, retval, tex2D (Mask, uv2).x);
}

