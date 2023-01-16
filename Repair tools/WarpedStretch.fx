// @Maintainer jwrl
// @Released 2023-01-10
// @Author khaver
// @Created 2013-12-04

/**
 This effect applies distortion to a region of the frame, and is intended for use as a means
 of helping handle mixed aspect ratio media.  It was designed to do the 4:3 to 16:9 warped
 stretch we all hate having to do.  You can set the range of the inner area that is not warped
 and set the outer limits at the edges of the crop.

 It defaults to a 4:3 image in a 16:9 frame, but since a "Strength" slider is provided it can
 be used for other purposes as well.  Note that because of its intended purpose of correcting
 aspect ratios it destroys resolution independence.  What leaves the effect is the size and
 aspect ratio of the sequence that it's used in.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WarpedStretch.fx
//
// Version history:
//
// Updated 2023-01-10 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Warped Stretch", "Stylize", "Repair tools", "This effect is intended for use as a means of helping handle mixed aspect ratio media", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Grid, "Show grid", kNoGroup, true);
DeclareBoolParam (Stretch, "Stretch", kNoGroup, false);

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (ILX, "Inner Left", kNoGroup, "SpecifiesPointX", 0.42, 0.0, 1.0);
DeclareFloatParam (ILY, "Inner Left", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (IRX, "Inner Right", kNoGroup, "SpecifiesPointX", 0.58, 0.0, 1.0);
DeclareFloatParam (IRY, "Inner Right", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (OLX, "Outer Left", kNoGroup, "SpecifiesPointX", 0.125, 0.0, 1.0);
DeclareFloatParam (OLY, "Outer Left", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (ORX, "Outer Right", kNoGroup, "SpecifiesPointX", 0.875, 0.0, 1.0);
DeclareFloatParam (ORY, "Outer Right", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK float2(0.0, 1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (WarpedStretch)
{
   float4 color;

   if (!Stretch) color = ReadPixel (Input, uv1);
   else {
      float delt, fact, stretchr = 1.0 - IRX;
      float sourcel = ILX - OLX;
      float sourcer = (ORX - IRX) / stretchr;

      float2 xy = uv1;
      float2 norm = uv1;
      float2 outp = uv1;

      if (uv1.x >= IRX) {
         norm.x =  IRX + ((uv1.x - IRX) * sourcer);
         delt = (uv1.x - IRX) / stretchr;
         fact = cos (radians (delt * 90.0));
         xy.x = ORX - ((1.0 - uv1.x) * fact * sourcer);
      }

      if (uv1.x <= ILX) {
         norm.x = xy.x = ILX - ((ILX - uv1.x) * sourcel / ILX);
         delt = (ILX - uv1.x) / ILX;
         fact = cos (radians (delt * 90.0));
         xy.x = OLX + (uv1.x * fact * sourcel / ILX);
      }
   
      outp.x = lerp (norm.x, xy.x, Strength);

      color = IsOutOfBounds (outp) ? BLACK : ReadPixel (Input, outp);
   }

   if (Grid
   && ((uv1.x >= ILX - 0.0008 && uv1.x <= ILX + 0.0008)
   ||  (uv1.x >= IRX - 0.0008 && uv1.x <= IRX + 0.0008)
   ||  (uv1.x >= OLX - 0.0008 && uv1.x <= OLX + 0.0008)
   ||  (uv1.x >= ORX - 0.0008 && uv1.x <= ORX + 0.0008))) color = float4 (1.0, 0.0, 0.0, color.a);

   return color;
}

