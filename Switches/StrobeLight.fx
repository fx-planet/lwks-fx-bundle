// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2018-03-31

/**
 Development of this effect was triggered by khaver's "Strobe light" effect, but
 uses newer Lightworks functions to set the strobe rate accurately in frames, not
 as a percentage of progress.  This means that the flash timing will be accurate
 regardless of the actual length of the clips to which it is applied.  The effect
 also handles foreground and background components at their native resolutions.

 Because this version is designed specifically for Lightworks versions 2023 plus
 it does not support earlier versions at all.  The earlier StrobeLight.fx by khaver
 and StrobeLightNew.fx by jwrl will do that if you need to work with those earlier
 Lightworks versions.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-------------------------------------------------------------------------------------//
// Lightworks user effect StrobeLight.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Strobe light", "User", "Switches", "The strobe effect for LW 2022.2 and later", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-------------------------------------------------------------------------------------//
// Parameters
//-------------------------------------------------------------------------------------//

DeclareIntParam (SetBgd, "Vision seen when flash is off", kNoGroup, 0, "Background|Black");

DeclareFloatParam (Rate, "Flash frame rate", kNoGroup, kNoFlags, 1.0, 1.0, 60.0);

DeclareBoolParam (SwapStart, "Swap start frame", kNoGroup, false);

DeclareFloatParam (_Progress);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK float2(0.0, 1.0).xxxy

//-------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (StrobeLight)
{
   float frame = floor ((_LengthFrames * _Progress) + 0.5);

   bool flash = frac (floor (frame / max (round (Rate), 1.0)) * 0.5) ? SwapStart : !SwapStart;

   return flash ? ReadPixel (Fg, uv1) : SetBgd ? BLACK : ReadPixel (Bg, uv2);
}

