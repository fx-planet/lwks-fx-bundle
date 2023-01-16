// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 A directional unsharp mask.  Useful where directional stretching and motion blur must be
 compensated for.  The angle can only be adjusted through 180 degrees, because it uses a
 bidirectional blur.  Using that technique, 90 degrees and 270 degrees would give identical
 results.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalSharpen.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Directional sharpen", "Stylize", "Blurs and sharpens", "This is a directional unsharp mask useful where directional blurring must be compensated for", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (BlurAngle, "Blur angle", kNoGroup, kNoFlags, 0.0, 0.0, 180.0);
DeclareFloatParam (BlurWidth, "Sample width", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Threshold, "Threshold", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Tolerance, "Tolerance", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EdgeGain, "Edge gain", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMA_DOT  float3(1.1955,2.3464,0.4581)
#define GAMMA_VAL 1.666666667

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

DeclareEntryPoint (DirectionalSharpen)
{
   float4 unblur = kTransparentBlack;

   if (IsOutOfBounds (uv1)) return unblur;

   float4 retval = tex2D (Inp, uv1);

   float2 offset, xy = uv1;

   if (BlurWidth <= 0.0) return retval;

   sincos (radians (BlurAngle), offset.y, offset.x);
   offset *= (BlurWidth * 0.0005);
   offset.y *= _OutputAspectRatio;

   xy += offset * 30.0;

   for (int i = 0; i < 60; i++) {
      unblur += mirror2D (Inp, xy);
      xy -= offset;
   }
    
   unblur /= 60.0;

   float sharpMask = dot (retval.rgb, LUMA_DOT);
   float maskGamma = min (1.15, 1.1 - min (1.05, EdgeGain)) * GAMMA_VAL;
   float maskGain  = Tolerance * 2.0;

   sharpMask -= dot (unblur.rgb, LUMA_DOT);
   maskGamma *= maskGamma;

   float sharpness = pow (max (0.0, sharpMask - Threshold), maskGamma);

   sharpness -= pow (max (0.0, -sharpMask - Threshold), maskGamma);
   sharpness *= maskGain;

   unblur = float4 (retval.rgb + sharpness.xxx, retval.a);

   return lerp (retval, unblur, tex2D (Mask, uv1));
}

