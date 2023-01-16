// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is essentially the same as Lightworks' dissolve, with a trigonometric curve applied
 to the "Amount" parameter.  If you need to you can vary the linearity of the curve.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sdissolve_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("S dissolve", "Mix", "Blend transitions", "Dissolve using either a trigonometric or a quadratic curve", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Curve type", kNoGroup, 0, "Trigonometric|Quadratic");

DeclareFloatParam (Curve, "Curve amount", kNoGroup, kNoFlags, 0.5, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Trig)
{
   float amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Curve < 0.0 ? Curve * 0.6666666667 : Curve;

   float4 Bgnd = ReadPixel (Bg, uv2);

   amount = lerp (Amount, 1.0 - amount, curve);

   return lerp (ReadPixel (Fg, uv1), Bgnd, amount);
}

DeclareEntryPoint (Power)
{
   float amount = 1.0 - abs ((Amount * 2.0) - 1.0);
   float curve  = abs (Curve);

   float4 Bgnd = ReadPixel (Bg, uv2);

   amount = Curve < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
   amount = Amount < 0.5 ? amount : 2.0 - amount;
   amount = lerp (Amount, amount * 0.5, curve);

   return lerp (ReadPixel (Fg, uv1), Bgnd, amount);
}

