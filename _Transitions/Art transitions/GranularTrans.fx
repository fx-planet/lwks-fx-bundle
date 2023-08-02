// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2016-02-08

/**
 This effect uses a granular noise driven pattern to transition into or out of an image
 The noise component is based on work by users khaver and windsturm.  The radial gradient
 part is from an effect provided by LWKS Software Ltd.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GranularTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-12 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Granular transition", "Mix", "Art transitions", "Uses a granular noise driven pattern to transition between clips", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition type", kNoGroup, 1, "Top to bottom|Left to right|Radial|No gradient");
DeclareBoolParam (TransDir, "Invert transition direction", kNoGroup, false);
DeclareFloatParam (gWidth, "Width", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (pSize, "Size", "Particles", kNoFlags, 5.5, 1.0, 10.0);
DeclareFloatParam (pSoftness, "Softness", "Particles", kNoFlags, 0.5, 0.0, 1.0);
DeclareBoolParam (TransVar, "Static particle pattern", "Particles", false);
DeclareBoolParam (Sparkles, "Sparkle", "Particles", false);
DeclareColourParam (starColour, "Colour", "Particles", kNoFlags, 0.9, 0.75, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

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

float4 fn_noise (float2 uv)
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000.0;

   return saturate (frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0).xxxx;
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

float4 fn_main (sampler F, sampler B, sampler G, sampler S, float2 xy)
{
   float4 Fgnd = tex2D (F, xy);     // Outgoing
   float4 Bgnd = tex2D (B, xy);     // Incoming
   float4 maskBg, retval;

   float4 grad  = tex2D (G, xy);                          // Gradient
   float4 noise = tex2D (S, ((xy - 0.5) / pSize) + 0.5);  // Soft

   float stars, level = saturate (((0.5 - grad.x) * 2) + noise);

   if (Blended) {
      if (ShowKey) {
         retval = lerp (kTransparentBlack, Fgnd, Fgnd.a);
         maskBg = kTransparentBlack;
      }
      else {
         retval = lerp (Fgnd, Bgnd, level);

         if (Sparkles) {
            if (level > 0.5) level = 0.5 - level;

            stars = saturate ((pow (level, 3.0) * 4.0) + level);
            retval = lerp (retval, starColour, stars);
         }

         maskBg = Bgnd;
         retval = lerp (maskBg, retval, Fgnd.a);
      }
   }
   else {
      maskBg = Fgnd;
      retval = lerp (Fgnd, Bgnd, level);

      if (Sparkles) {
         if (level > 0.5) level = 0.5 - level;

         stars = saturate ((pow (level, 3.0) * 4.0) + level);
         retval = lerp (retval, starColour, stars);
      }
   }

   return lerp (maskBg, retval, tex2D (Mask, xy).x);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Granulate Vertical

DeclarePass (Fg_V)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_V)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Gradient_V)                  // Buffer_0
{
   float amount, direction;

   if (Blended) {
      if (SwapDir) {
         amount = 1.0 - Amount;
         direction = uv3.y;
      }
      else {
         amount = Amount;
         direction = 1.0 - uv3.y;
      }

      if (!TransDir) direction = 1.0 - direction;
   }
   else {
      amount = Amount;
      direction = TransDir ? 1.0 - uv3.y : uv3.y;
   }

   float retval = smoothstep (0.0, 1.0, direction);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * amount))) + ((0.5 - amount) * 2.0));

   return retval.xxxx;
}

DeclarePass (Noise_V)                     // Buffer_1
{ return fn_noise (uv3); }

DeclarePass (Preblur_V)                   // Buffer_2
{ return fn_blur_X (Noise_V, uv3); }

DeclarePass (Soft_V)                      // Buffer_3
{ return fn_blur_Y (Preblur_V, uv3); }

DeclareEntryPoint (Granulate_V)
{ return fn_main (Fg_V, Bg_V, Gradient_V, Soft_V, uv3); }

//-----------------------------------------------------------------------------------------//

// technique Granulate Horizontal

DeclarePass (Fg_H)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_H)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Gradient_H)
{
   float amount, direction;

   if (Blended) {
      if (SwapDir) {
         amount = 1.0 - Amount;
         direction = 1.0 - uv3.x;
      }
      else {
         amount = Amount;
         direction = uv3.x;
      }

      if (TransDir) direction = 1.0 - direction;
   }
   else {
      amount = Amount;
      direction = TransDir ? 1.0 - uv3.x : uv3.x;
   }

   float retval = smoothstep (0.0, 1.0, direction);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * amount))) + ((0.5 - amount) * 2.0));

   return retval.xxxx;
}

DeclarePass (Noise_H)                     // Buffer_1
{ return fn_noise (uv3); }

DeclarePass (Preblur_H)                   // Buffer_2
{ return fn_blur_X (Noise_H, uv3); }

DeclarePass (Soft_H)                      // Buffer_3
{ return fn_blur_Y (Preblur_H, uv3); }

DeclareEntryPoint (Granulate_H)
{ return fn_main (Fg_H, Bg_H, Gradient_H, Soft_H, uv3); }

//-----------------------------------------------------------------------------------------//

// technique Granulate Radial

DeclarePass (Fg_R)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Gradient_R)
{
   float amount, retval = abs (distance (uv3, 0.5.xx)) * SQRT_2;

   if (Blended) {
      if (SwapDir) {
         amount = 1.0 - Amount;
         retval = 1.0 - retval;
      }
      else amount = Amount;

      if (TransDir) retval = 1.0 - retval;
   }
   else {
      amount = Amount;
      if (TransDir) retval = 1.0 - retval;
   }

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * amount))) + ((0.5 - amount) * 2.0));

   return retval.xxxx;
}

DeclarePass (Noise_R)                     // Buffer_1
{ return fn_noise (uv3); }

DeclarePass (Preblur_R)                   // Buffer_2
{ return fn_blur_X (Noise_R, uv3); }

DeclarePass (Soft_R)                      // Buffer_3
{ return fn_blur_Y (Preblur_R, uv3); }

DeclareEntryPoint (Granulate_R)
{ return fn_main (Fg_R, Bg_R, Gradient_R, Soft_R, uv3); }

//-----------------------------------------------------------------------------------------//

// technique Granulate Flat

DeclarePass (Fg_F)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_F)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Noise_F)
{ return fn_noise (uv3); }

DeclarePass (Blur_1_F)
{ return fn_blur_X (Noise_F, uv3); }

DeclarePass (Blur_F)
{ return fn_blur_Y (Blur_1_F, uv3); }

DeclareEntryPoint (Granulate_F)
{
   float4 Fgnd = tex2D (Fg_F, uv3);
   float4 Bgnd = tex2D (Bg_F, uv3);
   float4 MaskBg, retval;

   float amount;

   if (Blended) {
      if (ShowKey) {
         retval = lerp (kTransparentBlack, Fgnd, Fgnd.a);

         return lerp (kTransparentBlack, retval, tex2D (Mask, uv3).x);
      }

      amount = SwapDir ? 1.0 - Amount : Amount;
      MaskBg = Bgnd;
   }
   else {
      amount = Amount;
      MaskBg = Fgnd;
   }

   if (Fgnd.a > 0.0 ) {
      float noise  = tex2D (Blur_F, ((uv3 - 0.5) / pSize) + 0.5).x;
      float stars;

      amount = saturate (((amount - 0.5) * 2.0) + noise);
      retval = lerp (Fgnd, Bgnd, amount);

      if (amount > 0.5) amount = 0.5 - amount;

      if (Sparkles) {
         stars = saturate ((pow (amount, 3.0) * 4.0) + amount);
         retval = lerp (retval, starColour, stars);
      }
   }
   else retval = Bgnd;

   return lerp (MaskBg, retval, tex2D (Mask, uv3).x);
}

