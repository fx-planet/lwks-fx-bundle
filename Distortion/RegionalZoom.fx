// @Maintainer jwrl
// @Released 2023-01-24
// @Author schrauber
// @Created 2016-03-14

/**
 Regional zoom is designed to allow you to apply localised (focussed) distortion to a
 region of the frame.  Either zoom in or zoom out can be applied, the area covered can
 be varied, and the amount of distortion can be adjusted.  The edges of the image after
 distortion can optionally be mirrored out to fill the frame.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RegionalZoom.fx
//
// Version history.
//
// Updated 2023-01-24 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Regional zoom", "DVE", "Distortion", "This is designed to allow you to apply localised distortion to any region of the frame", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Zoom, "zoom", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Area, "Area", kNoGroup, kNoFlags, 0.95, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (Mode, "Flip edge", kNoGroup, 1, "No|Yes");

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define AREA  (200.0 - Area * 201.0)

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

DeclareEntryPoint (RegionalZoom)
{
   float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - uv1; 			 // XY Distance between the current position to the adjusted effect centering

   float distance = length (float2 (xydist.x, xydist.y / _OutputAspectRatio));   // Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
   float distortion = (distance * ((distance * AREA) + 1.0) + 1);		 // Creates the distortion.  AREA is a macro that limits the range of the Area setting.
   float zoom = Zoom;

   if (Area != 1) zoom = zoom / max (distortion, 0.1);	 			 // If the area = 1, then normal zoom works. Otherwise, a local zoom is active.   "0.1" prevents a division by zero

   float2 xy = uv1 + (zoom * xydist);						 // Get the distorted address.  It's the same whether mirrored or bordered.

   float4 ret = Mode ? MirrorEdge (Input, xy) : ReadPixel (Input, xy);		 // ReadPixel() blanks anything outside legal addresses, which adds a border to the distorted but mirrored video

   return lerp (ReadPixel (Input, uv1), ret, tex2D (Mask, uv1).x);		 // Return the masked regional zoom over the input video.
}

