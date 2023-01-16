// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is essentially the same as the S dissolve but extended to dissolve alpha and delta
 keys.  A trigonometric curve is applied to the "Amount" parameter and the linearity of
 the curve can be adjusted.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sdissolve_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("S dissolve (keyed)", "Mix", "Blend transitions", "Separates foreground from background then dissolves it with a non-linear profile", CanSize);

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

DeclareIntParam (CurveType, "Curve type", kNoGroup, 0, "Trigonometric|Quadratic");

DeclareFloatParam (CurveAmount, "Curve amount", kNoGroup, kNoFlags, 0.5, -1.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define TRIG    0
#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Sdissolve_Kx_F)
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

   float amount, curve;

   if (CurveType == TRIG) {
      amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
      curve  = CurveAmount < 0.0 ? CurveAmount * 0.6666666667 : CurveAmount;

      amount = lerp (Amount, 1.0 - amount, curve);
   }
   else {
      amount = 1.0 - abs ((Amount * 2.0) - 1.0);
      curve  = abs (CurveAmount);

      amount = CurveAmount < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
      amount = Amount < 0.5 ? amount : 2.0 - amount;
      amount = lerp (Amount, amount * 0.5, curve);
   }

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, lerp (Bgnd, Fgnd, amount), Fgnd.a);
}

DeclareEntryPoint (Sdissolve_Kx_I)
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

   float amount, curve;

   if (CurveType == TRIG) {
      amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
      curve  = CurveAmount < 0.0 ? CurveAmount * 0.6666666667 : CurveAmount;

      amount = lerp (Amount, 1.0 - amount, curve);
   }
   else {
      amount = 1.0 - abs ((Amount * 2.0) - 1.0);
      curve  = abs (CurveAmount);

      amount = CurveAmount < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
      amount = Amount < 0.5 ? amount : 2.0 - amount;
      amount = lerp (Amount, amount * 0.5, curve);
   }

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, lerp (Bgnd, Fgnd, amount), Fgnd.a);
}

DeclareEntryPoint (Sdissolve_Kx_O)
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

   float amount, curve;

   if (CurveType == TRIG) {
      amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
      curve  = CurveAmount < 0.0 ? CurveAmount * 0.6666666667 : CurveAmount;

      amount = lerp (Amount, 1.0 - amount, curve);
   }
   else {
      amount = 1.0 - abs ((Amount * 2.0) - 1.0);
      curve  = abs (CurveAmount);

      amount = CurveAmount < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
      amount = Amount < 0.5 ? amount : 2.0 - amount;
      amount = lerp (Amount, amount * 0.5, curve);
   }

   return CropEdges && IsOutOfBounds (uv2)
          ? kTransparentBlack : lerp (Bgnd, lerp (Fgnd, Bgnd, amount), Fgnd.a);
}

