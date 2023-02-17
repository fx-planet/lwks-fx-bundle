// @Maintainer jwrl
// @Released 2023-02_17
// @Author jwrl
// @Created 2023-02-14

/**
 This is a Lightworks 2023 replacement for all of khaver's original Polymask effects,
 which have now been withdrawn.  As with the original effect(s), inside the mask bounds
 is the Fg video, the outside is either the selected colour or Bg video (transparent
 black if no Bg is connected).  It also replaces several other mask effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Polymask.fx
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Added the ability to fade the background.
//
// Updated 2023-02-14 jwrl.
// Corrected descriptive comment at head of code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Polymask", "DVE", "Border and Crop", "Multi-sided adjustable mask", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Mode, "Mask background", kNoGroup, 1, "Bg input|Colour");

DeclareColourParam (BgColour, "Bg colour", kNoGroup, kNoFlags, 0.0, 0.5, 0.0, 1.0);

DeclareFloatParam (FadeBg, "Fade background", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (PolyMask)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = Mode == 0 ? ReadPixel (Bg, uv2) : BgColour;

   Bgnd = lerp (Fgnd, Bgnd, FadeBg);

   // We derive the mask from sequence coordinates, not from foreground nor background.

   return lerp (Bgnd, Fgnd, tex2D (Mask, uv3).x);
}

