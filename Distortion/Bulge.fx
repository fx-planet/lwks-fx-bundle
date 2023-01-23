// @Maintainer jwrl
// @Released 2023-01-24
// @Author schrauber
// @Created 2016-03-16

/**
 Bulge 2018 allows a variable area of the frame to have a concave or convex bulge applied.
 Optionally the background can have a radial distortion applied at the same time, or can
 be made black or transparent black.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bulge.fx
//
// Information for Effect Developer:
// 8 January 2023 by LW user jwrl: My apologies for the code reformatting, schrauber.  I
// have always had trouble reading other people's code.  The problem is mine, not yours.
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-01-24 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bulge", "DVE", "Distortion", "This effect allows a variable area of the frame to have a concave or convex bulge applied", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Zoom, "Zoom", kNoGroup, kNoFlags, 1.0, -3.0, 3.0);

DeclareFloatParam (Bulge_size, "Size","Bulge", kNoFlags, 0.25, 0.0, 0.5);
DeclareFloatParam (AspectRatio, "Aspect Ratio","Bulge", kNoFlags, 1.0, 0.1, 10.0);
DeclareFloatParam (Angle, "Angle","Bulge", kNoFlags, 0.0, -3600.0, 3600);

DeclareIntParam (Rotation, "Rotation mode", kNoGroup, 2, "Shape (Aspect ratio should not be 1)|Only the bulge content|Bulge|Input texture");
DeclareIntParam (Mode, "Environment of bulge", kNoGroup, 0, "Original| Distorted| Black alpha 0| Black alpha 1");

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

DeclareEntryPoint (Bulge)
{
   float Tsin, Tcos;     // Sine and cosine of the set angle.

   float2 centre = float2 (Xcentre, 1.0 - Ycentre);
   float2 vcenter = uv1 - centre;    // Vector between Center and Texel

   // ------ Rotation of bulge dimensions. --------

   float angle = radians (-Angle);

   vcenter = float2 (vcenter.x * _OutputAspectRatio, vcenter.y);

   sincos (angle, Tsin , Tcos);

   // Correction Vector for recalculation of objects Dimensions.

   float2 Spin = float2 ((vcenter.x * Tcos - vcenter.y * Tsin), (vcenter.x * Tsin + vcenter.y * Tcos));

   Spin = float2 (Spin.x / _OutputAspectRatio, Spin.y );

   // SpinPixel is the rotated Texel position.

   float2 SpinPixel = Spin + centre;

   // ------ Bulge --------

   vcenter = centre - uv1;

   if (Rotation == 1) Spin = vcenter;

   // Get corrected object radius.

   float corRadius = length (float2 (Spin.x / AspectRatio, (Spin.y / _OutputAspectRatio) * AspectRatio));
   float bulgeSize = Bulge_size * _InputWidthNormalised;    // Corrects Bulge_size scale - jwrl

   corRadius /= _InputWidthNormalised;    // Corrects corRadius scale - jwrl

   bool bulge = corRadius < bulgeSize;    // Saves on recalculation - jwrl

   if ((Mode == 3) && !bulge) return float4 (0.0.xxx, 1.0);
   if ((Mode == 2) && !bulge) return kTransparentBlack;

   float distortion = ((Mode == 1) || bulge) ? Zoom * sqrt (sin (abs(bulgeSize - corRadius))) : 0.0;

   float2 xy = ((Rotation == 3) || ((Rotation == 2) && bulge) || ((Rotation == 1) && bulge))
             ? SpinPixel : uv1;

   // New code to recover the bulged video and mask it into the original image.

   float4 retval = MirrorEdge (Input, (distortion * (centre - xy)) + xy);
   float4 source = ReadPixel (Input, uv1);

   return lerp (source, retval, tex2D (Mask, uv1).x);
}

