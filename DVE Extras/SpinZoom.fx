// @Maintainer jwrl
// @Released 2023-01-09
// @Author schrauber
// @Created 2017-10-22

/**
 This has some of the same functions as the 3D DVE, but the settings menu does not look
 as interesting as that effect.  It is actually more interesting.  It gives you a simple
 functionality, and adds the ability to mirror or duplicate the image as you zoom out.
 If you only need rotation and zoom, then you only need this effect.  The rotation axis
 is automatically adjusted in the same way as the 3D DVE does.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SpinZoom.fx
//
// ... More details:
// Setting characteristics of the zoom slider
//         The dimensions will be doubled or halved in setting steps of 10%:
//         -40% Dimensions / 16
//         -30% Dimensions / 8
//         -20% Dimensions / 4
//         -10% Half dimensions
//           0% No change
//          10% Double dimensions
//          20% Dimensions * 4
//          30% Dimensions * 8
//          40% Dimensions * 16
//
//        Center of rotation:
//        Zoom >= 0: rotation center = center of the output texture
//        Zoom <  0: rotation center = center of the input textur
//        For this purpose, the program sections ZOOM and ROTATION are run through in
//        different order.
//        Zoom >= 0: first ZOOM, then ROTATION
//        Zoom <  0: first ROTATION, then ZOOM
//
// Information for Effect Developer:
// 16 May 2018 by LW user schrauber: Subcategory defined, and data relevant to the homepage.
// The rotation code is based on the spin-dissolve effects of the user "jwrl".
// The zoom code is based on the zoom out, zoom in effect of the user "schrauber".
//
// 19 June 2022 by user jwrl: The wrap and mirror addressing is now taken care of inside the
// shader, allowing the use of a single entry point and the condensed input declaration code
// block used by 2022.2 effects and higher.  Some code optimisation has also been performed.
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Built 2023-01-09 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Spin Zoom", "DVE", "DVE Extras", "Has some of the same functions as the 3D DVE, but the settings are much easier to use", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Spin, "Revolutions", "Rotation", kNoFlags, 0.0, -62.0, 62.0);
DeclareFloatParam (Angle, "Angle", "Rotation", kNoFlags, 0.0, -360.0, 360.0);
DeclareFloatParam (AngleFine, "Angle Fine", "Rotation", kNoFlags, 0.0, -12.0, 12.0);

DeclareFloatParam (Zoom, "Strength", "Zoom", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (ZoomFine, "Fine", "Zoom", kNoFlags, 0.0, -5.0, 5.0);

DeclareFloatParam (XzoomPos, "Zoom centre", "Zoom", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (YzoomPos, "Zoom centre", "Zoom", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (EdgeMode, "Edge mode", kNoGroup, 0, "Bordered/transparent|Reflected image|Tiled image");

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define ZOOM (Zoom * 10 + ZoomFine / 10)
#define FRAMECENTER 0.5

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (SpinZoom)
{ 
   // ----Shader definitions and declarations ----

   float Tsin, Tcos;                                        // Sine and cosine of the set angle.
   float angle;

   // Position vectors

   float2 centreZoom = float2 (XzoomPos, 1.0 - YzoomPos);   // Zoom center
   float2 centreSpin = FRAMECENTER;                         // Position of the rotation axis
   float2 posZoom, posSpin, posFlip, posOut;

   // Direction vectors

   float2 vCrT;                                             // Vector between Center(rotation) and Texel
   float2 vCzT = centreZoom - uv1;                          // Vector between Center(zoom) and Texel

   posZoom = ((1.0 - (exp2 (-ZOOM))) * vCzT) + uv1;         // The set value Zoom has been replaced by the formula (1 - (exp2( Zoom * -1))) to get the setting characteristic described in the header.

   // ------ ROTATION --------

   angle = -radians (Spin * 360 + Angle + AngleFine);

   sincos (angle, Tsin , Tcos);

   if (ZOOM < 0.0) {
      // ------ negative ZOOM ------- Used only for negative zoom settings.

      vCrT = posZoom - centreSpin;
      vCrT.x *= _OutputAspectRatio;

      posSpin = float2 ((vCrT.x * Tcos - vCrT.y * Tsin), (vCrT.x * Tsin + vCrT.y * Tcos)); 
      posOut  = float2 (posSpin.x / _OutputAspectRatio, posSpin.y) + centreSpin;
   }
   else {
      // ------ positive ZOOM ------- Used only for positive zoom settings.

      vCrT = uv1 - centreSpin;
      vCrT.x *= _OutputAspectRatio;

      posSpin = float2 ((vCrT.x * Tcos - vCrT.y * Tsin), (vCrT.x * Tsin + vCrT.y * Tcos)); 
      posSpin = float2 (posSpin.x / _OutputAspectRatio, posSpin.y) + centreSpin;

      vCzT = centreZoom - posSpin;
      posOut = ((1.0 - (exp2 (-ZOOM))) * vCzT) + posSpin;
   }

   // This next code implements the mirror and wrap addressing.  Those functions are
   // now taken over by the shader code rather than by using native GPU addressing.

   if (EdgeMode == 2) { posOut = frac (posOut); }           // posOut is now wrapped to duplicate the image.
   else if (EdgeMode == 1) {                                // posOut is now mirrored to duplicate the image.
      posOut = 1.0.xx - abs (2.0 * (frac (posOut / 2.0) - 0.5.xx));
   }

   return ReadPixel (Input, posOut);
}

