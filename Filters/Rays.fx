// @Maintainer jwrl
// @Released 2023-02-17
// @Author khaver
// @Created 2012-01-19

/**
 This effect radiates rays away from the highlights in the image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rays.fx
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//
// Updated 2023-01-10 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rays", "Stylize", "Filters", "Radiates light rays away from the highlights in the image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (CX, "Center", kNoGroup, "SpecifiesPointX", 0.5, -1.5, 2.5);
DeclareFloatParam (CY, "Center", kNoGroup, "SpecifiesPointY", 0.5, -1.5, 2.5);

DeclareFloatParam (BlurAmount, "Length", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Radius, "Radius", kNoGroup, kNoFlags, 2.0, 0.0, 2.0);
DeclareFloatParam (RThreshold, "Red Threshold", kNoGroup, kNoFlags, 0.8, 0.0, 1.0);
DeclareFloatParam (GThreshold, "Green Threshold", kNoGroup, kNoFlags, 0.8, 0.0, 1.0);
DeclareFloatParam (BThreshold, "Blue Threshold", kNoGroup, kNoFlags, 0.8, 0.0, 1.0);
DeclareFloatParam (Mix, "Brightness", kNoGroup, kNoFlags, 2.0, 0.0, 10.0);

DeclareFloatParam (_OutputWidth);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclarePass (Mask)
{
   float2 Center = float2 (CX, 1.0 - CY) - 0.5.xx;
   float2 xy = uv2 - 0.5.xx;

   float4 color = kTransparentBlack;
   float4 rays = tex2D (Inp, uv2);

   if (rays.r >= RThreshold) color.r = rays.r;
   if (rays.g >= GThreshold) color.g = rays.g;
   if (rays.b >= BThreshold) color.b = rays.b;

   xy.x *= _OutputAspectRatio;

   float factor = 2.0 - distance (xy, Center);

   if (2.0 - factor > Radius) factor = 0.0;

   return color * factor;
}

DeclarePass (Partial)
{
   float2 Center = float2 (CX, 1 - CY);
   float2 xy = uv2 - Center;

   float4 c = kTransparentBlack;

   float scale;

   for (int i = 0; i < 25; i++) {
      scale = 1.0 - BlurAmount * ((float) i / 40.0);
      c += tex2D (Mask, xy * scale + Center) * ((40.0 - (float) i) / 60.0);
   }

   c /= 41.0;

   return c;
}

DeclareEntryPoint (Rays)
{
   float2 Center = float2 (CX, 1.0 - CY);
   float2 xy = uv2 - Center;

   float4 c = kTransparentBlack;

   float scale;

   for (int i = 25; i < 41; i++) {
      scale = 1.0 - BlurAmount * ((float) i / 40.0);
      c += tex2D (Mask, xy * scale + Center) * ((40.0 - (float) i) / 60.0);
   }

   c /= 41;

   float4 base  = tex2D (Inp, uv2);
   float4 pre_c = tex2D (Partial, uv2);
   float4 blend = (pre_c + (c * (1.0.xxxx - pre_c))) * Mix;

   blend = (base + blend * (1.0.xxxx - base));

   return lerp (kTransparentBlack, blend, base.a);
}

