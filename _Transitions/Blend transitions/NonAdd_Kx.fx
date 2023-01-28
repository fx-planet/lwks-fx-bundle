// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect emulates the classic analog vision mixer non-add dissolve.  It uses an
 algorithm that mimics reasonably closely what the electronics used to do.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAdd_Kx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Non-additive mix (keyed)", "Mix", "Blend transitions", "Separates foreground from background then emulates the classic analog vision mixer non-add dissolve", CanSize);

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

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique NonAdd_Kx_F

DeclarePass (Fg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_F)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAdd_Kx_F)
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

   float alpha = Fgnd.a;

   Fgnd.a *= (1.0 - abs (Amount - 0.5)) * 2.0;
   Fgnd = max (lerp (Bgnd, kTransparentBlack, Amount), lerp (kTransparentBlack, Fgnd, Amount));

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, lerp (Bgnd, Fgnd, Fgnd.a), alpha);
}

//-----------------------------------------------------------------------------------------//

// technique NonAdd_Kx_I

DeclarePass (Fg_I)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAdd_Kx_I)
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

   float alpha = Fgnd.a;

   Fgnd.a *= (1.0 - abs (Amount - 0.5)) * 2.0;
   Fgnd = max (lerp (Bgnd, kTransparentBlack, Amount), lerp (kTransparentBlack, Fgnd, Amount));

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, lerp (Bgnd, Fgnd, Fgnd.a), alpha);
}

//-----------------------------------------------------------------------------------------//

// technique NonAdd_Kx_O

DeclarePass (Fg_O)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAdd_Kx_O)
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

   float alpha = Fgnd.a;

   Fgnd.a *= (1.0 - abs (0.5 - Amount)) * 2.0;
   Fgnd = max (lerp (kTransparentBlack, Bgnd, Amount), lerp (Fgnd, kTransparentBlack, Amount));

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, lerp (Bgnd, Fgnd, Fgnd.a), alpha);
}

