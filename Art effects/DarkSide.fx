// @Maintainer jwrl
// @Released 2023-05-14
// @Author jwrl
// @Created 2017-02-25

/**
 The dark side gives a dark "glow" (don't know what else to call it) to an image.
 All parameters are minimum range limited to prevent manual entry of illegal or
 negative values.  There is no such limit to the maximum values possible.  The alpha
 channel is fully preserved throughout.

 It's sort of based on the Lightworks Glow effect, but only slightly.  The code under
 the hood differs from the code in their effect, and "Size" scales from 0% to 100%,
 not from 1 to 10.  It also has the ability to feather the red, green and blue values
 and add a glow colour to them, which the Lightorks effect does not.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DarkSide.fx
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2022-12-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("The dark side", "Stylize", "Art Effects", "Creates a shadow enhancing soft dark blur.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Source, "Source", kNoGroup, 0, "Luminance|Red|Green|Blue");

DeclareFloatParam (glowKnee, "Tolerance", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (glowFeather, "Feather", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (glowSpread, "Size", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (glowAmount, "Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour, "Colour difference", kNoGroup, kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA float3(0.2989, 0.5866, 0.1145)

#define F_SCALE 0.5
#define P_SCALE 0.0015

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Video)
{ return ReadPixel (Inp, uv1); }

DeclarePass (Glow_1)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval = tex2D (Video, uv2);

   float feather = max (glowFeather, 0.0) * F_SCALE;
   float knee = max (glowKnee, 0.0);
   float vid = Source == 1 ? retval.r : Source == 2 ? retval.g :
               Source == 3 ? retval.b : dot (retval.rgb, LUMA);

   vid *= retval.a;

   if (vid < knee) { retval.rgb = 1.0.xxx; }
   else if (vid >= (knee + feather)) { retval.rgb = Colour.rgb; }
   else retval.rgb = lerp (1.0.xxx, Colour.rgb, (vid - knee) / feather);

   return retval;
}

DeclarePass (Glow_2)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float2 xy = uv2;
   float2 offset = float2 (max (glowSpread, P_SCALE) * P_SCALE, 0.0);

   float4 retval = tex2D (Glow_1, xy);

   xy += offset; retval += tex2D (Glow_1, xy);
   xy += offset; retval += tex2D (Glow_1, xy);
   xy += offset; retval += tex2D (Glow_1, xy);
   xy += offset; retval += tex2D (Glow_1, xy);
   xy += offset; retval += tex2D (Glow_1, xy);
   xy += offset; retval += tex2D (Glow_1, xy);
   xy += offset; retval += tex2D (Glow_1, xy);

   xy = uv2 - offset;
   retval += tex2D (Glow_1, xy);

   xy -= offset; retval += tex2D (Glow_1, xy);
   xy -= offset; retval += tex2D (Glow_1, xy);
   xy -= offset; retval += tex2D (Glow_1, xy);
   xy -= offset; retval += tex2D (Glow_1, xy);
   xy -= offset; retval += tex2D (Glow_1, xy);
   xy -= offset; retval += tex2D (Glow_1, xy);

   return retval / 15.0;
}

DeclareEntryPoint (DarkSide)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 retval = tex2D (Video, uv2);
   float4 gloVal = tex2D (Glow_2, uv2);
   float4 source = retval;

   float2 offset = float2 (0.0, max (glowSpread, P_SCALE) * _OutputAspectRatio * P_SCALE);
   float2 xy = uv2;

   xy += offset; gloVal += tex2D (Glow_2, xy);
   xy += offset; gloVal += tex2D (Glow_2, xy);
   xy += offset; gloVal += tex2D (Glow_2, xy);
   xy += offset; gloVal += tex2D (Glow_2, xy);
   xy += offset; gloVal += tex2D (Glow_2, xy);
   xy += offset; gloVal += tex2D (Glow_2, xy);
   xy += offset; gloVal += tex2D (Glow_2, xy);

   xy = uv2 - offset;
   gloVal += tex2D (Glow_2, xy);

   xy -= offset; gloVal += tex2D (Glow_2, xy);
   xy -= offset; gloVal += tex2D (Glow_2, xy);
   xy -= offset; gloVal += tex2D (Glow_2, xy);
   xy -= offset; gloVal += tex2D (Glow_2, xy);
   xy -= offset; gloVal += tex2D (Glow_2, xy);
   xy -= offset; gloVal += tex2D (Glow_2, xy);

   gloVal = saturate (retval - (gloVal / 15.0));

   float amount = max (glowAmount, 0.0);

   retval.rgb = lerp (retval, gloVal, amount).rgb;

   return lerp (source, retval, tex2D (Mask, uv2).x);
}
