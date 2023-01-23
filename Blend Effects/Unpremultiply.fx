// @Maintainer jwrl
// @Released 2023-01-23
// @Author baopao
// @Created 2015-11-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Unpremultiply_640.png

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
// Update 2023-01-23 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
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

