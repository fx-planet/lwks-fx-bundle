// @Maintainer jwrl
// @Released 2023-01-06
// @Author jwrl
// @Released 2023-01-06

/**
 During the development of this effect particular attention has been given to the blur
 sample rate.  The effect achieves 108 samples by using three consecutive passes of
 36 samples each at finer and finer pitch.  This is an oversampling technique which
 results in a theoretical sample rate of greater than 45,000.  As a result a full 180
 degrees of arc can be blurred without the sampling becoming too obvious even if the
 blur centre is at the corner of the frame.

 The blur arc method used is bi-directional and produces a symmetrical blur.  For
 example, a 30 degree arc is produced by applying dual 15 degree clockwise and anti-
 clockwise blurs.  A level tracking parameter has been included to compensate for the
 inevitable upward drift in blacks and downward drift in whites that such a strong
 blur can cause.

 Blur density reduces the blur effect to zero.  Blur aspect ratio is set in percentage
 change values and swings between 1:5 and 5:1.  The blur centring can be set either by
 means of the sliders or by dragging with the mouse in the edit sequence viewer.  Blurs
 cannot be dragged off screen, but manually entering values will allow this if desired.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftSpinBlur.fx
//
// Version history:
//
// Built 2023-01-06 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Soft spin blur", "Stylize", "Blurs and Sharpens", "This effect uses a bidirectional blur to give an extremely smooth spin blur", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Arc, "Blur arc degrees", kNoGroup, kNoFlags, 45.0, 0.0, 180.0);
DeclareFloatParam (Aspect, "Aspect ratio", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (CentreX, "Blur centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Blur centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam (Tracking, "Level tracking", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define STEPS   18
#define DIVISOR 18.975

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define WT_DIFF 0.0555556

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

   if (Arc == 0.0) return ReadPixel (I, uv);

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

      weight -= WT_DIFF;
      angle  += spin;
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

DeclarePass (SpinBlur)
{ return fn_blur (Inp, Blur_2, uv1, SCALE_3); }

DeclareEntryPoint (SoftSpinBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float offset = 0.7 - (Arc / 600.0);
   float adjust = 1.0 + (Arc / 270.0);

   float4 retval = tex2D (SpinBlur, uv1);
   float4 repair = float4 (((retval.rgb - offset.xxx) * adjust) + offset.xxx, retval.a);

   retval = lerp (retval, repair, Tracking);

   return lerp (tex2D (Inp, uv1), retval, tex2D (Mask, uv1));
}

