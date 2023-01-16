// @Maintainer jwrl
// @Released 2023-01-07
// @Author jwrl
// @Created 2023-01-07

/**
 This adjusts mid-range red, green and blue levels to enhance or reduce them.  It does
 this by adjusting both mid level contrast and saturation.  To do this it compresses
 or expands the black and white RGB levels to compensate.  Since that means that the
 final look that you achieve will be affected by the black and white levels provision
 has been made to adjust them.  This should be done before doing anything else.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MidtoneKicker.fx
//
// Version history:
//
// Built 2023-01-07 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Midtone kicker", "Colour", "Colour Tools", "Adjusts mid-range RGB levels to enhance or reduce them", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Reference, "Set black & white references and levels first", kNoGroup, true);

DeclareColourParam (WhitePoint, "White", "Reference points", kNoFlags, 1.0, 1.0, 1.0);
DeclareColourParam (BlackPoint, "Black", "Reference points", kNoFlags, 0.0, 0.0, 0.0);

DeclareFloatParam (S_curve, "Contrast", "Midtone adjustments", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Vibrance, "Saturation", "Midtone adjustments", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (WhiteLevel, "White level", "Fine tuning", "DisplayAsPercentage", 1.0, 0.5, 1.5);
DeclareFloatParam (Trim_R, "Red midtones", "Fine tuning", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Trim_G, "Green midtones", "Fine tuning", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Trim_B, "Blue midtones", "Fine tuning", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (BlackLevel, "Black level", "Fine tuning", "DisplayAsPercentage", 0.0, -0.5, 0.5);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_s_curve (float video, float curve, float level)
{
   float vid = abs (video - 0.5) * 2.0;

   vid = (video > 0.5) ? (1.0 + pow (vid, curve)) * 0.5
                       : (1.0 - pow (vid, curve)) * 0.5;

   return lerp (video, vid, level);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (MidtoneKicker)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Bgd = tex2D (Inp, uv1);
   float4 ret = Bgd;

   ret.rgb = (ret.rgb - BlackPoint.rgb) / WhitePoint.rgb;
   ret.rgb = (ret.rgb * WhiteLevel) + BlackLevel.xxx;

   float3 retval = ret.rgb;

   float vibval = pow (1.0 + Vibrance, 2.0) - 1.0;
   float maxval = max (retval.r, max (retval.g, retval.b));
   float amount, curves;

   if (S_curve < 0.0) {
      amount = abs (S_curve) * 0.6666666666;
      curves = 1.0 / (1.0 + (S_curve * 0.5));
   }
   else {
      amount = S_curve * 1.3333333333;
      curves = 1.0 - (S_curve * 0.5);
   }

   vibval *= ((retval.r + retval.g + retval.b) / 3.0) - maxval;
   retval  = lerp (retval, maxval.xxx, vibval);

   ret.r = lerp (ret.r, fn_s_curve (retval.r, curves, amount), Trim_R + 1.0);
   ret.g = lerp (ret.g, fn_s_curve (retval.g, curves, amount), Trim_G + 1.0);
   ret.b = lerp (ret.b, fn_s_curve (retval.b, curves, amount), Trim_B + 1.0);

   return lerp (Bgd, ret, tex2D (Mask, uv1));
}

