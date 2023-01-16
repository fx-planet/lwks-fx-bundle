// @Maintainer jwrl
// @Released 2023-01-07
// @Author jwrl
// @Created 2023-01-07

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
// Built 2023-01-07 jwrl.
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

DeclareEntryPoint (PeakDesaturate)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Input  = tex2D (Input, uv1);
   float4 retval = saturate (Inp);

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

   return lerp (Input, retval, tex2D (Mask, uv1));
}

