// @Maintainer jwrl
// @Released 2023-01-06
// @Author jwrl
// @Released 2023-01-06

/**
 This blur is actually a simple directional blur.  It is extremely soft because it uses a
 radially-sampled blur engine.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftMotionBlur.fx
//
// Version history:
//
// Built 2023-01-06 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Soft motion blur", "Stylize", "Blurs and Sharpens", "This effect gives a very smooth, soft directional blur", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Length, "Blur length", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Angle, "Blur direction", kNoGroup, kNoFlags, 180.0, 0.0, 360.0);
DeclareFloatParam (Amount, "Blur density", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DIVISOR 18.5

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define W_DIFF  0.0277778

#define PI      3.1415927

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

float4 fn_blur (sampler B, float2 uv, int scale)
{
   float S, C, weight = WEIGHT;

   sincos (PI * (Angle / 180.0), S, C);

   float2 xy1 = uv;
   float2 xy2 = float2 (-C, -S * _OutputAspectRatio) * (Length / scale);

   float4 retval = kTransparentBlack;

   for (int i = 0; i < 36; i++) {
      retval += mirror2D (B, xy1) * weight;
      weight -= W_DIFF;
      xy1 += xy2;
   }

   return retval / DIVISOR;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input)
{ return ReadPixel (Inp, uv1); }

DeclarePass (Blur_1)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   if (Length == 0.0) return ReadPixel (Inp, uv1);

   return fn_blur (Inp, uv1, SCALE_1);
}

DeclarePass (Blur_2)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   if (Length == 0.0) return ReadPixel (Inp, uv1);

   return fn_blur (Blur_1, uv1, SCALE_2);
}

DeclarePass (MotionBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   if (Length == 0.0) return ReadPixel (Inp, uv1);

   return fn_blur (Blur_2, uv1, SCALE_3);
}

DeclareEntryPoint (SoftMotionBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float offset = 0.7 - (Length / 2.7777778);
   float adjust = 1.0 + (Length / 1.5);

   float4 blurry = tex2D (MotionBlur, uv1);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1));
}

