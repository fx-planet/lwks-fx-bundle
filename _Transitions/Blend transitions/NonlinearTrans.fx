// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2017-01-03

/**
 This effect emulates a range of dissolve types and can be used as a standard video
 transition, or applied to keyed and blended video.  The first transition is the classic
 analog vision mixer non-add mix.  It uses an algorithm that mimics reasonably
 closely what the vision mixer electronics used to do.

 The second is an extreme non-additive mix.  The incoming video is faded in to full value
 at the 50% point, at which stage the outgoing video starts to fade out.  The two images
 are mixed by giving the source with the maximum level priority.  The result is always
 visually interesting.

 The final two are essentially the same as a Lightworks' dissolve, with a choice of either
 a trigonometric curve or a quadratic curve applied to the "Amount" parameter.  You can
 vary the linearity of the curve using the strength setting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonlinearTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-11 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-07 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Non-linear transitions", "Mix", "Blend transitions", "Dissolves using a range of non-linear profiles", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Dissolve profile", kNoGroup, 0, "Non-additive mix|Ultra non-add|Trig curve|Quad curve");
DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.5, -1.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (!Blended) return float4 ((ReadPixel (F, xy1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (B, xy2);
      Bgnd = ReadPixel (F, xy1);
   }
   else {
      Fgnd = ReadPixel (F, xy1);
      Bgnd = ReadPixel (B, xy2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (F, xy1) : ReadPixel (B, xy2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Non-add

DeclarePass (Fg_N)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_N)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (NonAdd)
{
   float4 Fgnd = tex2D (Fg_N, uv3);
   float4 Bgnd = tex2D (Bg_N, uv3);
   float4 maskBg, retval;

   float amount;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         float alpha = Fgnd.a;

         amount = SwapDir ? Amount : 1.0 - Amount;

         Fgnd.a *= (1.0 - abs (Amount - 0.5)) * 2.0;
         Fgnd = lerp (kTransparentBlack, Fgnd, amount);

         retval = max (lerp (Bgnd, kTransparentBlack, amount), Fgnd);
         retval.a = alpha;

         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      maskBg = Fgnd;

      amount = (1.0 - abs (Amount - 0.5)) * 2.0;

      Fgnd = lerp (Fgnd, kTransparentBlack, Amount);
      Bgnd = lerp (kTransparentBlack, Bgnd, Amount);
      retval = saturate (max (Bgnd, Fgnd) * amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// Ultra non-add

DeclarePass (Fg_U)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_U)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (NonAddUltra)
{
   float4 Fgnd = tex2D (Fg_U, uv3);
   float4 Bgnd = tex2D (Bg_U, uv3);
   float4 maskBg, retval;

   float amount;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         float alpha  = Fgnd.a;

         amount = SwapDir ? Amount : 1.0 - Amount;

         Fgnd.a *= (1.0 - abs (amount - 0.5)) * 2.0;
         retval = max (lerp (Bgnd, kTransparentBlack, amount), lerp (kTransparentBlack, Fgnd, amount));
         retval.a = alpha;

         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      amount = (1.0 - abs (Amount - 0.5)) * 2.0;
      maskBg = Fgnd;

      Fgnd = lerp (Fgnd, kTransparentBlack, Amount);
      Bgnd = lerp (kTransparentBlack, Bgnd, Amount);
      retval = saturate (amount * max (Bgnd, Fgnd));
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// Trig curve

DeclarePass (Fg_T)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_T)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Trig)
{
   float4 Fgnd = tex2D (Fg_T, uv3);
   float4 Bgnd = tex2D (Bg_T, uv3);
   float4 maskBg, retval;

   float curve  = Strength < 0.0 ? Strength * 0.6666666667 : Strength;
   float amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;

   amount = lerp (Amount, 1.0 - amount, curve);

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         float alpha  = Fgnd.a;

         if (!SwapDir) amount = 1.0 - amount;

         retval = lerp (Bgnd, Fgnd, amount);
         retval.a = alpha;

         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      maskBg = Fgnd;
      retval = lerp (Fgnd, Bgnd, amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// Quad curve

DeclarePass (Fg_P)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_P)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Quad)
{
   float4 Fgnd = tex2D (Fg_P, uv3);
   float4 Bgnd = tex2D (Bg_P, uv3);
   float4 maskBg, retval;

   float amount = Amount * Amount * (3.0 - (Amount * 2.0));

   amount = lerp (Amount, amount, Strength + 1.0);

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         float alpha  = Fgnd.a;

         if (!SwapDir) amount = 1.0 - amount;

         retval = lerp (Bgnd, Fgnd, amount);
         retval.a = alpha;

         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      retval = lerp (Fgnd, Bgnd, amount);
      maskBg = Fgnd;
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

