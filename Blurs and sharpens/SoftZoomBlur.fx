// @Maintainer jwrl
// @Released 2023-01-06
// @Author jwrl
// @Released 2023-01-06

/**
 This blur effect is similar to the Lightworks radial blur effect, but is very much
 softer in the result that it can produce.  The blur length range is also much greater
 than that provided by the Lightworks effect.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftZoomBlur.fx
//
// Version history:
//
// Built 2023-01-06 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Soft zoom blur", "Stylize", "Blurs and Sharpens", "Similar to the Lightworks radial blur effect but very much softer", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Length, "Blur length", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
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

#define DIVISOR 18.5

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define W_DIFF  0.0277778

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

float4 fn_blur (sampler I, sampler B, float2 uv, int scale)
{
   float4 retval = kTransparentBlack;

   if (IsOutOfBounds (uv)) return retval;

   if (Length == 0.0) return ReadPixel (I, uv);

   float2 center = float2 (CentreX, 1.0 - CentreY);
   float2 xy = uv - center;

   float S = (Length * 0.1) / scale;
   float Scale = 1.0;
   float weight = WEIGHT;

   for (int i = 0; i < 36; i++) {
      xy *= Scale;
      retval += mirror2D (B, xy + center) * weight;
      weight -= W_DIFF;
      Scale  -= S;
   }

   return retval / DIVISOR;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Blur_1)
{ return fn_blur (Inp, Inp, uv1, SCALE_1); }

DeclarePass (Blur_2)
{ return fn_blur (Inp, Blur_1, uv1, SCALE_2); }

DeclarePass (Blur_3)
{ return fn_blur (Inp, Blur_2, uv1, SCALE_3); }

DeclareEntryPoint (SoftZoomBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float offset = 0.7 - (Length / 2.7777778);
   float adjust = 1.0 + (Length / 1.5);

   float4 blurry = tex2D (Blur_3, uv1);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1));
}

