// @Maintainer jwrl
// @Released 2023-01-10
// @Author jwrl
// @Created 2023-01-10

/**
 This is a simple black and white balance utility.  To use it, first sample the point that
 you want to use as a white reference with the eyedropper, then get the black reference
 point.  Switch off "Select white and black reference points" and set up the white and
 black levels.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhiteBalance.fx
//
// Version history:
//
// Built 2023-01-10 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("White and black balance", "Colour", "Simple tools", "A simple black and white balance utility", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Reference, "Select white and black reference points", kNoGroup, true);

DeclareColourParam (WhitePoint, "White", "Reference points", kNoFlags, 1.0, 1.0, 1.0);
DeclareColourParam (BlackPoint, "Black", "Reference points", kNoFlags, 0.0, 0.0, 0.0);

DeclareFloatParam (WhiteLevel, "White", "Target levels", "DisplayAsPercentage", 1.0, 0.5, 1.5);
DeclareFloatParam (BlackLevel, "Black", "Target levels", "DisplayAsPercentage", 0.0, -0.5, 0.5);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (WhiteBalance)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval, source = tex2D (Inp, uv1);

   if (!Reference) {
      // Get the black and white reference points

      retval = ((source - BlackPoint) / WhitePoint);

      // Convert the black and white reference values to the target values

      retval = ((retval * WhiteLevel) + BlackLevel.xxxx);

      retval.a = source.a;
   }
   else retval = source;

   retval = lerp (kTransparentBlack, saturate (source), source.a);

   return lerp (source, retval, tex2D (Mask, uv1));
}

