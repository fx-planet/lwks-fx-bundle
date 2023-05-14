// @Maintainer jwrl
// @Released 2023-05-14
// @Author khaver
// @Created 2011-04-18

/**
 In Toon (Toon_2022.fx) the image is posterized, then outlines are developed from the
 image edges.  These are then applied on top of the already posterized image to give
 the final result.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Toon.fx
//
// Version history:
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Toon", "Stylize", "Art Effects", "The image is posterized then outlines derived from the edges are added to produce a cartoon-like result", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (RedStrength, "RedStrength", "Master", "DisplayAsPercentage", 4.0, 1.0, 100.0);
DeclareFloatParam (GreenStrength, "GreenStrength", "Master", "DisplayAsPercentage", 4.0, 1.0, 100.0);
DeclareFloatParam (BlueStrength, "BlueStrength", "Master", "DisplayAsPercentage", 4.0, 1.0, 100.0);
DeclareFloatParam (Threshold, "Threshold", "Master", kNoFlags, 0.1, 0.0, 10.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define NUM 9

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Toon)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   // Read a pixel from the source image at position 'uv1' into the variable 'color'

   float4 color = ReadPixel (Input, uv1);
   float4 src1 = color;

   color.r = round (color.r * RedStrength) / RedStrength;
   color.g = round (color.g * GreenStrength) / GreenStrength;
   color.b = round (color.b * BlueStrength) / BlueStrength;

   float2 c [NUM] = { { -0.0078125, 0.0078125 }, {  0.0, 0.0078125 },
                      {  0.0078125, 0.0078125 }, { -0.0078125, 0.0 },
                      { 0.0, 0.0 }, { 0.0078125, 0.007 }, { -0.0078125,-0.0078125 },
                      { 0.0, -0.0078125 }, { 0.0078125, -0.0078125 } };
   int i;

   float3 col [NUM];

   for (i = 0; i < NUM; i++) {
      col [i] = tex2D (Input, uv1 + 0.2 * c [i]).rgb;
      }

   float3 rgb2lum = float3 (0.30, 0.59, 0.11);

   float lum [NUM];

   for (i = 0; i < NUM; i++) {
      lum [i] = dot (col [i].xyz, rgb2lum);
      }

   float x = lum [2] +  lum [8] + 2 * lum[5] - lum [0] - 2 * lum [3] - lum [6];
   float y = lum [6] + 2 * lum [7] + lum [8] - lum [0] - 2 * lum [1] - lum [2];
   float edge = (x * x) + (y * y) < Threshold ? 1.0 : 0.0;

   color.rgb *= edge;

   return lerp (src1, color, tex2D (Mask, uv1).x);
}
