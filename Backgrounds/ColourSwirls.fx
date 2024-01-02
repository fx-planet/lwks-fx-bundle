// @Maintainer jwrl
// @Released 2024-01-02
// @Author jwrl
// @Created 2024-01-02

/**
 Colour swirls is an effect that creates animated swirling colour patterns.  They can
 be used as semi-abstract backgrounds, or mixed over the background input.  Masking
 can also be used to reveal the background.  In actual work it has been masked and used
 with lower thirds to very effectively add interest to the graphic.

 The core of this effect is based on code at https://glslsandbox.com/e#109156.0.
 If I knew who wrote that part I would credit them.  The bulk of the code - speed,
 angle, offset, position, depth, hue, tint, saturation and opacity are all original work
 by me, jwrl.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSwirls.fx
//
// Version history:
//
// Created 2024-01-02 jwrl based on code at https://glslsandbox.com/e#109156.0.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Colour swirls", "Mattes", "Backgrounds", "Generates swirling colour patterns", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (PosX, "Position", "Geometry", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (PosY, "Position", "Geometry", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Angle, "Angle", "Geometry", kNoFlags, 0.0, -180.0, 180.0);
DeclareFloatParam (Offset, "Offset", "Geometry", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Speed, "Speed", "Geometry", kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Dpth, "Depth", "Geometry", 5, "10|20|30|40|50|60|70|80|90|100");

DeclareFloatParam (Gain, "Gain", "Colour", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Hue, "Hue", "Colour", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Satn, "Saturation", "Colour", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (TintAmt, "Tint amount", "Colour", kNoFlags, 0.0, 0.0, 1.0);
DeclareColourParam (TintVal, "Tint colour", "Colour", kNoFlags, 0.375, 0.125, 0.0, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float _o[] = { 0.1375, 0.1275, 0.1168, 0.1995, 0.075, 0.05, 0.0488, 0.0475, 0.0466, 0.045 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Colour_swirls)
{
   float s, c, d = _o [Dpth];
   float time = (_Progress * _Length * lerp (0.0005, 0.01, pow (Speed, 4.0))) + (Offset * d);

   sincos (radians (Angle), s, c);

   float2 xy1, xy2 = uv0 - float2 (PosX, 1.0 - PosY);

   xy2.x *= _OutputAspectRatio;
   xy1 = (c * xy2) + (s * float2 (xy2.y, -xy2.x)) + 0.5.xx;
   xy1.x /= _OutputAspectRatio;
   xy1 = ((2.0 * xy1) - float2 (_OutputAspectRatio, 1.0)) / _OutputAspectRatio;

   int depth = (Dpth + 1) * 10;               // Colour swirls - default is 60.

   for (int i = 1; i < depth; i++) {
      float2 xy0 = xy1 + time;

      float j = float (i);

      xy0.x += (0.5 / j) * sin ((j * xy1.y) + time + (0.2 * j)) + 0.2;
      xy0.y += (0.4 / j) * sin ((j * xy1.x) + time + (0.3 * (j + 10.0))) - 0.8;

      xy1 = xy0;
   }

   float4 hsva, retval = 1.0.xxxx;
   float4 Bgnd = ReadPixel (Inp, uv1);

   float g_1 = saturate (Gain) * 2.0;
   float g_2 = max (0.0, g_1 - 1.0);

   retval.rgb = (float3 (sin (xy1 * 3.0), sin (xy1.x + xy1.y)) + 1.0.xxx) * 0.5;
   retval.rgb = lerp (0.0.xxx, lerp (retval.rgb, 1.0.xxx, g_2), min (1.0, g_1));
   hsva = fn_rgb2hsv (retval);
   hsva.x += Hue;

   if (hsva.x > 1.0) hsva.x -= 1.0;

   retval = fn_hsv2rgb (hsva);

   // Cannot do saturation in the HSV domain because there is almost no variation in V when
   // averaged.  By doing it here we take into account gain and hue variation.  We also
   // produce a more sensible tint result.

   float3 luma = dot (retval, float4 (0.299, 0.587, 0.114, 0.0)).xxx;

   float4 Tint = float4 (luma + TintVal.rgb - 0.5.xxx, 1.0);

   retval.rgb = lerp (luma, retval.rgb, Satn * 2.0);
   retval = lerp (Bgnd, lerp (retval, Tint, TintAmt), Opacity);

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

