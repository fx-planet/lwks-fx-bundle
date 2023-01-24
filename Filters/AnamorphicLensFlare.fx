// @Maintainer jwrl
// @Released 2023-01-24
// @Author khaver
// @Created 2011-05-25

/**
 Anamorphic Lens Flare simulates the non-linear flare that an anamorphic lens produces.
 They are those purplish horizontal flares often seen on movie blockbusters.  Use the
 Threshold slider to isolate just the bright lights and the Length slider to adjust the
 size of the flare.  Checking the "Show Flare" checkbox will display the flare against
 black.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnamorphicLensFlare.fx
//
// Version history:
//
// Updated 2023-01-24 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Anamorphic lens flare", "Stylize", "Filters", "Simulates the horizontal non-linear flare that an anamorphic lens produces", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (BlurAmount, "Length", kNoGroup, kNoFlags, 12.0, 0.0, 50.0);
DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (adjust, "Threshold", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Hue, "Hue", kNoGroup, kNoFlags, 0.0, -0.5, 0.5);

DeclareBoolParam (flare, "Show Flare", kNoGroup, false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclarePass (Adjust)
{
   float4 Color = tex2D (Inp, uv2);
   float4 c_hue = float4 (0.1.xx, 1.2, 1.0);

   float luma = (Color.r + Color.g + Color.b) / 3.0;

   if (Hue < 0.0) c_hue.r += abs (Hue);

   if (Hue > 0.0) c_hue.g += Hue;

   if (luma < 1.0 - adjust) Color.rgb = 0.0.xxx;

   return Color * c_hue;
}

DeclarePass (Blur1)
{
   float4 ret = kTransparentBlack;

   float2 offset = 0.0.xx;
   float2 displacement = float2 (1.0 / _OutputWidth, 0.0);

   for (int count = 0; count < 24; count++) {
      ret += tex2D (Adjust, uv2 + offset);
      ret += tex2D (Adjust, uv2 - offset);
      offset += displacement;
   }

   ret /= 48.0;

   return ret;
}

DeclarePass (Blur2)
{
   float4 ret = kTransparentBlack;

   float2 offset = 0.0.xx;
   float2 displacement = float2 (BlurAmount / _OutputWidth, 0.0);

   for (int count = 0; count < 24; count++) {
      ret += tex2D (Blur1, uv2 + offset);
      ret += tex2D (Blur1, uv2 - offset);
      offset += displacement;
   }

   ret /= 24.0;

   return ret;
}

DeclareEntryPoint (AnamorphicLensFlare)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 blr = tex2D (Blur2, uv2);
   float4 source = tex2D (Inp, uv2);
   float4 comb = saturate (float4 (source.rgb + blr.rgb, source.a));

   blr = flare ? float4 (blr.rgb * Strength * 2.0, source.a) : lerp (source, comb, Strength);

   blr = lerp (kTransparentBlack, blr, source.a);

   return lerp (source, blr, tex2D (Mask, uv2).x);
}

