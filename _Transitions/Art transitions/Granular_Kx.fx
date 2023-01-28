// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect uses a granular noise driven pattern to transition into or out of an alpha
 or delta key.  The noise component is based on work by users khaver and windsturm.  The
 radial gradient part is from an effect provided by LWKS Software Ltd.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Granulate_Kx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Granular dissolve (keyed)", "Mix", "Art transitions", "Uses a granular noise driven pattern to transition into or out of the foreground", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");
DeclareIntParam (SetTechnique, "Transition type", kNoGroup, 1, "Top to bottom|Left to right|Radial|No gradient");

DeclareBoolParam (TransDir, "Invert transition direction", kNoGroup, false);

DeclareFloatParam (gWidth, "Width", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (pSize, "Size", "Particles", kNoFlags, 5.5, 1.0, 10.0);
DeclareFloatParam (pSoftness, "Softness", "Particles", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (TransVar, "Static particle pattern", "Particles", false);
DeclareBoolParam (Sparkles, "Sparkle", "Particles", false);

DeclareColourParam (starColour, "Colour", "Particles", kNoFlags, 0.9, 0.75, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define B_SCALE 0.000545
#define SQRT_2  1.4142135624

// Pascal's triangle magic numbers for blur

float _pascal [] = { 0.3125, 0.2344, 0.09375, 0.01563 };

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

float4 fn_noise (float2 uv)
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;

   return saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 3).xxxx;
}

float4 fn_blur_X (sampler B, float2 uv)
{
   float2 offset_X1 = float2 (pSoftness * B_SCALE, 0.0);
   float2 offset_X2 = offset_X1 * 2.0;
   float2 offset_X3 = offset_X1 * 3.0;

   float4 retval = tex2D (B, uv) * _pascal [0];

   retval += tex2D (B, uv + offset_X1) * _pascal [1];
   retval += tex2D (B, uv - offset_X1) * _pascal [1];
   retval += tex2D (B, uv + offset_X2) * _pascal [2];
   retval += tex2D (B, uv - offset_X2) * _pascal [2];
   retval += tex2D (B, uv + offset_X3) * _pascal [3];
   retval += tex2D (B, uv - offset_X3) * _pascal [3];

   return retval;
}

float4 fn_blur_Y (sampler B, float2 uv)
{
   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio * B_SCALE);
   float2 offset_Y2 = offset_Y1 * 2.0;
   float2 offset_Y3 = offset_Y1 * 3.0;

   float4 retval = tex2D (B, uv) * _pascal [0];

   retval += tex2D (B, uv + offset_Y1) * _pascal [1];
   retval += tex2D (B, uv - offset_Y1) * _pascal [1];
   retval += tex2D (B, uv + offset_Y2) * _pascal [2];
   retval += tex2D (B, uv - offset_Y2) * _pascal [2];
   retval += tex2D (B, uv + offset_Y3) * _pascal [3];
   retval += tex2D (B, uv - offset_Y3) * _pascal [3];

   return retval;
}

float4 fn_main (sampler F, sampler B, sampler S, sampler B1, sampler B2, float2 xy)
{
   float grad   = tex2D (B1, xy).x;
   float noise  = tex2D (B2, ((xy - 0.5) / pSize) + 0.5).x;
   float amount = saturate (((0.5 - grad) * 2.0) + noise);

   float4 Fgnd = tex2D (S, xy);
   float4 retval;

   if (Ttype == 0) { retval = lerp (tex2D (F, xy), Fgnd, Fgnd.a * amount); }
   else {
      float amt = Ttype == 1 ? amount : 1.0 - amount;

      retval = lerp (tex2D (B, xy), Fgnd, Fgnd.a * amt);
   }

   if (Sparkles) {
      amount = 0.5 - abs (amount - 0.5);

      float stars = saturate ((pow (amount, 3.0) * 4.0) + amount);

      retval = lerp (retval, starColour, stars * Fgnd.a);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Granulate Vertical

DeclarePass (Fg_V)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_V)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_V)
{ return fn_keygen (Fg_V, Bg_V, uv3); }

DeclarePass (Noise_V)
{ return fn_noise (uv3); }

DeclarePass (Blur_1_V)
{ return fn_blur_X (Noise_V, uv3); }

DeclarePass (Blur_V)
{ return fn_blur_Y (Blur_1_V, uv3); }

DeclarePass (Vertical)
{
   float retval = TransDir ? smoothstep (0.0, 1.0, 1.0 - uv3.y) : smoothstep (0.0, 1.0, uv3.y);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

DeclareEntryPoint (Granulate_V)
{ return fn_main (Fg_V, Bg_V, Super_V, Vertical, Blur_V, uv3); }

//-----------------------------------------------------------------------------------------//

// technique Granulate Horizontal

DeclarePass (Fg_H)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_H)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_H)
{ return fn_keygen (Fg_H, Bg_H, uv3); }

DeclarePass (Noise_H)
{ return fn_noise (uv3); }

DeclarePass (Blur_1_H)
{ return fn_blur_X (Noise_H, uv3); }

DeclarePass (Blur_H)
{ return fn_blur_Y (Blur_1_H, uv3); }

DeclarePass (Horizontal)
{
   float retval = TransDir ? smoothstep (0.0, 1.0, 1.0 - uv3.x) : smoothstep (0.0, 1.0, uv3.x);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

DeclareEntryPoint (Granulate_H)
{ return fn_main (Fg_H, Bg_H, Super_H, Horizontal, Blur_H, uv3); }

//-----------------------------------------------------------------------------------------//

// technique Granulate Radial

DeclarePass (Fg_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_R)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_R)
{ return fn_keygen (Fg_R, Bg_R, uv3); }

DeclarePass (Noise_R)
{ return fn_noise (uv3); }

DeclarePass (Blur_1_R)
{ return fn_blur_X (Noise_R, uv3); }

DeclarePass (Blur_R)
{ return fn_blur_Y (Blur_1_R, uv3); }

DeclarePass (Radial)
{
   float retval = abs (distance (uv3, 0.5.xx)) * SQRT_2;

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

DeclareEntryPoint (Granulate_R)
{ return fn_main (Fg_R, Bg_R, Super_R, Radial, Blur_R, uv3); }

//-----------------------------------------------------------------------------------------//

// technique Granulate Flat

DeclarePass (Fg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_F)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_F)
{ return fn_keygen (Fg_F, Bg_F, uv3); }

DeclarePass (Noise_F)
{ return fn_noise (uv3); }

DeclarePass (Blur_1_F)
{ return fn_blur_X (Noise_F, uv3); }

DeclarePass (Blur_F)
{ return fn_blur_Y (Blur_1_F, uv3); }

DeclareEntryPoint (Granulate_F)
{
   float noise  = tex2D (Blur_F, ((uv3 - 0.5) / pSize) + 0.5).x;
   float amount = saturate (((Amount - 0.5) * 2.0) + noise);

   float4 Fgnd = tex2D (Super_F, uv3);
   float4 retval;

   if (Ttype == 0) { retval = lerp (tex2D (Fg_F, uv3), Fgnd, Fgnd.a * amount); }
   else {
      float amt = Ttype == 1 ? amount : 1.0 - amount;

      retval = lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a * amt);
   }

   if (Sparkles) {
      amount = 0.5 - abs (amount - 0.5);

      float stars = saturate ((pow (amount, 3.0) * 4.0) + amount);

      retval = lerp (retval, starColour, stars * Fgnd.a);
   }

   return retval;
}

