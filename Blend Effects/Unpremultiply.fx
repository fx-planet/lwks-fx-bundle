// @Maintainer jwrl
// @Released 2023-05_15
// @Author baopao
// @Created 2015-11-30

/**
 Unpremultiply does just that.  It removes the hard outline you can get with premultiplied
 mattes.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Unpremultiply.fx
//
// Version history:
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Unpremultiply", "Mix", "Blend Effects", "Removes the hard outline you can get with some blend effects", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Unpremultiply)
{
   float4 color = lerp (kTransparentBlack, ReadPixel (Inp, uv1), tex2D (Mask, uv1).x);

   return float4 (color.rgb /= color.a, color.a);
}
