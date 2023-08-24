// @Maintainer jwrl
// @Released 2023-08-24
// @Author jwrl
// @Created 2019-05-12

/**
 This simple effect turns the alpha channel of a clip fully on, making it opaque.  There
 are two modes available - the first simply turns the alpha on, the second adds a flat
 opaque background colour where previously the clip was transparent.  The default colour
 used is black, and the image can be unpremultiplied in this mode if desired.

 A means of boosting alpha before processing to support clips such as Lightworks titles
 and image keys in versions earlier than 2023.2 has also been included.  This only
 functions when the background is being replaced.

 NOTE:  This effect is only suitable for use with Lightworks version 2023.1 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AlphaOpq.fx
//
// Version history:
//
// Updated 2023-08-24 jwrl.
// Explicitly declare transparent black if masked when OpacityMode is set to 0.
// Explicitly recovered the mask as a float and not a float4 (vec4) to resolve a
// Linux/Mac lerp/mix issue.
//
// Updated 2023-08-02 jwrl.
// Reworded alpha channel selection for 2023.2 settings.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-26 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Alpha opaque", "Key", "Key Extras", "Makes a transparent image or title completely opaque", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (OpacityMode, "Opacity mode", kNoGroup, 0, "Make opaque|Blend with colour");
DeclareIntParam (KeyMode, "Type of alpha channel", kNoGroup, 0, "Standard|Premultiplied|Image key/Title pre 2023.2");

DeclareColourParam (Colour, "Background colour", kNoGroup, kNoFlags, 0.0, 0.0, 0.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (AlphaOpq)
{
   float4 Fgd = ReadPixel (Inp, uv1);

   float maskShape = tex2D (Mask, uv1).x;

   if (OpacityMode == 0) return lerp (0.0.xxxx, float4 (Fgd.rgb, 1.0), maskShape);

   if (KeyMode == 2) Fgd.a = pow (Fgd.a, 0.5);
   if (KeyMode > 0) Fgd.rgb /= Fgd.a;

   Fgd = float4 (lerp (Colour.rgb, Fgd.rgb, Fgd.a), 1.0);

   return lerp (Colour, Fgd, maskShape);
}

