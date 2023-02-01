// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 A transition that simulates the burn effect of the classic film optical.  Titles or
 any other keyed components are separated from the background with an alpha or delta
 key before executing the transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Optical_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Optical dissolve (keyed)", "Mix", "Blend transitions", "Separates foreground from background then simulates the burn effect of the classic film optical title", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Optical_Kx_F

DeclarePass (Fg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_F)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Optical_Kx_F)
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

   float amount  = 1.0 - Amount;
   float alpha   = Fgnd.a;
   float cAmount = sin (amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (amount * PI)) / 2.0;

   float4 Key = lerp (min (Fgnd, Bgnd), Bgnd, amount);

   Fgnd = lerp (Fgnd, min (Fgnd, Bgnd), amount);
   Key  = lerp (Fgnd, Key, aAmount);

   cAmount += 1.0;

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, saturate ((Key * cAmount) - bAmount.xxxx), alpha);
}

//-----------------------------------------------------------------------------------------//

// technique Optical_Kx_I

DeclarePass (Fg_I)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Optical_Kx_I)
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

   float amount  = 1.0 - Amount;
   float alpha   = Fgnd.a;
   float cAmount = sin (amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (amount * PI)) / 2.0;

   float4 Key = lerp (min (Fgnd, Bgnd), Bgnd, amount);

   Fgnd = lerp (Fgnd, min (Fgnd, Bgnd), amount);
   Key  = lerp (Fgnd, Key, aAmount);

   cAmount += 1.0;

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, saturate ((Key * cAmount) - bAmount.xxxx), alpha);
}

//-----------------------------------------------------------------------------------------//

// technique Optical_Kx_O

DeclarePass (Fg_O)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Optical_Kx_O)
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

   float alpha   = Fgnd.a;
   float cAmount = sin (Amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (Amount * PI)) / 2.0;

   float4 Key = lerp (min (Fgnd, Bgnd), Bgnd, Amount);

   Fgnd = lerp (Fgnd, min (Fgnd, Bgnd), Amount);
   Key  = lerp (Fgnd, Key, aAmount);

   cAmount += 1.0;

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, saturate ((Key * cAmount) - bAmount.xxxx), alpha);
}

