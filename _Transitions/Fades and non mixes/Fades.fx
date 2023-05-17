// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2018-12-31

/**
 This simple effect fades any video to which it's applied to or from from black.  It
 isn't a standard dissolve, since it requires one input only.  It must be applied in
 the same way as a title effect, i.e., by marking the region that the fade in or out
 is to occupy.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fades.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Fades", "Mix", "Fades and non mixes", "Fades video to or from black", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Type, "Fade type", kNoGroup, 0, "Fade up|Fade down");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0,1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Fades)
{
   float level = Type ? Amount : 1.0 - Amount;

   float4 Input  = ReadPixel (Fgd, uv2);
   float4 retval = lerp (Input, BLACK, level);

   return lerp (kTransparentBlack, retval, tex2D (Mask, uv2).x);
}

