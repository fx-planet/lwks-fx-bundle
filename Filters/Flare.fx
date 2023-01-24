// @Maintainer jwrl
// @Released 2023-01-24
// @Author khaver
// @Created 2011-05-24

/**
 Flare is an original effect by khaver which creates an adjustable lens flare effect.
 The origin of the flare can be positioned by adjusting the X and Y sliders or by
 dragging the on-viewer icon with the mouse.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Flare.fx
//
// Version history:
//
// Updated 2023-01-24 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flare", "Stylize", "Filters", "Creates an adjustable lens flare effect", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (CentreX, "Origin", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Origin", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Stretch, "Stretch", kNoGroup, kNoFlags, 5.0, 0.0, 100.0);
DeclareFloatParam (adjust, "Adjust", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Adjusted)
{
   float4 Color = ReadPixel (Input, uv1);

   if (Color.r < 1.0 - adjust) Color.r = 0.0;
   if (Color.g < 1.0 - adjust) Color.g = 0.0;
   if (Color.b < 1.0 - adjust) Color.b = 0.0;

   return Color;
}

DeclareEntryPoint (Flare)
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 amount = float2 (1.0, _OutputAspectRatio) * Stretch / _OutputWidth;
   float2 adj = amount;
   float2 xy = uv2 - centre;

   float scale = 0.0;
   
   float4 source = ReadPixel (Input, uv1);
   float4 negative = tex2D (Adjusted, uv2);
   float4 ret = tex2D (Adjusted, (xy * adj) + centre);

   for (int count = 1; count < 13; count++) {
      scale += Strength;
      adj += amount;
      ret += tex2D (Adjusted, (xy * adj) + centre) * scale;
   }

   ret /= 15.0;
   ret.a = 0.0;

   ret = lerp (kTransparentBlack, saturate (ret + source), source.a);

   return lerp (source, ret, tex2D (Mask, uv1).x);
}

