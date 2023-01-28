// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This is an extreme non-additive mix for alpha and delta (difference) keys.  The
 incoming key is faded in to full value at the 50% point, at which stage the
 background video starts to fade out.  The two images are mixed by giving the
 source with the maximum level priority.  The dissolve out is the reverse of that.

 The result is extreme, but can be interesting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAddUltra_Kx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
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

// technique NonAddUltra_Kx_F

DeclarePass (Fg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_F)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAddUltra_Kx_F)
{
   float4 Fgnd = tex2D (Fg_F, uv3);
   float4 Bgnd = tex2D (Bg_F, uv3);

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

//-----------------------------------------------------------------------------------------//

// technique NonAddUltra_Kx_I

DeclarePass (Fg_I)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAddUltra_Kx_I)
{
   float4 Fgnd = tex2D (Fg_I, uv3);
   float4 Bgnd = tex2D (Bg_I, uv3);

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

//-----------------------------------------------------------------------------------------//

// technique NonAddUltra_Kx_O

DeclarePass (Fg_O)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAddUltra_Kx_O)
{
   float4 Fgnd = tex2D (Fg_O, uv3);
   float4 Bgnd = tex2D (Bg_O, uv3);

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

