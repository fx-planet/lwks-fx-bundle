// @Maintainer jwrl
// @Released 2023-05-17
// @Author schrauber
// @Released 2016-08-03

/**
 This cute transition effect "flies" the image off to reveal the new image.  The
 process is divided into 2 phases in order to always ensure a clean transition at
 different effect positions.  The first phase transforms the outgoing image into
 the centre of the frame as a butterfly shape.  In this part of the transition the
 position is fixed. The second part is the actual flight phase.  Adjustment of the
 final destination is possible, but the default is a destination just outside of
 the screen.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlyAwayTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Fly away transition", "Mix", "Special Fx transitions", "Flies the outgoing image out to reveal the incoming", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (reduction, "Progress", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Setup, "Setup shape and border", "Outgoing clip settings", false);

DeclareFloatParam (layout, "Shape", "Outgoing clip settings", kNoFlags, 1.2, 0.8, 1.5);
DeclareFloatParam (borderX, "Border X", "Outgoing clip settings", "DisplayAsPercentage", 0.2, -1.0, 1.0);
DeclareFloatParam (borderY, "Border Y", "Outgoing clip settings", "DisplayAsPercentage", 0.2, -1.0, 1.0);

DeclareColourParam (Colour, "Border colour", "Outgoing clip settings", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Destination", "Flight path", "SpecifiesPointX", 1.1, -0.2, 1.5);
DeclareFloatParam (Ycentre, "Destination", "Flight path", "SpecifiesPointY", 0.9, -0.2, 1.5);

DeclareFloatParam (StartFlight, "Flutter start", "Fluttering", kNoFlags, 0.5, 0.1, 0.9);
DeclareFloatParam (frequency, "Frequency", "Fluttering", kNoFlags, 50.0, 0.0, 100.0);
DeclareFloatParam (amplitude, "Amplitude", "Fluttering", kNoFlags, 0.03, 0.0, 0.1);

DeclareFloatParam (fluttering_zoom, "Cyclical zoom", kNoGroup, kNoFlags, 8.0, 0.0, 20.0);
DeclareFloatParam (fluttering_y, "Cyclical Y", kNoGroup, kNoFlags, 8.0, 0.0, 20.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (FlyAwayTrans)
{
   float amount, progress;                                  // Set up the effect parameters

   if (Setup) {
      amount = 0.5;
      progress = 0.5;
   }
   else {
      float flutterStart = clamp (StartFlight, 0.1, 0.9);

      amount   = (smoothstep (0.0, flutterStart, reduction) + smoothstep (flutterStart, 1.0, reduction)) / 2.0;
      progress = (smoothstep (0.0, flutterStart, _Progress) + smoothstep (flutterStart, 1.0, _Progress)) / 2.0;
   }

   // ... Definitions, declarations, adaptation and defaults ...

   float2 border = abs (float2 (borderX, borderY * _OutputAspectRatio));   // Border of the flying outgoing clip, aspect ratio corrected
   float2 XYc;                                              // Automatically adjusted Effect Centering
   float2 XYcDiv;                                           // XY Distance: Frame Center to the adjusted Effect Center
   float2 DivCuv3 = float2 (Xcentre, 1.0 - Ycentre) - 0.5;  // XY Distance: Frame Center to the manual Effect Center setting, with adaptation of Y direction
   float2 xydist;                                           // XY Distance between the current position to the adjusted effect centering, but excluding layout changes in the next step.
   float2 xydistance;                                       // XY Distance between the current position to the adjusted effect centering
   float2 xydistortion;                                     // Source pixel position

   float zoom = amount * (-0.8);                            // Parameter acquisition and adaptation
   float _distance;                                         // Hypotenuse of xydistance, the shortest distance between the current position to the center of the distortion.
   float cycle = 0;                                         // Wave for generation of flutter / wing beat. Default is 0 to disable when Progress <= 0.5
   float distortion;                                        // Intensity of the deformation and the cyclical zoom during the wing beat.

   // ... Wave for generation of flutter / wing beat. (disabled when progress <= 0.5) ...

   if (progress > 0.5) cycle = sin (progress * frequency) * amplitude;   // wave

   // ... Distances from the effect center ...

   XYc = 0.5;                                               // This default is used only when progress <= 0.5

   // Activate effect centering settings when Progress > 0.5 and adaptation 

   if (progress > 0.5) XYc = 0.5 + DivCuv3 * (2.0 * (progress - 0.5));

   xydist = XYc - uv3;                                            // XY Distance between the current position to the adjusted effect centering	
   xydistance = float2 (xydist.x * layout, xydist.y / layout);    // Similar xydist + Layout
   _distance = distance (0.0.xx, xydistance);                     // Hypotenuse of xydistance, the shortest distance between the current position to the center of the distortion.

   // ... Deformation , Intensity of the deformation and fluttering- zoom ....

   distortion = (zoom / _distance) + (cycle * fluttering_zoom);

  // ... uv3-Distance of the frame-center to the adjusted effect centering ...

  XYcDiv = 0.5 - XYc;

   // ... Pixel position of the source whose signal is to be distorted ...

   xydistortion = (distortion * xydist) + uv3;                                   // xydistortion Step 1: Source pixel position, without subsequent adjustments
   xydistortion = xydistortion + XYcDiv;                                         // xydistortion Step 2: Calibrated to the center of the source frame.
   xydistortion = xydistortion + cycle + float2 (0.0, cycle * fluttering_y);     // xydistortion Step 3: Source pixel position (including flutter and and including the adjustment in step 1 & 2).

   // ........ Output (rewritten by jwrl) ........

   // Use the input Fg (ougoing video) if the position of the distorted Fg pixel is inside the the borders.  If the distorted Fg pixel falls completely outside the legal bounds the background
   // (incoming video) is shown instead.

   // This is a rewrite of the original and has been much cleaned up.  It was initially done so that we could implement the masking that is now standard on Lightworks transitions without the
   // need to implement another pass.  The original had five potential exit paths, and while masking could have been added to each, it would have had to have been individually tailored.  Not
   // only does this rewrite obviate that need, an added benefit is that the conditionals are much simpler than the originals at the cost of some comparatively simple extra maths.

   // The keyframed border ramp has also been removed and a transition from zero width to the preset border width over the first quarter of the transition progress has been implented.  This
   // uses an S curve to smoothly transition from no border to preset border.  Instead of just a black border, colour is now available.

   amount  = saturate (progress * 4.0);
   border *= amount * amount * (3.0 - (2.0 * amount)) / 8.0;
   border += abs (xydistortion - 0.5.xx);

   // Use the incoming video when the border settings are negative and the source pixel coordinates are inside the border or are outside legal coordinates.

   float4 retval;

   if (((borderX < 0.0) && (border.x > 0.5)) || ((borderY < 0.0) && (border.y > 0.5)) || IsOutOfBounds (xydistortion)) { retval = tex2D (Bgd, uv3); }
   else if (any (border > 0.5)) { retval = float4 (Colour.rgb, 1.0); }    // Opaque coloured border
   else retval = tex2D (Fgd, xydistortion);

   return lerp (tex2D (Fgd, uv3), retval, tex2D (Mask, uv3).x);
}

