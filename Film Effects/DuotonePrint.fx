// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2016-04-12

/**
 This simulates the effect of the old Duotone film colour process.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DuotonePrint.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Duotone print", "Colour", "Film Effects", "This simulates the look of the old Duotone colour film process", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Saturation, "Saturation", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Profile, "Colour profile", kNoGroup, kNoFlags, 1.0, -1.0, 1.0);
DeclareFloatParam (Curve, "Dye curve", kNoGroup, kNoFlags, 0.4, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define R_ORG  1.4088
#define G_ORG  0.5912

#define G_BGN  1.7472
#define B_BGN  0.2528

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (DuotonePrint)
{
   float4 source = ReadPixel (Input, uv1);
   float4 retval = source;

   float gamma = (Curve > 0.0) ? 1.0 - Curve * 0.2 : 1.0;
   float luma  = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float alpha = retval.a;

   float4 altret = float2 (luma, retval.a).xxxy;
   float4 desat  = altret;

   float orange = dot (retval.rg, float2 (G_ORG, R_ORG));
   float cyan   = dot (retval.gb, float2 (G_BGN, B_BGN));

   altret.r = orange - luma;
   altret.b = cyan - luma;

   retval.r    = orange / 2.0;
   retval.b    = cyan / 2.0;
   luma        = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   retval.rgb += retval.rgb - luma.xxx;

   retval = saturate (lerp (altret, retval, Profile));
   retval = pow (retval, gamma);

   retval = lerp (desat, retval, Saturation * 4.0);

   retval = lerp (kTransparentBlack, retval, alpha);

   return lerp (source, retval, tex2D (Mask, uv1).x);
}

