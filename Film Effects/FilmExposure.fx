// @Maintainer jwrl
// @Released 2023-05-16
// @Author abelmilanes
// @Author jwrl
// @Created 2017-03-04

/**
 This is an effect that simulates exposure adjustment using a Cineon profile.  It is
 fairly accurate at the expense of requiring some reasonably complex maths.  With current
 GPU types this shouldn't be an issue.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmExposure.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Film exposure", "Colour", "Film Effects", "Simulates exposure adjustment using a Cineon profile", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Exposure, "Master", "Exposure", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (CyanRed, "Cyan/red", "Exposure", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (MagGreen, "Magenta/green", "Exposure", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (YelBlue, "Yellow/blue", "Exposure", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Amount, "Original", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FilmExposure)
{
   float4 retval, Src = ReadPixel (Input, uv1);

   // Convert RGB to linear

   float test = max (Src.r, max (Src.g, Src.b));   // Workaround to address Cg's all() bug

   float3 lin = (test < 0.04045) ? Src.rgb / 12.92 : pow ((Src.rgb + 0.055.xxx) / 1.055, 2.4);

   // Convert linear to Kodak Cineon

   float3 logOut   = ((log10 ((lin * 0.9892) + 0.0108) * 300.0) + 685.0) / 1023.0;
   float3 exposure = { CyanRed, MagGreen, YelBlue };

   exposure = (exposure + Exposure) * 0.1;

   // Adjust exposure then convert back to linear

   logOut = (((logOut + exposure) * 1023.0) - 685.0) / 300.0;
   lin = (pow (10.0.xxx, logOut) - 0.0108.xxx) * 1.0109179;

   // Back to RGB

   test = max (lin.r, max (lin.g, lin.b));

   retval.rgb = (test < 0.0031308) ? lin * 12.92 : (1.055 * pow (lin, 0.4166667)) - 0.055;
   retval = lerp (kTransparentBlack, float4 (saturate (retval.rgb), 1.0), Src.a);
   retval = lerp (retval, Src, Amount);

   return lerp (Src, retval, tex2D (Mask, uv1).x);
}

