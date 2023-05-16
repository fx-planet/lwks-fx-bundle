// @Maintainer jwrl
// @Released 2023-05-16
// @Author schrauber
// @Created 2017-01-05

/**
 This is similar in operation to the regional zoom effect, but instead of non-linear
 distortion a linear zoom is performed.  It can be used as-is, or fed into another
 effect to generate borders and/or generate shadows or blend with another background.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Magnify.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Magnifying glass", "DVE", "Distortion", "Similar in operation to a bulge effect but performs a flat linear zoom", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (lens, "Shape", kNoGroup, 0, "Round or elliptical lens|Rectangular lens");

DeclareFloatParam (zoom, "zoom", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Dimension, "Dimensions","Glass size", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (AspectRatio, "Aspect Ratio","Glass size", kNoFlags, 1.0, 0.1, 10.0);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_InputWidthNormalised);
DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 MirrorEdge (sampler S, float2 uv)
{
   float2 xy = 1.0.xx - abs (2.0 * (frac (uv / 2.0) - 0.5.xx));

   return tex2D (S, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (MagnifyingGlass)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - uv1; 									// XY Distance between the current position to the adjusted effect centering

   float dimensions = Dimension * _InputWidthNormalised;                                                       // Corrects Dimension scale - jwrl
   float distance = length (float2 (xydist.x / AspectRatio, (xydist.y / _OutputAspectRatio) * AspectRatio));   // Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.

   distance /= _InputWidthNormalised;                                                                          // Corrects distance scale - jwrl

   float4 retval = ((distance > dimensions) && (lens == 0)) ||                                                 // Background, round lens
                     (((abs(xydist.x) / AspectRatio > dimensions) ||                                             // Background, rectangular lens
                     (abs(xydist.y) * AspectRatio > dimensions)) &&
                     (lens == 1))
                 ? float4 (MirrorEdge (Input, uv1).rgb, 0.0)
                 : MirrorEdge (Input, zoom * xydist + uv1);										// Zoom  (lens)

   return lerp (ReadPixel (Input, uv1), retval, tex2D (Mask, uv1).x);
}

