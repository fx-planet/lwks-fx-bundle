// @Maintainer jwrl
// @Released 2023-01-12
// @Author jwrl
// @Created 2023-01-12

/**
 This simulates the "colour under/pilot tone colour" of early helical scan recorders.
 It does this by blurring the image chroma and re-applying it to the luminance.  This
 effect is resolution locked to the sequence in which it is used.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaBleed.fx
//
// Version history:
//
// Built 2023-01-12 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chroma bleed", "Stylize", "Video artefacts", "Gives the horizontal smeared colour look of early helical scan recorders", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Smear, "Smear", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Saturation, "Chroma boost", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LOOP   12
#define DIVIDE 49

#define LUMA   float3(0.2989, 0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Bleed)
{
   float4 retval = tex2D (Inp, uv1);

   if ((Smear > 0.0) && (Amount > 0.0)) {

      float2 xy = 0.0.xx;
      float2 spread = float2 (Smear * 0.003, 0.0);

      for (int i = 0; i < LOOP; i++) {
         xy += spread;
         retval = max (retval, tex2D (Inp, uv1 + xy));
         retval = max (retval, tex2D (Inp, uv1 - xy));
         xy += spread;
         retval = max (retval, tex2D (Inp, uv1 + xy));
         retval = max (retval, tex2D (Inp, uv1 - xy));
      }
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : retval;
}

DeclareEntryPoint (ChromaBleed)
{
   float4 retval = tex2D (Inp, uv1);

   if ((Smear > 0.0) && (Amount > 0.0)) {
      float2 xy = 0.0.xx;
      float2 spread = float2 (Smear * 0.000375, 0.0);

      float4 chroma = tex2D (Bleed, uv2);

      for (int i = 0; i < LOOP; i++) {
         xy += spread;
         chroma += tex2D (Inp, uv1 + xy);
         chroma += tex2D (Inp, uv1 - xy);
         xy += spread;
         chroma += tex2D (Inp, uv1 + xy);
         chroma += tex2D (Inp, uv1 - xy);
      }

      chroma /= DIVIDE;

      float luma = dot (chroma.rgb, LUMA);

      chroma.rgb -= luma.xxx;
      chroma.rgb *= 1.0 + Saturation;
      luma = dot (retval.rgb, LUMA);
      chroma.rgb = saturate (chroma.rgb + luma.xxx);

      retval = lerp (retval, chroma, Amount);
   }
   else {
      float amt = Amount * Saturation;

      retval.rgb = saturate (retval.rgb + (retval.rgb - dot (retval.rgb, LUMA).xxx) * amt);
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : retval;
}

