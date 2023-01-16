// @Maintainer jwrl
// @Released 2023-01-08
// @Author schrauber
// @Created 2017-11-06

/**
 Visualise what happens when water empties out of a sink, and you have what this effect
 does.  Possibly you could regard it as adding the sort of sink error you want to your
 video!

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/ 

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Whirl.fx
//
// Version history:
//
// Updated 2023-01-08 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Whirl", "DVE", "Distortion", "Simulates what happens when water empties out of a sink", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (WhirlCenter, "Whirl", kNoGroup, kNoFlags, 0.0, -62.0, 62.0);
DeclareFloatParam (WhirlOutside, "Whirl, outside", kNoGroup, kNoFlags, 0.0, -62.0, 62.0);
DeclareFloatParam (Spin, "Revolutions", kNoGroup, kNoFlags, 0.0, -62.0, 62.0);
DeclareFloatParam (Zoom, "Zoom", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (XzoomPos, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (YzoomPos, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

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

DeclareEntryPoint (Whirl)
{ 
   // ----Shader definitions and declarations ----

   float Tsin, Tcos;    // Sine and cosine of the set angle.
   float angle;
   float distance;      //Distance from the center of rotation

   // Position vectors

   float2 centreEffect = float2 (XzoomPos, 1.0 - YzoomPos);
   float2 posZoom, posSpin;

   // Direction vectors

   float2 vCzT;              // Vector between Center(zoom) and Texel
   float2 vCrT;              // Vector between Center(rotation) and Texel

   // ------ ROTATION --------

   vCrT = uv1 - centreEffect;
   distance = length (float2 (vCrT.x, vCrT.y / _OutputAspectRatio));

   angle = radians ((Spin * 360.0) + (WhirlOutside * 360.0 * distance) - (WhirlCenter * 360.0 * (1.0 - distance)));

   vCrT = float2(vCrT.x * _OutputAspectRatio, vCrT.y );

   sincos (angle, Tsin , Tcos);

   posSpin = float2 ((vCrT.x * Tcos - vCrT.y * Tsin), (vCrT.x * Tsin + vCrT.y * Tcos));
   posSpin = float2 (posSpin.x / _OutputAspectRatio, posSpin.y) + centreEffect;

   // ------ ZOOM -------

   vCzT = centreEffect - posSpin;
   posZoom = ((1.0 - (exp2 (Zoom * -10.0))) * vCzT) + posSpin;            // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * 10 -1)))   to get the setting characteristic described in the header.

   // ------ OUTPUT-------

   return MirrorEdge (Input, posZoom);

}

