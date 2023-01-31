// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This effect emulates a range of dissolve types.  The first is the classic analog vision
 mixer non-add mix.  It uses an algorithm that mimics reasonably closely what the vision
 mixer electronics used to do.

 The second is an extreme non-additive mix.  The incoming video is faded in to full value
 at the 50% point, at which stage the outgoing video starts to fade out.  The two images
 are mixed by giving the source with the maximum level priority.  The result can be
 extreme, but is always visually interesting.

 The final two are essentially the same as a Lightworks' dissolve, with a choice of either
 a trigonometric curve or a quadratic curve applied to the "Amount" parameter.  You can
 vary the linearity of the curve using the strength setting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ndissolve_Dx.fx
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Non-linear dissolve", "Mix", "Blend transitions", "Dissolves using a range of profiles", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Dissolve profile", kNoGroup, 0, "Non-additive mix|Ultra non-add|Trig curve|Quad curve");

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.5, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Non-add

DeclareEntryPoint (NonAdd)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 Mix0 = lerp (Fgnd, Bgnd, Amount);

   Fgnd = lerp (Fgnd, kTransparentBlack, Amount);
   Bgnd = lerp (kTransparentBlack, Bgnd, Amount);

   float4 Mix1 = saturate (max (Bgnd, Fgnd) * ((1.0 - abs (Amount - 0.5)) * 2.0));

   return lerp (Mix0, Mix1, abs (Strength));
}

//-----------------------------------------------------------------------------------------//

// Ultra non-add

DeclareEntryPoint (NonAddUltra)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float outAmount = min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = min (1.0, Amount * 2.0);
   float temp = outAmount * outAmount * outAmount;

   outAmount = lerp (outAmount, temp, Strength);
   temp = in_Amount * in_Amount * in_Amount;
   in_Amount = lerp (in_Amount, temp, Strength);

   Fgnd *= outAmount;
   Bgnd *= in_Amount;

   return max (Fgnd, Bgnd);
}

//-----------------------------------------------------------------------------------------//

// Trig curve

DeclareEntryPoint (Trig)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Strength < 0.0 ? Strength * 0.6666666667 : Strength;

   amount = lerp (Amount, 1.0 - amount, curve);

   return lerp (Fgnd, Bgnd, amount);
}

//-----------------------------------------------------------------------------------------//

// Quad curve

DeclareEntryPoint (Power)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float amount = 1.0 - abs ((Amount * 2.0) - 1.0);
   float curve  = abs (Strength);

   amount = Strength < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
   amount = Amount < 0.5 ? amount : 2.0 - amount;
   amount = lerp (Amount, amount * 0.5, curve);

   return lerp (Fgnd, Bgnd, amount);
}

