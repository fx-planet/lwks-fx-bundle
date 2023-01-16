// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is a four-way split which moves the image to or from the corners of the frame.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSplit_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Corner split", "Mix", "Wipe transitions", "Splits an image four ways to or from the corners of the frame", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Corner open|Corner close");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Open

DeclarePass (Overlay_0)
{ return ReadPixel (Fg, uv1); }

DeclareEntryPoint (Open)
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv3.x - posAmt + 0.5, uv3.y - posAmt + 0.5);
   float2 xy2 = float2 (uv3.x - negAmt + 0.5, xy1.y);
   float2 xy3 = float2 (xy1.x, uv3.y - negAmt + 0.5);
   float2 xy4 = float2 (xy2.x, xy3.y);

   return (uv3.x > posAmt) && (uv3.y > posAmt) ? tex2D (Overlay_0, xy1) :
          (uv3.x < negAmt) && (uv3.y > posAmt) ? tex2D (Overlay_0, xy2) :
          (uv3.x > posAmt) && (uv3.y < negAmt) ? tex2D (Overlay_0, xy3) :
          (uv3.x < negAmt) && (uv3.y < negAmt) ? tex2D (Overlay_0, xy4) :
                                                 ReadPixel (Bg, uv2);
}


// technique Shut

DeclarePass (Overlay_1)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Shut)
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv3.x - posAmt + 0.5, uv3.y - posAmt + 0.5);
   float2 xy2 = float2 (uv3.x - negAmt + 0.5, xy1.y);
   float2 xy3 = float2 (xy1.x, uv3.y - negAmt + 0.5);
   float2 xy4 = float2 (xy2.x, xy3.y);

   return (uv3.x > posAmt) && (uv3.y > posAmt) ? tex2D (Overlay_1, xy1) :
          (uv3.x < negAmt) && (uv3.y > posAmt) ? tex2D (Overlay_1, xy2) :
          (uv3.x > posAmt) && (uv3.y < negAmt) ? tex2D (Overlay_1, xy3) :
          (uv3.x < negAmt) && (uv3.y < negAmt) ? tex2D (Overlay_1, xy4) :
                                                 ReadPixel (Fg, uv1);
}

