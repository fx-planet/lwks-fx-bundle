// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect performs a blurred transition between two sources.  It has been designed from
 the ground up to handle mixtures of varying frame sizes and aspect ratios.  To this end,
 it has been tested with a range of rotated camera phone videos, as well as professional
 standard camera formats.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Blur_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Blur dissolve", "Mix", "Blur transitions", "Uses a blur to transition between two video sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Blurriness, "Blurriness", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI        3.1415926536

#define STRENGTH  0.005

#define SAMPLES   30
#define SAMPSCALE 61

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Mixed)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   return lerp (Fgnd, Bgnd, saturate (Amount + Amount - 0.5));
}

DeclarePass (BlurX)
{
   float4 retval = tex2D (Mixed, uv3);

   if (Blurriness > 0.0) {

      float amount = sin (saturate (Amount) * PI) * Blurriness * STRENGTH / _OutputAspectRatio;

      float2 blur = float2 (amount, 0.0);
      float2 xy1 = uv3, xy2 = uv3;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (Mixed, xy1);
         retval += tex2D (Mixed, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

DeclareEntryPoint (Blur_Dx)
{
   float4 retval = tex2D (BlurX, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, sin (saturate (Amount) * PI) * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (BlurX, xy1);
         retval += tex2D (BlurX, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   return retval;
}

