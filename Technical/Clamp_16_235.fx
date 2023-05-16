// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2011-05-05

/**
 This is one of three tools to manage broadcast colour space.  The names are self-explanatory.
 They install into the custom category "User", subcategory "Technical".

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Clamp_16_235.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Clamp to 16-235", "User", "Technical", "Clamps full swing RGB signal to legal video gamut", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Clamp_16_235)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 color = tex2D (Input, uv1);

   float highc = 235.0 / 255.0;
   float lowc = 16.0 / 255.0;

   color.rgb = clamp (color.rgb, lowc, highc);

   return color;
}

