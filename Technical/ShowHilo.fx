// @Maintainer jwrl
// @Released 2023-01-11
// @Author juhartik
// @Created 2016-05-09

/**
 This effect blinks extreme blacks and whites.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ShowHiLo.fx
//
// JH Analysis Show Hi/Lo v1.0 - Juha Hartikainen - juha@linearteam.org - Blinks extreme
// darks/highlights.
//
// Version history:
//
// Updated 2023-01-13 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Show highs and lows", "User", "Technical", "This effect blinks blacks and whites that exceed preset levels", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (LoLimit, "Low Limit", kNoGroup, kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (HiLimit, "High Limit", kNoGroup, kNoFlags, 0.95, 0.0, 1.0);

DeclareFloatParam (_Length);
DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ShowHiLo)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 color = tex2D (Input, uv1);

   float weight = (color.r + color.g + color.b) / 3.0;

   if ((weight <= LoLimit) || (weight >= HiLimit))
      color.rgb = frac (_Progress * _Length * 3.0) > 0.5 ? 1.0.xxx : 0.0.xxx;

   return color;
}

