// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is really the classic barn door effect, but since a wipe with that name already exists
 in Lightworks another name had to be found.  The Lightworks wipe is just that, a wipe.  It
 doesn't move the separated image parts apart.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BarnDoorSplit_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Barn door split", "Mix", "Wipe transitions", "Splits the image in half and separates the halves horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Horizontal open|Horizontal close|Vertical open|Vertical close");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Open horizontal

DeclarePass (Overlay_0)
{ return ReadPixel (Fg, uv1); }

DeclareEntryPoint (Open_horizontal)
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv3.x - posAmt + 0.5, uv3.y);
   float2 xy2 = float2 (uv3.x - negAmt + 0.5, uv3.y);

   return (uv3.x > posAmt) ? tex2D (Overlay_0, xy1) : (uv3.x < negAmt)
                           ? tex2D (Overlay_0, xy2) : ReadPixel (Bg, uv2);
}


// technique Shut horizontal

DeclarePass (Overlay_1)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Shut_horizontal)
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv3.x - posAmt + 0.5, uv3.y);
   float2 xy2 = float2 (uv3.x - negAmt + 0.5, uv3.y);

   return (uv3.x > posAmt) ? tex2D (Overlay_1, xy1) : (uv3.x < negAmt)
                           ? tex2D (Overlay_1, xy2) : ReadPixel (Fg, uv1);
}


// technique Open vertical

DeclarePass (Overlay_2)
{ return ReadPixel (Fg, uv1); }

DeclareEntryPoint (Open_vertical)
{
   float negAmt = (1.0 - Amount) / 2.0;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv3.x, uv3.y - posAmt + 0.5);
   float2 xy2 = float2 (uv3.x, uv3.y - negAmt + 0.5);

   return (uv3.y > posAmt) ? tex2D (Overlay_2, xy1) : (uv3.y < negAmt)
                           ? tex2D (Overlay_2, xy2) : ReadPixel (Bg, uv2);
}


// technique Shut vertical

DeclarePass (Overlay_3)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Shut_vertical)
{
   float negAmt = Amount / 2.0;
   float posAmt = (2.0 - Amount) / 2.0;

   float2 xy1 = float2 (uv3.x, uv3.y - posAmt + 0.5);
   float2 xy2 = float2 (uv3.x, uv3.y - negAmt + 0.5);

   return (uv3.y > posAmt) ? tex2D (Overlay_3, xy1) : (uv3.y < negAmt)
                           ? tex2D (Overlay_3, xy2) : ReadPixel (Fg, uv1);
}

