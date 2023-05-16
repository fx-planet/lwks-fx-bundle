// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2011-06-27

/**
 Originally called perspective, the current name of the effect better describes what
 it does.  It also avoids a conflict with another effect of the same name.  It's a
 neat, simple effect for skewing the image to add a perspective illusion to a flat
 plane.  With resolution independence, the image will only wrap to the boundaries
 of the undistorted image.  If the aspect ratio of the input video is such that it
 doesn't fill the frame, neither will the warped image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Skew.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-05-08 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Skew", "DVE", "Distortion", "A neat, simple effect for adding a perspective illusion to a flat plane", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters 
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (showGrid, "Show grid", kNoGroup, false);

DeclareFloatParam (TLX, "Top Left", kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (TLY, "Top Left", kNoGroup, "SpecifiesPointY", 0.9, 0.0, 1.0);

DeclareFloatParam (TRX, "Top Right", kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (TRY, "Top Right", kNoGroup, "SpecifiesPointY", 0.9, 0.0, 1.0);

DeclareFloatParam (BLX, "Bottom Left", kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (BLY, "Bottom Left", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (BRX, "Bottom Right", kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (BRY, "Bottom Right", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (ORGX, "Pan", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (ORGY, "Pan", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Zoom, "Zoom", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define WHITE 1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

DeclarePass (Input)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Perspective)
{
   float x1 = lerp (0.1 - TLX, 1.9 - TRX, uv2.x);
   float x2 = lerp (0.1 - BLX, 1.9 - BRX, uv2.x);
   float y1 = lerp (TLY - 0.9, BLY + 0.9, uv2.y);
   float y2 = lerp (TRY - 0.9, BRY + 0.9, uv2.y);

   float2 xy;

   xy.x = lerp (x1, x2, uv2.y) + (0.5 - ORGX);
   xy.y = lerp (y1, y2, uv2.x) + (ORGY - 0.5);

   float2 zoomit = ((xy - 0.5.xx) / Zoom) + 0.5.xx;

   float4 color = ReadPixel (Input, zoomit);

   if (showGrid) {
      xy = frac (uv2 * 10.0);

      if (any (xy <= 0.02) || any (xy >= 0.98))
         color = WHITE - color;
   }

   return lerp (kTransparentBlack, color, tex2D (Mask, uv2).x);
}

