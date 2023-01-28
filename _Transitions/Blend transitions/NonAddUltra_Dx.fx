// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This is an extreme non-additive mix.  The incoming video is faded in to full value at
 the 50% point, at which stage the outgoing video starts to fade out.  The two images
 are mixed by giving the source with the maximum level priority.

 The result is extreme, but can be interesting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAddUltra_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Non-add mix ultra", "Mix", "Blend transitions", "Emulates the classic analog vision mixer non-add mix", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Params
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Linearity, "Linearity", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (NonAddUltra_Dx)
{
   float outAmount = min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = min (1.0, Amount * 2.0);
   float temp = outAmount * outAmount * outAmount;

   outAmount = lerp (outAmount, temp, Linearity);
   temp = in_Amount * in_Amount * in_Amount;
   in_Amount = lerp (in_Amount, temp, Linearity);

   float4 Fgnd = tex2D (Outgoing, uv3) * outAmount;
   float4 Bgnd = tex2D (Incoming, uv3) * in_Amount;

   return max (Fgnd, Bgnd);
}

