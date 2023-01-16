// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This blur effect mimics the classic "petroleum jelly on the lens" look.  It does this by
 combining a radial and a spin blur effect.  The spin component has an adjustable aspect
 ratio which can have significant effect on the final look.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftFoggyBlur.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Soft foggy blur", "Stylize", "Blurs and sharpens", "This blur effect mimics the classic 'petroleum jelly on the lens' look", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Strength, "Blur strength", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Aspect, "Spin aspect 1:x", kNoGroup, kNoFlags, 1.0, 0.2, 5.0);
DeclareFloatParam (CentreX, "Blur centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Blur centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DIV_1    18.5
#define DIV_2    18.975

#define SCALE_1  0.0027777778    // 0.1 / 36
#define SCALE_2  0.0009259259    // 0.1 / 108
#define SCALE_3  0.0096962736    // PI / 324

#define W_DIFF_1 0.0277777778
#define W_DIFF_2 0.0555555556

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input)
{ return ReadPixel (Inp, uv1); }

DeclarePass (Blur_1)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv1)) return retval;

   if (Strength <= 0.0) return ReadPixel (Inp, uv1);

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv1 - center;

   float S = Strength * SCALE_1;
   float Scale = 1.0;
   float weight = 1.0;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += mirror2D (Inp, xy + center) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIV_1;
}

DeclarePass (Blur_2)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv1)) return retval;

   if (Strength <= 0.0) return ReadPixel (Inp, uv1);

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv1 - center;

   float S  = Strength * SCALE_2;
   float Scale = 1.0;
   float weight = 1.0;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += mirror2D (Blur_1, xy + center) * weight;
      weight -= W_DIFF_1;
      Scale  -= S;
   }

   return retval / DIV_1;
}

DeclarePass (FogBlur)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv1)) return retval;

   if (Strength <= 0.0) return ReadPixel (Inp, uv1);

   float spin   = Strength * SCALE_3;
   float weight = 1.0;
   float angle  = 0.0;
   float C, S;

   float2 blur_aspect = float2 (1.0, max (Aspect, 0.0001)) * _OutputAspectRatio;
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

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1));
}

