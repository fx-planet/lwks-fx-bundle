// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is an extreme non-additive mix for alpha and delta (difference) keys.  The
 incoming key is faded in to full value at the 50% point, at which stage the
 background video starts to fade out.  The two images are mixed by giving the
 source with the maximum level priority.  The dissolve out is the reverse of that.

 The result is extreme, but can be interesting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAddUltra_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Non-add mix ultra (keyed)", "Mix", "Blend transitions", "This is an extreme non-additive mix for titles, which are delta keyed from the background", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Linearity, "Linearity", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (NonAddUltra_Kx_F)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   if (Source == 0) {
      float4 Key = Bgnd; Bgnd = Fgnd;

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Key.rgb, Bgnd.rgb));
      Fgnd.rgb = Key.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);

   outAmount = lerp (outAmount, pow (outAmount, 3.0), Linearity);
   in_Amount = lerp (in_Amount, pow (in_Amount, 3.0), Linearity);

   Fgnd.rgb = max (Fgnd.rgb * outAmount, Bgnd.rgb * in_Amount);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : lerp (Bgnd, Fgnd, Fgnd.a);
}

DeclareEntryPoint (NonAddUltra_Kx_I)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   if (Source == 0) {
      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);

   outAmount = lerp (outAmount, pow (outAmount, 3.0), Linearity);
   in_Amount = lerp (in_Amount, pow (in_Amount, 3.0), Linearity);

   Fgnd.rgb = max (Fgnd.rgb * outAmount, Bgnd.rgb * in_Amount);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : lerp (Bgnd, Fgnd, Fgnd.a);
}

DeclareEntryPoint (NonAddUltra_Kx_O)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   if (Source == 0) {
      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);

   outAmount = lerp (outAmount, pow (outAmount, 3.0), Linearity);
   in_Amount = lerp (in_Amount, pow (in_Amount, 3.0), Linearity);

   Fgnd.rgb = max (Bgnd.rgb * outAmount, Fgnd.rgb * in_Amount);

   return CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : lerp (Bgnd, Fgnd, Fgnd.a);
}

