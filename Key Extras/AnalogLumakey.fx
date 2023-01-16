// @Maintainer jwrl
// @Released 2023-01-10
// @Author jwrl
// @Created 2023-01-10

/**
 This keyer is similar to the Lightworks lumakey effect, but behaves more like an analogue
 luminance keyer.  In this version "Tolerance" is called "Clip" and "Invert" has become
 "Invert key".  These are the industry standard names used for these functions in analogue
 keyers.

 When the key clip is exceeded by the image luminance the Lightworks keyer passes the luma
 value unchanged, which an analogue keyer will not.  This keyer turns the alpha channel fully
 on instead, which is consistent with the way that an analogue keyer works.

 Regardless of whether the key is inverted or not, the clip setting works from black at 0% to
 white at 100%.  Key softness, instead of being calculated entirely from within the keyed area
 is produced symmetrically around the key's edges.  Both of these are more consistent with the
 way that analogue keyers behave.

 The keyer's alpha channel can either replace the foreground's existing alpha channel or can
 be gated with it.  It can then optionally be used to key the foreground over the background
 or passed on to other effects.  In that mode the background is blanked.  This functionality
 was never provided in the analogue world so there is no equivalent to match it to.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnalogLumakey.fx
//
// Version history:
//
// Built 2023-01-10 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Analogue lumakey", "Key", "Key Extras", "A digital keyer which behaves in a similar way to an analogue keyer", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (KeyMode, "Mode", "Key settings", 0, "Luminance key|Lumakey plus existing alpha|Lumakey (no background)|Lumakey plus alpha (no background)");

DeclareFloatParam (KeyClip, "Clip", "Key settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Softness, "Softness", "Key settings", kNoFlags, 0.1, 0.0, 1.0);

DeclareBoolParam (InvertKey, "Invert key", "Key settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (AnalogLumakey)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ((KeyMode > 1) || IsOutOfBounds (uv2)) ? BLACK : tex2D (Bg, uv2);

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   if (InvertKey) alpha = 1.0 - alpha;

   if (abs (KeyMode - 2) == 1) alpha = min (Fgd.a, alpha);

   alpha *= Amount;

   return lerp (Bgd, Fgd, alpha * tex2D (Mask, uv1));
}

