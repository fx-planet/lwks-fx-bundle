// @Maintainer jwrl
// @Released 2023-05-20
// @Author nouanda
// @Created 2014-10-20

/**
 A means of cloning sections of the image into other sections, in a similar way to the art
 tool.  This effect breaks resolution independence.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CloneStamp.fx
//
// Collective effort from Lightworks Forum members nouanda // brdloush // jwrl
// Ok, we're amateurs, but we managed to do it!
//
// Absolutely no copyright - none - zero - nietchevo - rien - it's not rocket science,
// why should we claim a copyright?  Feel free to use at your envy!
//
// Function aspectAdjustedpos from Lwks' shapes2.fx shader
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-05-20 jwrl.
// Destination parameter reformatted.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Clone Stamp", "Stylize", "Repair tools", "A means of cloning sections of the image into other sections similar to art software", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Shape", kNoGroup, 0, "Ellipse|Rectangle");

DeclareFloatParam (Size, "Size", "Parameters", kNoFlags, 0.33, 0.0, 1.0);
DeclareFloatParam (Softness, "Softness", "Parameters", kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Interpolation, "Interpolation", "Parameters", 0, "Linear|Square|Sinusoidal");

DeclareFloatParam (SrcPosX, "Source Position", "Parameters", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (SrcPosY, "Source Position", "Parameters", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (AspectRatio, "Aspect ratio x:1", "Parameters", kNoFlags, 1.0, 0.3, 3.3333333);

DeclareFloatParam (DestPosX, "Destination", "Parameters", "SpecifiesPointX", 0.7, 0.0, 1.0);
DeclareFloatParam (DestPosY, "Destination", "Parameters", "SpecifiesPointY", 0.7, 0.0, 1.0);

DeclareFloatParam (BlendOpacity, "Blend Opacity", "Overlay", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (DestRed, "Red correction", "Color Correction", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (DestGreen, "Green correction", "Color Correction", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (DestBlue, "Blue correction", "Color Correction", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);
DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.14159265
#define PI_AREA 1.27323954

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (CloneStampEllipse)
{
   // Get background (source) texture

   float4 Src = ReadPixel (Input, uv1);

   // Adjust size for circle

   float CircleSize = Size * PI_AREA;

   // Adjust aspect ratio

   float2 DestPos = float2 (DestPosX, 1.0 - DestPosY);
   float2 DestAspectAdjustedPos = ((uv1 - DestPos) / (float2 (AspectRatio, _OutputAspectRatio) * CircleSize)) + DestPos;

   float DestDelta = distance (DestAspectAdjustedPos, DestPos);

   // Apply effect only in the effect radius

   if (CircleSize <= DestDelta) return Src;

   // Correct Softness radius (cannot be greater than the effect radius)

   float SoftRadius = CircleSize * (1.0 - Softness);

   // Distance between the softness radius and the pixel position

   float SoftRing = DestDelta - SoftRadius;

   // Initiate Softness to set Transparency (0 - fully solid by default)

   float Soft = 0.0;

   // If the pixel is in the soft area, interpolate softness as per Interpolation parameter

   if (SoftRing >= 0.0) {
      SoftRing /= (CircleSize - SoftRadius);

      Soft = (Interpolation == 0) ? SoftRing
           : (Interpolation == 1) ? 1.0 - pow (1.0 - pow (SoftRing, 2.0), 0.5)
                                  : 0.5 - (cos (SoftRing * PI) / 2.0);
   }

   // Offset source and destination

   float2 xy = uv1 + float2 (SrcPosX, DestPosY) - float2 (DestPosX, SrcPosY);

   // Get texture for destination replacement

   float4 Dest = ReadPixel (Input, xy);

   // Apply color correction

   Dest.rgb += float3 (DestRed, DestGreen, DestBlue);

   // Apply softness by merging with the background

   Dest = lerp (Dest, Src, Soft);

   // Apply opacity the same way

   return IsOutOfBounds (uv1) ? kTransparentBlack : float4 (lerp (Src.rgb, Dest.rgb, BlendOpacity), Src.a);
}

DeclareEntryPoint (CloneStampRectangle)
{
   // Get background (source) texture

   float4 Src = ReadPixel (Input, uv1);

   // Get destination position so it can be modified.  Parameters are constant, not variables

   float2 DestPos  = float2 (DestPosX, 1.0 - DestPosY);
   float2 DestSize = float2 (AspectRatio, _OutputAspectRatio) * Size;
   float2 SoftSize = DestSize * (1.0 - Softness);

   // Define box effect limits

   float2 BoxMin = DestPos - DestSize / 2.0;
   float2 BoxMax = BoxMin + DestSize;

   // Apply effect only in the effect bounds

   if (any ((uv1 - BoxMin) < 0.0.xx) || any ((uv1 - BoxMax) > 0.0.xx)) return Src;

   // Define softness effect limits

   float2 SoftMin = DestPos - SoftSize / 2.00;
   float2 SoftMax = SoftMin + SoftSize;

   // Define softness range

   float2 RangeMin = (uv1 - SoftMin) / (BoxMin - SoftMin);
   float2 RangeMax = (uv1 - SoftMax) / (BoxMax - SoftMax);

   // If the pixel is in the soft area, interpolate softness as per Interpolation parameter

   if (Interpolation == 1) {
      RangeMin = 1.0.xx - pow ((1.0.xx - pow (RangeMin, 2.0.xx)), 0.5.xx);
      RangeMax = 1.0.xx - pow ((1.0.xx - pow (RangeMax, 2.0.xx)), 0.5.xx);
   }
   else if (Interpolation == 2) {
      RangeMin = 0.5.xx - (cos (RangeMin * PI) / 2.0);
      RangeMax = 0.5.xx - (cos (RangeMax * PI) / 2.0);
   }

   RangeMin = 1.0.xx - RangeMin;
   RangeMax = 1.0.xx - RangeMax;

   float Soft_1 = ((uv1.x >= BoxMin.x) && (uv1.x <= SoftMin.x)) ? RangeMin.x : 1.0;
   float Soft_2 = ((uv1.y >= BoxMin.y) && (uv1.y <= SoftMin.y)) ? RangeMin.y : 1.0;

   if ((uv1.x <= BoxMax.x) && (uv1.x >= SoftMax.x)) Soft_1 = min (Soft_1, RangeMax.x);
   if ((uv1.y <= BoxMax.y) && (uv1.y >= SoftMax.y)) Soft_2 = min (Soft_2, RangeMax.y);

   float Soft = saturate (min (Soft_1, Soft_2) * Soft_1 * Soft_2);

   // Offset source and destination

   float2 xy = uv1 + float2 (SrcPosX, DestPosY) - float2 (DestPosX, SrcPosY);

   // Get texture for destination replacement

   float4 Dest = ReadPixel (Input, xy);

   // Apply color correction

   Dest.rgb += float3 (DestRed, DestGreen, DestBlue);

   // Apply softness by merging with the background

   Dest = lerp (Src, Dest, Soft);

   // Apply opacity the same way

   return IsOutOfBounds (uv1) ? kTransparentBlack : float4 (lerp (Src.rgb, Dest.rgb, BlendOpacity), Src.a);
}
