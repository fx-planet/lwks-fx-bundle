// @Maintainer jwrl
// @Released 2023-01-11
// @Author khaver
// @Created 2011-05-05

/**
 This is one of three tools to manage broadcast colour space.  The names are self-explanatory.
 They install into the custom category "User", subcategory "Technical".

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Expand_16_235.fx
//
// Version history:
//
// Updated 2023-01-11 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Expand 16-235 to 0-255", "User", "Technical", "Expands legal video levels to full gamut RGB", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (superwhite, "Keep super whites", kNoGroup, false);
DeclareBoolParam (superblack, "Keep super blacks", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Expand_16_235)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 color = tex2D (Input, uv1);

   float highc = 20.0 / 255.0;
   float lowc = 16.0 / 255.0;
   float alpha = color.a;

   if (superwhite) { if (!superblack) color = (color - lowc.xxxx) / (1.0 - lowc); }
   else if (superblack) { color = ((color - highc.xxxx) / (1.0 - highc)) + highc; }
   else { color = (color - lowc.xxxx) / (1.0 - lowc - highc); }

   color = saturate (color);
   color.a = alpha;

   return color;
}

