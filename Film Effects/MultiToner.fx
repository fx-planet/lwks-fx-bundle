// @Maintainer jwrl
// @Released 2023-01-09
// @Author jwrl
// @Created 2023-01-09

/**
 Multiple toner aims to produce the effect of a range of chemical processes that
 can be applied to black and white prints.  The tones used are generic, and the
 black and white conversion approximates the spectral response of panchromatic
 film.

 The sepia toner is based on an existing effect, and closely matches the look of
 of photographic prints that have been compared with it.  The selenium toners
 have two presets because the actual colour produced is seriously affected by
 the chemistry of the paper used.   Bottom line: these colour values have been
 obtained empirically.  Even with the best care and attention given, how well the
 results match can only be subjective.

 I've had to rely on on-line reference images for the gold toner.  As far as I'm
 aware I've never actually seen one "in the flesh", so to speak.  If it's wrong
 I can only apologise.  Copper toning can vary from the reddish tones that you
 see here through to quite green or even blue depending on the print's age and
 how it has been stored.  I just picked a colour and contrast setting that had
 about the right look.  I've based the blue in the iron toner on the blue you
 see in blueprints, because the chemistry that produces that colour is identical
 to the chemistry in a treated photographic print.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MultiToner.fx
//
// Version history:
//
// Built 2023-01-09 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Multiple toner", "Colour", "Film Effects", "Select from sepia, selenium, gold, copper and ferro toners to simulate darkroom processes", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Toner type", kNoGroup, 0, "Sepia|Selenium 1|Selenium 2|Gold|Copper|Iron");

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Tone, "Strength", "Toner settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Exposure, "Exposure", "Toner settings", "DisplayAsLiteral", 0.0, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMA       float3(0.217, 0.265, 0.518)  // A rough panchromatic profile

#define SEPIA      float3(0.732, 0.899, 1.0)
#define SELENIUM_1 float3(0.725, 0.950, 1.0)
#define SELENIUM_2 float3(0.744, 1.0, 0.871)
#define GOLD       float3(0.782, 0.983, 1.0)
#define COPPER     float3(0.604, 0.968, 1.0)
#define FERRO      float3(1.0, 0.776, 0.486)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (MultiTonerSepia)
{
   float4 source = ReadPixel (Inp, uv1);
   float4 retval = source;

   float alpha = retval.a;
   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (SEPIA * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma), toner_mix);

   retval.rgb = lerp (retval.rgb, toner, Amount);

   return lerp (source, lerp (kTransparentBlack, retval, alpha), tex2D (Mask, uv1));
}

DeclareEntryPoint (MultiTonerSelenium_1)
{
   float4 source = ReadPixel (Inp, uv1);
   float4 retval = source;

   float alpha = retval.a;
   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (SELENIUM_1 * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.116), toner_mix);

   retval.rgb = lerp (retval.rgb, toner, Amount);

   return lerp (source, lerp (kTransparentBlack, retval, alpha), tex2D (Mask, uv1));
}

DeclareEntryPoint (MultiTonerSelenium_2)
{
   float4 source = ReadPixel (Inp, uv1);
   float4 retval = source;

   float alpha = retval.a;
   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (SELENIUM_2 * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.187), toner_mix);

   retval.rgb = lerp (retval.rgb, toner, Amount);

   return lerp (source, lerp (kTransparentBlack, retval, alpha), tex2D (Mask, uv1));
}

DeclareEntryPoint (MultiTonerGold)
{
   float4 source = ReadPixel (Inp, uv1);
   float4 retval = source;

   float alpha = retval.a;
   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (GOLD * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.463), toner_mix);

   retval.rgb = lerp (retval.rgb, toner, Amount);

   return lerp (source, lerp (kTransparentBlack, retval, alpha), tex2D (Mask, uv1));
}

DeclareEntryPoint (MultiTonerCopper)
{
   float4 source = ReadPixel (Inp, uv1);
   float4 retval = source;

   float alpha = retval.a;
   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (COPPER * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.559), toner_mix);

   retval.rgb = lerp (retval.rgb, toner, Amount);

   return lerp (source, lerp (kTransparentBlack, retval, alpha), tex2D (Mask, uv1));
}

DeclareEntryPoint (MultiTonerIron)
{
   float4 source = ReadPixel (Inp, uv1);
   float4 retval = source;

   float alpha = retval.a;
   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (FERRO * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.408), toner_mix);

   retval.rgb = lerp (retval.rgb, toner, Amount);

   return lerp (source, lerp (kTransparentBlack, retval, alpha), tex2D (Mask, uv1));
}

