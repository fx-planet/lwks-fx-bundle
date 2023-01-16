// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect performs a transition between two sources.  During the process it also applies
 a directional blur, the angle and strength of which can be fully adjusted.  It has been
 designed from the ground up to handle mixtures of varying frame sizes and aspect ratios.
 To this end, it has been tested with a range of rotated camera phone videos, as well as
 professional standard camera formats.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalBlur_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Directional blur dissolve", "Mix", "Blur transitions", "Uses a directional blur to transition between two sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Spread, "Spread", "Blur settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle, "Angle", "Blur settings", kNoFlags, 0.0, -180.0, 180.0);
DeclareFloatParam (Strength, "Strength", "Blur settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI        3.1415926536

#define SAMPLES   30
#define SAMPSCALE 61

#define STRENGTH  0.005

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Mixed)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float amount = pow (1.0 - (abs (Amount - 0.5) * 2.0), 1.0 + (Strength * 8.0)) / 2.0;

   if (Amount > 0.5) amount = 1.0 - amount;

   return lerp (Fgnd, Bgnd, amount);
}

DeclareEntryPoint (DirectionalBlur_Dx)
{
   float4 retval = tex2D (Mixed, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle), blur.y, blur.x);
      blur   *= sin (saturate (Amount) * PI) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (Mixed, xy1);
         retval += tex2D (Mixed, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

