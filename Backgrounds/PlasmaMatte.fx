// @Maintainer jwrl
// @Released 2023-05-14
// @Author jwrl
// @Created 2018-09-01

/**
 This effect generates soft plasma-like cloud patterns.  Hue, level, saturation, and rate
 of change of the pattern are all adjustable, and the pattern is also adjustable.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PlasmaMatte.fx
//
// Version history:
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Plasma matte", "Mattes", "Backgrounds", "Generates soft plasma clouds", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Rate, "Rate", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Style, "Pattern style", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Scale, "Scale", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Gain, "Pattern gain", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Level, "Level", kNoGroup, kNoFlags, 0.6666666667, 0.0, 1.0);
DeclareFloatParam (Hue, "Hue", kNoGroup, kNoFlags, 0, -180, 180);
DeclareFloatParam (Saturation, "Saturation", kNoGroup, "DisplayAsPercentage", 1.0, 0.0, 2.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RGB_LUMA float3(0.2989, 0.5866, 0.1145)

#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (PlasmaMatte)
{
   float2 xy = uv0;

   if (_OutputAspectRatio <= 1.0) {
      xy.x = (xy.x - 0.5) * _OutputAspectRatio;

      if (_OutputAspectRatio < 1.0) {
         xy.y -= 0.5;
         xy   *= _OutputAspectRatio;
         xy.y += 0.5;
      }

      xy.x += 0.5;
   }
   else {
      xy.y = (xy.y - 0.5) / _OutputAspectRatio;

      if (_OutputAspectRatio < 1.0) {
         xy.x -= 0.5;
         xy   /= _OutputAspectRatio;
         xy.x += 0.5;
      }

      xy.y += 0.5;
   }

   float rate = _LengthFrames * _Progress / (1.0 + ((1.0 - Rate) * 100.0));
   float _hue = (Hue + 180) / 360;

   float2 xy1, xy2, xy3, xy4 = (xy - 0.5.xx) * HALF_PI;

   sincos (xy4, xy3, xy2.yx);

   xy1  = lerp (xy3, xy2, (1.0 + Style) * 0.5) * (5.5 - (Scale * 5.0));
   xy1 += sin (xy1 * HALF_PI + rate.xx).yx;
   xy4  = xy1 * HALF_PI;

   sincos (xy1.x, xy3.x, xy3.y);
   sincos (xy4.x, xy2.x, xy2.y);
   sincos (xy1.y, xy1.x, xy1.y);
   sincos (xy4.y, xy4.x, xy4.y);

   float3 ptrn = (dot (xy2, xy4.xx) + dot (xy1, xy3.yy)).xxx;

   ptrn.y = dot (xy1, xy2.xx) + dot (xy3, xy4.xx);
   ptrn.z = dot (xy2, xy3.yy) + dot (xy1, xy4.yy);
   ptrn  += float3 (_hue, 0.5, 1.0 - _hue) * TWO_PI;

   float3 ret = sin (ptrn) * ((Gain * 0.5) + 0.05);

   ret = saturate (ret + Level.xxx);

   float luma = dot (ret, RGB_LUMA);

   float4 Fgd = ReadPixel (Inp, uv1);
   float4 retval = float4 (lerp (luma.xxx, ret, Saturation), Fgd.a);

   return lerp (Fgd, retval, tex2D (Mask, uv1).x);
}
