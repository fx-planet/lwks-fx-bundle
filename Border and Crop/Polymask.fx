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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These first 2 passes are done to optionally invert the inputs to the effect and map
// their coordinates to the master sequence coordinates.

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint ()
{
   float4 Bgnd = Mode == 0 ? tex2D (Bgd, uv3) : BgColour;

   return lerp (Bgnd, tex2D (Fgd, uv3), tex2D (Mask, uv3).x);
}

