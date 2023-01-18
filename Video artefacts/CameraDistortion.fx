// @Maintainer jwrl
// @Released 2023-01-18
// @Author jwrl
// @Created 2023-01-18

/**
 Camera distortions adds colour fringing effects, pincushion distortion, scaling and
 anamorphic adjustment to an image.  The centre of action of the effect can also be
 adjusted.  It can be used to simulate camera distortion or possibly even correct it,
 and can also be used as an effect in its own right.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CameraDistortion.fx
//
// This effect was suggested by CubicLensDistortion.fx by Lightworks user brdloush.
// This implementation is my own, based on the cubic lens distortion algorithm from
// SSontech (Syntheyes) - http://www.ssontech.com/content/lensalg.htm
// 
//     r2 = image_aspect*image_aspect*u*u + v*v
//     f = 1 + r2*(k + kcube*sqrt(r2))
//     u' = f*u
//     v' = f*v
//
// Although brdloush's version was based on code published by Francois Tarlier in 2010,
// this version re-implements the original Ssontech algorithm, and uses none of
// M. Tarlier's code.  I have not maintained the variable names used in the original
// algorithm, but the code should be clear enough to identify them.
//
// The most notable difference is the use of float2 variables for screen coordinate
// mathematics wherever possible.  This means that some parts require indexing where
// they didn't in the original algorithm.  It also means that overall the code is much
// simpler and will execute faster.  For example the last two lines shown above can
// now be expressed as a single line, viz:
//
//     uv'= f*uv
//
// which executes as a single function but is equivalent to
//
//     uv'.x = f*uv.x
//     uv'.y = f*uv.y
//
// The centring function is additional to any of the published work as far as I'm
// aware, and is entirely my own.  Also new is a means of automatically scaling the
// image while using the basic distortion.  This only applies to positive values of
// the basic distortion and doesn't apply at all to cubic distortion.
//
// I understand that one implementation of this algorithm had chromatic aberration
// correction.  I've done something similar, providing both optical and electronic
// aberrations.  As far as I'm aware these are both original work.
//
// Optical color artefacts are applied prior to distortion, and electronic artefacts
// are applied after it.  This ensures that lens fringing stays inside the image
// boundary while colour registration errors affect the whole frame.
//
// All of the above notwithstanding, you can do what you will with this effect.  It
// would be nice to be credited if you decide to use it elsewhere or change it in
// any way - jwrl.
//
// Version history:
//
// Built 2023-01-18 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Camera distortion", "Stylize", "Video artefacts", "Simulates a range of digital camera distortion artefacts", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (DistortScale, "Enable basic distortion autoscaling", "Distortion", false);

DeclareFloatParam (BasicDistortion, "Basic", "Distortion", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (CubicDistortion, "Cubic", "Distortion", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Scale, "Scale", "Distortion", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (AnamorphicDistortion, "Anamorphic", "Distortion", kNoFlags, 0.0, -1.0, 1.0);

DeclareIntParam (SetTechnique, "Camera type", "Chromatic aberration", 0, "Single chip|Single chip (portrait)|Three chip|Three chip (portrait)");
DeclareFloatParam (OpticalErrors, "Optical errors", "Chromatic aberration", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (ElectronicErrors, "Electronic errors", "Chromatic aberration", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Xcentre, "Centre", "Effect position", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Centre", "Effect position", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define STEPS     12
#define FRNG_INC  1.0/STEPS

#define DICHROIC  0.01
#define CHIP_ERR  0.0025
#define DISTORT   0.35355339

#define HORIZ     true
#define VERT      false

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_lens (sampler S, float2 uv)
{
   float4 retval = tex2D (S, uv);

   if (OpticalErrors != 0.0) {
      retval.rgb = 0.0.xxx;

      float2 centre = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy1 = uv - centre;
      float2 fringe, xy2;

      float fringing = 0.0;
      float strength = 1.0;
      float str_diff = (OpticalErrors / 100.0) * length (xy1);

      for (int i = 0; i < STEPS; i++) {
         xy2 = (xy1 * strength) + centre;
         fringe = tex2D (S, xy2).rg / STEPS;

         retval.rg += fringe * float2 (1.0 - fringing, fringing);

         fringing += FRNG_INC;
         strength -= str_diff;
      }

      for (int i = 0; i < STEPS; i++) {
         xy2 = (xy1 * strength) + centre;
         fringe = ReadPixel (S, xy2).gb / STEPS;

         retval.gb += fringe * float2 (2.0 - fringing, fringing - 1.0);

         fringing += FRNG_INC;
         strength -= str_diff;
      }

      for (int i = 0; i < STEPS; i++) {
         xy2 = (xy1 * strength) + centre;
         fringe = ReadPixel (S, xy2).rb / STEPS;

         retval.rb += fringe * float2 (fringing - 2.0, 3.0 - fringing);

         fringing += FRNG_INC;
         strength -= str_diff;
      }
   }

   return retval;
}

float4 fn_distort (sampler S, float2 xy)
{
   float autoscale [] = { 1.0,    0.8249, 0.7051, 0.6175, 0.5478, 0.4926, 0.4462,
                          0.4093, 0.3731, 0.3476, 0.3243, 0.3039, 0.286,  0.2707,
                          0.2563, 0.2435, 0.2316, 0.2214, 0.2116, 0.2023, 0.1942 };

   if (BasicDistortion || CubicDistortion || AnamorphicDistortion) {
      float sa, sb = (Scale * ((Scale / 2.0) - 1.0)) + 0.5;

      sb += pow (max (0.0, -Scale) * DISTORT, 2.0);

      if (DistortScale) {
         float a_s0 = saturate (BasicDistortion) * 20;
         float a_s1 = floor (a_s0);
         float a_s2 = ceil (a_s0);

         sa = autoscale [a_s1];

         if (a_s1 != a_s2) {
            a_s0 -= a_s1;
            a_s0  = sqrt (a_s0 / 9) + (0.666667 * a_s0);
            sa = lerp (sa, autoscale [a_s2], a_s0);
         }
      }
      else sa = 1.0;

      float2 centre = float2 (Xcentre, 1.0 - Ycentre);
      float2 sf = max (0.0, float2 (AnamorphicDistortion, -AnamorphicDistortion));

      xy = 2.0 * (xy - centre);
      sf = (sb.xx - (sf * sf * DISTORT)) * xy * sa;

      float r = _OutputAspectRatio * _OutputAspectRatio * xy.x * xy.x + xy.y * xy.y;
      float f = CubicDistortion ? 1.0 + (r * (BasicDistortion + (CubicDistortion * sqrt (r))))
                                : 1.0 + (r * BasicDistortion);
      xy = (sf * f) + centre;
   }

   return ReadPixel (S, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Single chip landscape

DeclarePass (Inp_SH)
{ return fn_lens (Inp, uv1); }

DeclarePass (Distort_SH)
{ return fn_distort (Inp_SH, uv2); }

DeclareEntryPoint (CameraDistortion_Single_H)
{
   if (ElectronicErrors == 0.0) return tex2D (Distort_SH, uv2);

   float offset = (ElectronicErrors * CHIP_ERR) / _OutputAspectRatio;

   float2 xy1 = float2 (uv2.x - offset, uv2.y);
   float2 xy2 = float2 (uv2.x + offset, uv2.y);

   float4 retval = tex2D (Distort_SH, xy1);

   retval.g = tex2D (Distort_SH, xy2).g;

   return retval;
}

//Single chip portrait

DeclarePass (Inp_SV)
{ return fn_lens (Inp, uv1); }

DeclarePass (Distort_SV)
{ return fn_distort (Inp_SV, uv2); }

DeclareEntryPoint (CameraDistortion_Single_V)
{
   if (ElectronicErrors == 0.0) return tex2D (Distort_SV, uv2);

   float offset = ElectronicErrors * CHIP_ERR;

   float2 xy1 = float2 (uv2.x, uv2.y - offset);
   float2 xy2 = float2 (uv2.x, uv2.y + offset);

   float4 retval = tex2D (Distort_SV, xy1);

   retval.g = tex2D (Distort_SV, xy2).g;

   return retval;
}

//Three chip landscape

DeclarePass (Inp_DH)
{ return fn_lens (Inp, uv1); }

DeclarePass (Distort_DH)
{ return fn_distort (Inp_DH, uv2); }

DeclareEntryPoint (CameraDistortion_Dichroic_H)
{
   float4 retval = tex2D (Distort_DH, uv2);

   if (ElectronicErrors != 0.0) {
      float offset = (ElectronicErrors * DICHROIC) / _OutputAspectRatio;

      float2 xy1 = float2 (uv2.x + offset, uv2.y);
      float2 xy2 = float2 (uv2.x - offset, uv2.y);

      retval.r = tex2D (Distort_DH, xy1).r;
      retval.b = tex2D (Distort_DH, xy2).b;
   }

   return retval;
}

//Three chip portrait

DeclarePass (Inp_DV)
{ return fn_lens (Inp, uv1); }

DeclarePass (Distort_DV)
{ return fn_distort (Inp_DV, uv2); }

DeclareEntryPoint (CameraDistortion_Dichroic_V)
{
   float4 retval = tex2D (Distort_DV, uv2);

   if (ElectronicErrors != 0.0) {
      float offset = ElectronicErrors * DICHROIC;

      float2 xy1 = float2 (uv2.x, uv2.y - offset);
      float2 xy2 = float2 (uv2.x, uv2.y + offset);

      retval.r = tex2D (Distort_DV, xy1).r;
      retval.b = tex2D (Distort_DV, xy2).b;
   }

   return retval;
}

