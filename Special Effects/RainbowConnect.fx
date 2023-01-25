// @Maintainer jwrl
// @Released 2023-01-25
// @Author jwrl
// @Created 2023-01-25

/**
 This effect changes tones through a complex colour translation while performing what is
 essentially a non-additive mix.  It can be adjusted to operate over a limited range of the
 input video levels or the full range.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RainbowConnect.fx
//
// Version history:
//
// Built 2023-01-25 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rainbow connection", "Stylize", "Special Effects", "Changes colours through rainbow patterns according to levels", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Saturation, "Saturation", "Colour settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (HueCycle, "Hue cycling", "Colour settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (LowClip, "Low clip", "Range settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (HighClip, "High clip", "Range settings", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (Softness, "Key softness", "Range settings", kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SQRT_3 1.7320508076
#define TWO_PI 6.2831853072

#define H_MIN  0.3333333333
#define H_MAX  0.6666666667

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RainbowConnect)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgnd   = tex2D (Inp, uv1);
   float4 premix = float4 (1.0.xxx - Fgnd.rgb, Fgnd.a);
   float4 nonAdd = max (Fgnd * min (1.0, 2.0 * (1.0 - Amount)), premix * min (1.0, 2.0 * Amount));

   premix.rgb = max (Fgnd.rgb, premix.rgb);

   float Alpha = Fgnd.a;
   float Luma  = 0.1 + (0.5 * premix.r);
   float Satn  = premix.g * Saturation;
   float Hue   = frac (premix.b + (Amount * HueCycle));
   float Hfctr = (floor (3.0 * Hue) + 0.5) / 3.0;

   Hue = SQRT_3 * tan ((Hue - Hfctr) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   float4 retval = (Hue < H_MIN) ? float4 (Green, Blue, Red, Alpha)
                 : (Hue < H_MAX) ? float4 (Red, Green, Blue, Alpha)
                                 : float4 (Blue, Red, Green, Alpha);

   retval = lerp (nonAdd, retval, Amount);
   Luma   = dot (Fgnd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   float edge = max (0.00001, Softness);
   float clip = (LowClip * 1.0002) - (edge * 0.5) - 0.0001;

   Alpha = saturate ((Luma - clip) / edge);
   clip  = (HighClip * 1.0002) - (edge * 0.5) - 0.0001;
   Alpha = min (Alpha, saturate ((clip - Luma) / edge));

   return lerp (Fgnd, retval, tex2D (Mask, uv1).x * Alpha);
}

