// @Maintainer jwrl
// @Released 2023-01-25
// @Author jwrl
// @Created 2023-01-25

/**
 This effect allows the user to apply an S-curve correction to red, green and blue video
 components and to the luminance.  You can achieve some very dramatic visual results with
 it that are hard to get by other means.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleS.fx
//
// Version history:
//
// Built 2023-01-25 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Simple S curve", "Colour", "Simple tools", "This applies an S curve to the video levels to give an image that extra zing", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Mix amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (CurveY, "Luma curve", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (CurveR, "Red curve", "RGB components", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CurveG, "Green curve", "RGB components", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CurveB, "Blue curve", "RGB components", kNoFlags, 0.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

/**
 If V is less than 0.5 this macro will double it and raise it to the power P, then
 halve it.  If it is greater than 0.5 it will invert it then double and raise it to
 the power of P before inverting and halving it again.  This applies an S curve to V
 when the two components are combined.
*/

#define S_curve(V,P) (V > 0.5 ? 1.0 - (pow (2.0 - V - V, P) * 0.5) : pow (V + V, P) * 0.5)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Vid)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (SimpleS)
{
   if (IsOutOfBounds (uv2)) return kTransparentBlack;

   float4 video  = tex2D (Vid, uv2);   // Recover the video source
   float4 retval = video;              // Only really needs video.a

   // Now load a float3 variable with double the Y curve and offset it
   // by 1 to give us a range from 1 to 3, limited to a minimum of 1.

   float3 curves = (max (CurveY + CurveY, 0.0) + 1.0).xxx;

   // Add to the luminance curves the doubled and limited RGB values.
   // This means that each curve value will now range between 1 and 5.

   curves += max (float3 (CurveR, CurveG, CurveB) * 2.0, 0.0.xxx);

   // Now place the individual S-curve modified RGB channels into retval

   retval.r = S_curve (video.r, curves.r);
   retval.g = S_curve (video.g, curves.g);
   retval.b = S_curve (video.b, curves.b);

   // Return the processed video, mixing it back with the input video

   retval = lerp (video, retval, Amount);

   return lerp (video, retval, tex2D (Mask, uv2).x);
}

