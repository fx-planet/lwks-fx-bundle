// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect was created to provide a granular noise driven dissolve.  The noise
 component is based on work by users khaver and windsturm.  The radial gradient part
 is from an effect provided by LWKS Software Ltd.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Granular_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Granular dissolve", "Mix", "Art transitions", "This effect provides a granular noise driven dissolve between shots", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Type", "Particles", 1, "Top to bottom|Left to right|Radial|No gradient");

DeclareBoolParam (TransDir, "Invert transition direction", kNoGroup, false);
DeclareFloatParam (gWidth, "Width", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (pSize, "Size", "Particles", kNoFlags, 5.5, 1.0, 10.0);
DeclareFloatParam (pSoftness, "Softness", "Particles", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (TransVar, "Static particle pattern", "Particles", false);
DeclareBoolParam (Sparkles, "Sparkle", "Particles", false);

DeclareColourParam (starColour, "Colour", "Particles", kNoFlags, 0.9, 0.75, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

// Pascal's triangle magic numbers for blur

#define BLUR_0  0.3125
#define BLUR_1  0.2344
#define BLUR_2  0.09375
#define BLUR_3  0.01563

#define B_SCALE 0.000545

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_noise (float2 uv)
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;

   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000.0;

   return saturate (frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0).xxxx;
}

float4 fn_blur_X (sampler S, float2 uv)
{
   float4 retval = tex2D (S, uv);

   float2 offset_X1 = float2 (pSoftness * B_SCALE, 0.0);
   float2 offset_X2 = offset_X1 * 2.0;
   float2 offset_X3 = offset_X1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (S, uv + offset_X1) * BLUR_1;
   retval += tex2D (S, uv - offset_X1) * BLUR_1;
   retval += tex2D (S, uv + offset_X2) * BLUR_2;
   retval += tex2D (S, uv - offset_X2) * BLUR_2;
   retval += tex2D (S, uv + offset_X3) * BLUR_3;
   retval += tex2D (S, uv - offset_X3) * BLUR_3;

   return retval;
}

float4 fn_blur_Y (sampler S, float2 uv)
{
   float4 retval = tex2D (S, uv);

   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio * B_SCALE);
   float2 offset_Y2 = offset_Y1 * 2.0;
   float2 offset_Y3 = offset_Y1 * 3.0;

   retval *= BLUR_0;
   retval += tex2D (S, uv + offset_Y1) * BLUR_1;
   retval += tex2D (S, uv - offset_Y1) * BLUR_1;
   retval += tex2D (S, uv + offset_Y2) * BLUR_2;
   retval += tex2D (S, uv - offset_Y2) * BLUR_2;
   retval += tex2D (S, uv + offset_Y3) * BLUR_3;
   retval += tex2D (S, uv - offset_Y3) * BLUR_3;

   return retval;
}

float4 fn_main (sampler F, sampler B, sampler G, sampler S, float2 uv)
{
   float4 Fgnd  = tex2D (F, uv);
   float4 Bgnd  = tex2D (B, uv);

   float4 grad  = tex2D (G, uv);
   float4 noise = tex2D (S, ((uv - 0.5) / pSize) + 0.5);

   float level  = saturate (((0.5 - grad.x) * 2) + noise);

   float4 retval = lerp (Fgnd, Bgnd, level);

   if (!Sparkles) return retval;

   if (level > 0.5) level = 0.5 - level;

   float stars = saturate ((pow (level, 3.0) * 4.0) + level);

   return lerp (retval, starColour, stars);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique TopToBottom

DeclarePass (Fgd_V)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_V)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Gradient_V)
{
   float retval = lerp (0.0, 1.0, uv3.y);

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

DeclarePass (Noise_V)
{ return fn_noise (uv3); }

DeclarePass (Preblur_V)
{ return fn_blur_X (Noise_V, uv3); }

DeclarePass (Soft_V)
{ return fn_blur_Y (Preblur_V, uv3); }

DeclareEntryPoint (TopToBottom)
{ return fn_main (Fgd_V, Bgd_V, Gradient_V, Soft_V, uv3); }


// technique LeftToRight

DeclarePass (Fgd_H)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_H)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Gradient_H)
{
   float retval = lerp (0.0, 1.0, uv3.x);

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

DeclarePass (Noise_H)
{ return fn_noise (uv3); }

DeclarePass (Preblur_H)
{ return fn_blur_X (Noise_H, uv3); }

DeclarePass (Soft_H)
{ return fn_blur_Y (Preblur_H, uv3); }

DeclareEntryPoint (LeftToRight)
{ return fn_main (Fgd_H, Bgd_H, Gradient_H, Soft_H, uv3); }


// technique Radial

DeclarePass (Fgd_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_R)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Gradient_R)
{
   float progress = abs (distance (uv3, float2 (0.5, 0.5))) * 1.414;

   float4 pixel = tex2D (Fgd_R, uv3);

   float colOneAmt = 1.0 - progress;
   float colTwoAmt = progress;

   float retval = (lerp (pixel, 0.0, 1.0) * colOneAmt) +
                  (lerp (pixel, 1.0, 1.0) * colTwoAmt) +
                  (pixel * (1.0 - (colOneAmt + colTwoAmt)));

   if (TransDir) retval = 1.0 - retval;

   return saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0)).xxxx;
}

DeclarePass (Noise_R)
{ return fn_noise (uv3); }

DeclarePass (Preblur_R)
{ return fn_blur_X (Noise_R, uv3); }

DeclarePass (Soft_R)
{ return fn_blur_Y (Preblur_R, uv3); }

DeclareEntryPoint (Radial)
{ return fn_main (Fgd_R, Bgd_R, Gradient_R, Soft_R, uv3); }


// technique Flat

DeclarePass (Fgd_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd_F)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Noise_F)
{ return fn_noise (uv3); }

DeclarePass (Preblur_F)
{ return fn_blur_X (Noise_F, uv3); }

DeclarePass (Soft_F)
{ return fn_blur_Y (Preblur_F, uv3); }

DeclareEntryPoint (Flat)
{
   float4 Fgnd = tex2D (Fgd_F, uv3);
   float4 Bgnd = tex2D (Bgd_F, uv3);

   float4 noise = tex2D (Soft_F, ((uv3 - 0.5) / pSize) + 0.5);

   float level = saturate (((Amount - 0.5) * 2) + noise);

   float4 retval = lerp (Fgnd, Bgnd, level);

   if (!Sparkles) return retval;

   if (level > 0.5) level = 0.5 - level;

   float stars = saturate ((pow (level, 3.0) * 4.0) + level);

   return lerp (retval, starColour, stars);
}


