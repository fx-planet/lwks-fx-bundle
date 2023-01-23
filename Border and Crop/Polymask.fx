// @Maintainer jwrl
// @Released 2023-01-22
// @Author jwrl
// @Released 2023-01-22

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
// Built 2023-01-22 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Polymask", "DVE", "Border and Crop", "Multi-sided adjustable mask", "ScaleAware|HasMinOutputSize");

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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint ()
{
   float4 Bgd = Mode == 0 ? ReadPixel (Bg, uv2) : BgColour;

   return lerp (Bgd, ReadPixel (Fg, uv1), tex2D (Mask, uv1).x);
}

