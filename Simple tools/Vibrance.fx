// @Maintainer jwrl
// @Released 2023-01-25
// @Author jwrl
// @Created 2023-01-25

/**
 This simple effect just adjusts the colour vibrance.  It does this by selectively  altering
 the saturation levels of the mid tones in the video.  You can probably think of it as a sort
 of gamma adjustment that only works on saturation.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Vibrance.fx
//
// Version history:
//
// Built 2023-01-25 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Vibrance", "Colour", "Simple tools", "Makes your video POP!!!", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Vibrance, "Vibrance", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Vid)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Vibrance_2023)
{
   if (IsOutOfBounds (uv2)) return kTransparentBlack;

   float4 source = tex2D (Vid, uv2);

   float amount = pow (1.0 + Vibrance, 2.0) - 1.0;
   float maxval = max (source.r, max (source.g, source.b));
   float vibval = amount * (((source.r + source.g + source.b) / 3.0) - maxval);

   float4 retval = float4 (saturate (lerp (source.rgb, maxval.xxx, vibval)), source.a);

   return lerp (source, retval, tex2D (Mask, uv2).x);
}

