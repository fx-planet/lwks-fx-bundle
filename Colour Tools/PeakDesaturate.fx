// @Maintainer jwrl
// @Released 2023-05-15
// @Author jwrl
// @Created 2016-04-06

/**
 This is a tool designed to quickly and easily desaturate whites and blacks, which can
 easily become contaminated during other grading operations.  The turnover point and
 blend smoothness of both black and white desaturation are adjustable.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PeakDesaturate.fx
//
// Version history:
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Peak desaturate", "Colour", "Colour Tools", "Quickly and easily desaturate whites and blacks contaminated during other grading operations", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (WhtPnt, "Turnover", "White", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (WhtRng, "Spread", "White", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (WhtDesat, "Desaturate", "White", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (BlkPnt, "Turnover", "Black", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BlkRng, "Spread", "Black", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BlkDesat, "Desaturate", "Black", kNoFlags, 0.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (PeakDesaturate)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 video  = tex2D (Inp, uv2);
   float4 retval = saturate (video);

   // We use all RGB data for raw luminance so that we don't get hard contouring.
   // This may also give some colour noise reduction - possibly.

   float Rlum = retval.g + retval.r + retval.b;
   float Luma = Rlum / 3.0;

   // Get the turnover point for white desaturation and set the level.

   float Wpoint = lerp (1.25, 0.75, WhtPnt);
   float Wlevel = clamp (Rlum * Wpoint, 0.0, 3.0) - 2.0;

   Wlevel *= 2.0 - WhtRng;                                 // Expand the range
   Wlevel  = saturate (Wlevel - WhtRng);                   // Legalise it
   Wlevel *= WhtDesat;                                     // Quit with luma level set

   float Bpoint = lerp (1.5, 0.0, BlkPnt);                 // Turnover point for blacks
   float Blevel = clamp (Rlum * Bpoint, 0.0, 3.0);

   Blevel *= 2.0 - BlkRng;
   Blevel  = 1.0 - saturate (Blevel - BlkRng);
   Blevel *= BlkDesat;

   // Desaturate the blacks, then the whites.

   retval.rgb = lerp (lerp (retval.rgb, Luma.xxx, Blevel), Luma.xxx, Wlevel);

   return lerp (video, retval, tex2D (Mask, uv2));
}

