// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Created 2023-01-23

/**
 This blur effect is similar to the Lightworks radial blur effect, but is very much
 softer in the result that it can produce.  The blur length range is also much greater
 than that provided by the Lightworks effect.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftBlurs.fx
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Soft blurs", "Stylize", "Blurs and sharpens", "A selection of soft blurs", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Blur type", kNoGroup, 0, "Foggy rays|Motion blur|Spin|Zoom blur);

DeclareFloatParam (Strength, "Blur strength", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Angle, "Blur rotation", kNoGroup, kNoFlags, 0.0, -180.0, 180.0);
DeclareFloatParam (Aspect, "Aspect ratio", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (CentreX, "Blur centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Blur centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define STEPS   18

#define DIVISOR  18.5
#define DIV_2    18.975

#define SCALE_1  36
#define SCALE_2  108
#define SCALE_3  324

#define SCINV_1  0.0027777778    // 0.1 / 36
#define SCINV_2  0.0009259259    // 0.1 / 108
#define SCINV_3  0.0096962736    // PI / 324

#define WEIGHT   1.0
#define W_DIFF_1 0.0277778
#define W_DIFF_2 0.0555555556

#define PI       3.1415927

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

float4 fn_zoomblur (sampler I, sampler B, float2 uv, int scale)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv)) return retval;

   if (Strength == 0.0) return ReadPixel (I, uv);

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv - center;

   float S = (Strength * 0.1) / scale;
   float Scale = 1.0;
   float weight = WEIGHT;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += mirror2D (B, xy + center) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIVISOR;
}

float4 fn_spinblur (sampler I, sampler B, float2 uv, int scale)
{
   float4 retval = kTransparentBlack;

   float Arc = Angle + 45.0;

   if (IsOutOfBounds (uv)) return retval;

   if (Arc <= 0.0) return ReadPixel (I, uv);

   float spin   = radians (Arc) / scale;
   float weight = WEIGHT;
   float angle  = 0.0;
   float C, S;

   float2 blur_aspect  = float2 (1.0, (1.0 - (max (Aspect, 0.0) * 0.8) - (min (Aspect, 0.0) * 4.0)) * _OutputAspectRatio);
   float2 fxCentre = float2 (CentreX, 1.0 - CentreY);
   float2 xy = (uv - fxCentre) / blur_aspect;
   float2 xy1, xy2, xyC, xyS;

   for (int i = 0; i < STEPS; i++) {
      sincos (angle, S, C);

      xyC = xy * C;
      xyS = float2 (xy.y, -xy.x) * S;
      xy1 = (xyC + xyS) * blur_aspect + fxCentre;
      xy2 = (xyC - xyS) * blur_aspect + fxCentre;

      retval += ((mirror2D (B, xy1) + mirror2D (B, xy2)) * weight);

      weight -= W_DIFF_2;
      angle  += spin;
   }

   return retval / DIVISOR;
}

float4 fn_motionblur (sampler B, float2 uv, int scale)
{
   if (IsOutOfBounds (uv)) return kTransparentBlack;

   if (Strength == 0.0) return ReadPixel (B, uv);

   float S, C, weight = WEIGHT;

   sincos (PI * (Angle + 180.0) / 180.0, S, C);

   float2 xy1 = uv;
   float2 xy2 = float2 (-C, -S * _OutputAspectRatio) * (Strength / scale);

   float4 retval = kTransparentBlack;

   for (int i = 0; i < 36; i++) {
      retval += mirror2D (B, xy1) * weight;
      weight -= W_DIFF_1;
      xy1 += xy2;
   }

   return retval / DIVISOR;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//------------------------------------ Soft Foggy Blur ------------------------------------//

DeclarePass (Blur_1)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv1)) return retval;

   if (Strength <= 0.0) return ReadPixel (Inp, uv1);

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv1 - center;

   float S = Strength * SCINV_1;
   float Scale = 1.0;
   float weight = 1.0;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += mirror2D (Inp, xy + center) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIVISOR;
}

DeclarePass (Blur_2)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv1)) return retval;

   if (Strength <= 0.0) return ReadPixel (Inp, uv1);

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv1 - center;

   float S  = Strength * SCINV_2;
   float Scale = 1.0;
   float weight = 1.0;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += mirror2D (Blur_1, xy + center) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIVISOR;
}

DeclarePass (FogBlur)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv1)) return retval;

   if (Strength <= 0.0) return ReadPixel (Inp, uv1);

   float spin   = Strength * SCINV_3;
   float weight = 1.0;
   float angle  = 0.0;
   float ratio  = lerp (lerp (1.0, 0.2, max (0.0, Aspect)), 5.0, max (0.0, -Aspect));
   float C, S;

   float2 blur_aspect = float2 (1.0, max (ratio, 0.0001)) * _OutputAspectRatio;
   float2 fxCentre = float2 (CentreX, 1.0 - CentreY);
   float2 xy = (uv1 - fxCentre) / blur_aspect;
   float2 xy1, xy2, xyC, xyS;

   for (int i = 0; i < 18; i++) {
      sincos (angle, S, C);

      xyC = xy * C;
      xyS = float2 (xy.y, -xy.x) * S;
      xy1 = (xyC + xyS) * blur_aspect + fxCentre;
      xy2 = (xyC - xyS) * blur_aspect + fxCentre;

      retval += ((mirror2D (Blur_2, xy1) + mirror2D (Blur_2, xy2)) * weight);

      weight -= W_DIFF_2;
      angle  += spin;
   }

   return retval / DIV_2;
}

DeclareEntryPoint (SoftFoggyBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float offset = 0.7 - (Strength / 2.7777778);
   float adjust = 1.0 + (Strength / 1.5);

   float4 blurry = tex2D (FogBlur, uv1);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1).x);
}

//----------------------------------- Soft Motion Blur ------------------------------------//

DeclarePass (mBlur_1)
{ return fn_motionblur (Inp, uv1, SCALE_1); }

DeclarePass (mBlur_2)
{ return fn_motionblur (mBlur_1, uv1, SCALE_2); }

DeclarePass (MotionBlur)
{ return fn_motionblur (mBlur_2, uv1, SCALE_3); }

DeclareEntryPoint (SoftMotionBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float offset = 0.7 - (Strength / 2.7777778);
   float adjust = 1.0 + (Strength / 1.5);

   float4 blurry = tex2D (MotionBlur, uv1);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1).x);
}

//------------------------------------- Soft Spin Blur ------------------------------------//

DeclarePass (sBlur_1)
{ return fn_spinblur (Inp, Inp, uv1, SCALE_1); }

DeclarePass (sBlur_2)
{ return fn_spinblur (Inp, sBlur_1, uv1, SCALE_2); }

DeclarePass (SpinBlur)
{ return fn_spinblur (Inp, sBlur_2, uv1, SCALE_3); }

DeclareEntryPoint (SoftSpinBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float offset = 0.625 - (Angle / 600);
   float adjust = 1.16666667 + (Angle / 270.0);

   float4 retval = tex2D (SpinBlur, uv1);
   float4 repair = float4 (((retval.rgb - offset.xxx) * adjust) + offset.xxx, retval.a);

   retval = lerp (retval, repair, Strength);

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1).x);
}

//------------------------------------- Soft Zoom Blur ------------------------------------//

DeclarePass (zBlur_1)
{ return fn_zoomblur (Inp, Inp, uv1, SCALE_1); }

DeclarePass (zBlur_2)
{ return fn_zoomblur (Inp, zBlur_1, uv1, SCALE_2); }

DeclarePass (zBlur_3)
{ return fn_zoomblur (Inp, zBlur_2, uv1, SCALE_3); }

DeclareEntryPoint (SoftZoomBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float offset = 0.7 - (Strength / 2.7777778);
   float adjust = 1.0 + (Strength / 1.5);

   float4 blurry = tex2D (zBlur_3, uv1);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1).x);
}

