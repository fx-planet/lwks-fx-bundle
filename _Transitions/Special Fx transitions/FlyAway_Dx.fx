// @Maintainer jwrl
// @Released 2023-01-29
// @Author schrauber
// @Released 2016-08-03

/**
 This cute transition effect "flies" the image off to reveal the new image.  The
 process is divided into 2 phases in order to always ensure a clean transition at
 different effect positions.  The first phase transforms the outgoing image into the
 centre of the frame as a butterfly shape.  In this part of the transition the
 position is fixed. The second part is the actual flight phase.  Adjustment of the
 final destination is possible, but the default is a destination outside of the screen.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlyAway_Dx.fx
//
// Version history:
//
// Updated 2023-01-29 jwrl
// Updated to provide LW 2022 revised cross platform support.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Fly away B", "Mix", "Special Fx transitions", "Flies the outgoing image out to reveal the incoming", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Xcentre, "Destination", "Only influences the flight phase", "SpecifiesPointX", 1.1, -0.2, 1.5);
DeclareFloatParam (Ycentre, "Destination", "Only influences the flight phase", "SpecifiesPointY", 0.9, -0.2, 1.5);

DeclareFloatParamAnimated (reduction, "Reduction", "Settings for the first clip", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (layout, "Layout", "Settings for the first clip", kNoFlags, 1.2, 0.8, 1.5);

DeclareFloatParamAnimated (borderX, "Border X", "Settings for the first clip", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParamAnimated (borderY, "Border Y", "Settings for the first clip", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (frequency, "Frequency", "Fluttering, only influences the flight phase", kNoFlags, 50.0, 0.0, 100.0);
DeclareFloatParam (amplitude, "Amplitude", "Fluttering, only influences the flight phase", kNoFlags, 0.03, 0.0, 0.1);
DeclareFloatParam (fluttering_zoom, "cyclical zoom", "Fluttering, only influences the flight phase", kNoFlags, 8.0, 0.0, 20.0);
DeclareFloatParam (fluttering_y, "cyclical Y", "Fluttering, only influences the flight phase", kNoFlags, 8.0, 0.0, 20.0);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Fly_Away_Dx)
{
   // ... Definitions, declarations, adaptation and defaults ...

   float2 border = abs (float2 (borderX, borderY));         // Border to the flying first clip
   float2 XYc;                                              // automatically adjusted Effect Centering
   float2 XYcDiv;                                           // XY Distance: Frame Center to the adjusted Effect Center
   float2 DivCuv3 = float2 (Xcentre, 1.0 - Ycentre) - 0.5;  // XY Distance: Frame Center to the manual Effekt Center setting, with adaptation of Y direction
   float2 uv3dist;                                          // XY Distance between the current position to the adjusted effect centering, but excluding layout changes in the next step.
   float2 uv3distance;                                      // XY Distance between the current position to the adjusted effect centering
   float2 uv3distortion;                                    // Source pixel position

   float zoom = reduction * (-0.8);                         // Parameter acquisition and adaptation
   float _distance;                                         // Hypotenuse of uv3distance, the shortest distance between the current position to the center of the distortion.
   float cycle = 0;                                         // Wave for generation of flutter / wing beat. Default is 0 to disable when Progress <= 0.5
   float distortion;                                        // Intensity of the deformation and the cyclical zoom during the wing beat.

   // ... Wave for generation of flutter / wing beat. (disabled when Progress <= 0.5) ...

   if (_Progress > 0.5) cycle = sin (_Progress * frequency) * amplitude;   // wave

   // ... Distances from the effect center ...

   XYc = 0.5;                                               // This default is used only when Progress <= 0.5

   // Activate effect centering settings when Progress> 0.5 ; and adaptation 

   if (_Progress > 0.5) XYc = 0.5 + DivCuv3 * (2.0 * (_Progress - 0.5));

   uv3dist = XYc - uv3;                                           // XY Distance between the current position to the adjusted effect centering	
   uv3distance = float2 (uv3dist.x * layout, uv3dist.y / layout); // Similar uv3dist + Layout
   _distance = distance (0.0.xx, uv3distance);                    // Hypotenuse of uv3distance, the shortest distance between the current position to the center of the distortion.

   // ... Deformation , Intensity of the deformation and fluttering- zoom ....

   distortion = (zoom / _distance) + cycle * fluttering_zoom;

  // ... uv3-Distance of the frame-center to the adjusted effect centering ...

  XYcDiv = 0.5 - XYc;

   // ... Pixel position of the source whose signal is to be distorted ...

   uv3distortion = distortion * uv3dist + uv3;                                // uv3distortion Step 1: Source pixel position, without subsequent adjustments
   uv3distortion = uv3distortion + XYcDiv;                                    // uv3distortion Step 2: Calibrated to the center of the source frame.
   uv3distortion = uv3distortion + cycle + float2 (0 , cycle * fluttering_y); // uv3distortion Step 3: Source pixel position (including flutter and and including the adjustment in step 1 & 2).

   // ........ Output ........

   // Use the input Fg, if the position of the distorted Fg-pixel inside of the frame and outside the borders:

   if ((uv3distortion.x >= 0+border.x) && (uv3distortion.x <= 1-border.x) && (uv3distortion.y >= 0+border.y) && (uv3distortion.y <= 1-border.y)) return tex2D (Fgd, uv3distortion);

  // Use the input Bg, if the position of the Fg-pixel outside the Frame:

  if ((uv3distortion.x < 0) || (uv3distortion.x > 1) || (uv3distortion.y < 0) || (uv3distortion.y > 1)) return tex2D (Bgd, uv3);

   // Use the input Bg, when the manual frame settings are negative and the Sorce-position of the pixel inside the border-position:

   if ((borderX < 0) && ((uv3distortion.x < border.x) || (uv3distortion.x > (1-border.x)))) return tex2D (Bgd, uv3);
   if ((borderY < 0) && ((uv3distortion.y < border.y) || (uv3distortion.y > (1-border.y)))) return tex2D (Bgd, uv3);

   // Black border:

   return kTransparentBlack;
}

