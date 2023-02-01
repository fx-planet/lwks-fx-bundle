// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This alpha and delta dissolve emulates a range of dissolve types.  The first is the
 classic analog vision mixer non-add mix.  It uses an algorithm that mimics reasonably
 closely what the vision mixer electronics used to do.

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
// Lightworks user effect Ndissolve_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Non-linear dissolve (keyed)", "Mix", "Blend transitions", "Separates foreground from background and dissolves it using a range of profiles", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Dissolve profile", kNoGroup, 0, "Non-additive mix|Ultra non-add|Trig curve|Quad curve");

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.5, -1.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Bgnd, Fgnd = tex2D (F, xy);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (B, xy);
      }
      else Bgnd = tex2D (B, xy);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? kTransparentBlack : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Non-add

DeclarePass (Fg_N)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_N)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_N)
{ return fn_keygen (Fg_N, Bg_N, uv3); }

DeclareEntryPoint (NonAdd)
{
   float4 Fgnd = tex2D (Super_N, uv3);
   float4 Bgnd = (Ttype == 0) && (Source == 0) ? tex2D (Fg_N, uv3) : tex2D (Bg_N, uv3);
   float4 retval;

   float alpha = Fgnd.a;

   Fgnd.a *= (1.0 - abs (Amount - 0.5)) * 2.0;

   if (Ttype == 2) {
      retval = lerp (Fgnd, Bgnd, Amount);
      Fgnd = max (lerp (kTransparentBlack, Bgnd, Amount), lerp (Fgnd, kTransparentBlack, Amount));
   }
   else {
      retval = lerp (Bgnd, Fgnd, Amount);
      Fgnd = max (lerp (Bgnd, kTransparentBlack, Amount), lerp (kTransparentBlack, Fgnd, Amount));
   }

   Fgnd = lerp (retval, Fgnd, abs (Strength));

   return lerp (Bgnd, lerp (Bgnd, Fgnd, Fgnd.a), alpha);
}

//-----------------------------------------------------------------------------------------//

// Ultra non-add

DeclarePass (Fg_U)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_U)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_U)
{ return fn_keygen (Fg_U, Bg_U, uv3); }

DeclareEntryPoint (UltraNonAdd)
{
   float4 Fgnd = tex2D (Super_U, uv3);
   float4 Bgnd = (Ttype == 0) && (Source == 0) ? tex2D (Fg_U, uv3) : tex2D (Bg_U, uv3);

   float outAmount, in_Amount;

   if (Ttype == 2) {
      in_Amount = min (1.0, Amount * 2.0);
      outAmount = min (1.0, (1.0 - Amount) * 2.0);
   }
   else {
      outAmount = min (1.0, Amount * 2.0);
      in_Amount = min (1.0, (1.0 - Amount) * 2.0);
   }

   outAmount = lerp (outAmount, pow (outAmount, 3.0), Strength);
   in_Amount = lerp (in_Amount, pow (in_Amount, 3.0), Strength);

   Fgnd.rgb = max (Fgnd.rgb * outAmount, Bgnd.rgb * in_Amount);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// Trig curve

DeclarePass (Fg_T)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_T)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_T)
{ return fn_keygen (Fg_T, Bg_T, uv3); }

DeclareEntryPoint (Trig)
{
   float4 Fgnd = tex2D (Super_T, uv3);
   float4 Bgnd = (Ttype == 0) && (Source == 0) ? tex2D (Fg_T, uv3) : tex2D (Bg_T, uv3);

   float amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Strength < 0.0 ? Strength * 0.6666666667 : Strength;

   amount = lerp (Amount, 1.0 - amount, curve);

   if (Ttype == 2) amount = 1.0 - amount;

   return lerp (Bgnd, lerp (Bgnd, Fgnd, amount), Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// Quad curve

DeclarePass (Fg_Q)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_Q)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Q)
{ return fn_keygen (Fg_Q, Bg_Q, uv3); }

DeclareEntryPoint (Quad)
{
   float4 Fgnd = tex2D (Super_Q, uv3);
   float4 Bgnd = (Ttype == 0) && (Source == 0) ? tex2D (Fg_Q, uv3) : tex2D (Bg_Q, uv3);

   float amount = 1.0 - abs ((Amount * 2.0) - 1.0);
   float curve  = abs (Strength);

   amount = Strength < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
   amount = Amount < 0.5 ? amount : 2.0 - amount;
   amount = lerp (Amount, amount * 0.5, curve);

   if (Ttype == 2) amount = 1.0 - amount;

   return lerp (Bgnd, lerp (Bgnd, Fgnd, amount), Fgnd.a);
}

