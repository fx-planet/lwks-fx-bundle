// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Author trirop
// @Created 2023-01-23

/**
 Fractal matte 2 produces backgrounds generated from fractal patterns.  The rate of
 development, position and scaling are all adjustable, and a flat colour can be mixed
 with the fractal to give a wide range of unique appearances.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FractalMatte2.fx
//
// The fractal generation component was first created by Robert Schütze (trirop) in GLSL
// sandbox (http://glslsandbox.com/e#29611.0).  It has been somewhat modified to better
// suit its use in this effect.
//
// Version history:
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Fractal matte 2", "Mattes", "Backgrounds", "Produces fractal patterns for background generation", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Distortion", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Rate, "Speed", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (StartPoint, "Start point", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam (Size, "Effect centre", kNoGroup, "SpecifiesPointZ", 1.0, 0.0, 2.0);

DeclareColourParam (Colour, "Mix colour", "Colour", kNoFlags, 0.06, 0.5, 0.82);

DeclareFloatParam (ColourMix, "Mix level", "Colour", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (HueParam, "Hue", "Colour", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (SatParam, "Saturation", "Colour", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Gain, "Gain", "Luminance", kNoFlags, 1.0, 0.0, 4.0);
DeclareFloatParam (Gamma, "Gamma", "Luminance", kNoFlags, 1.0, 0.0, 4.0);
DeclareFloatParam (Brightness, "Brightness", "Luminance", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Contrast, "Contrast", "Luminance", kNoFlags, 1.0, 0.0, 4.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define TWO_PI   6.28318530718
#define INVSQRT3 0.57735026919
#define SCL_RATE 224

#define LOOP 60

#define RGB_WEIGHT float3(0.2989, 0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_distort (sampler S, float2 uv, bool P2)
{
   float4 Img = tex2D (S, uv);

   if (Amount != 0.0) {
      float2 xy = P2 ? float2 (Img.b - Img.r, Img.g) : float2 (Img.b, Img.g - Img.r - 1.0);

      xy  = abs (uv + frac (xy * Amount));

      if (xy.x > 1.0) xy.x -= 1.0;

      if (xy.y > 1.0) xy.y -= 1.0;

      Img = tex2D (S, xy);
   }

   return Img;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fractal)
{
   float progress = _Progress * _Length / 5.0;

   progress = ((progress + StartPoint) * TWO_PI) / sqrt (SCL_RATE + 1.0 - (SCL_RATE * Rate));

   float2 seed = float2 (cos (progress) * 0.3, sin (progress) * 0.5) + 0.5.xx;
   float2 xy = uv0 - float2 (Xcentre, 1.0 - Ycentre);

   float3 retval = float3 (xy / (Size + 0.075), seed.x);

   for (int i = 0; i < LOOP; i++) {
      retval.rbg = float3 (1.2, 0.999, 0.9) * (abs ((abs (retval) / dot (retval, retval) - float3 (1.0, 1.0, seed.y * 0.4))));
   }

   return float4 (saturate (retval), 1.0);
}

DeclarePass (Image)
{ return fn_distort (Fractal, uv2, true); }

DeclarePass (Matte)
{ return fn_distort (Image, uv2, false); }

DeclareEntryPoint (FractalMatte2)
{
   float4 Fgd = ReadPixel (Inp, uv1);
   float4 retval = tex2D (Matte, uv2);

   float luma   = dot (retval.rgb, RGB_WEIGHT);
   float buffer = dot (Colour.rgb, RGB_WEIGHT);

   buffer = saturate (buffer - 0.5);
   buffer = 1.0 / (buffer + 0.5);

   float4 temp = Colour * luma * buffer;

   retval = lerp (retval, temp, ColourMix);
   luma = (retval.r + retval.g + retval.b) / 3.0;

   float RminusG = retval.r - retval.g;
   float RminusB = retval.r - retval.b;
   float GammVal = (Gamma > 1.0) ? Gamma : Gamma * 0.9 + 0.1;
   float Hue_Val = acos ((RminusG + RminusB) / (2.0 * sqrt (RminusG * RminusG + RminusB * (retval.g - retval.b)))) / TWO_PI;
   float Sat_Val = 1.0 - min (min (retval.r, retval.g), retval.b) / luma;

   if (retval.b > retval.g) Hue_Val = 1.0 - Hue_Val;

   Hue_Val = frac (Hue_Val + (HueParam * 0.5));
   Sat_Val = saturate (Sat_Val * (SatParam + 1.0));

   float Hrange = Hue_Val * 3.0;
   float Hoffst = (2.0 * floor (Hrange) + 1.0) / 6.0;

   buffer = INVSQRT3 * tan ((Hue_Val - Hoffst) * TWO_PI);
   temp.w = 1.0;
   temp.x = (1.0 - Sat_Val) * luma;
   temp.y = ((3.0 * (buffer + 1.0)) * luma - (3.0 * buffer + 1.0) * temp.x) / 2.0;
   temp.z = 3.0 * luma - temp.y - temp.x;

   retval = (Hrange < 1.0) ? temp.zyxw : (Hrange < 2.0) ? temp.xzyw : temp.yxzw;
   retval = (((pow (retval, 1.0 / GammVal) * Gain) + (Brightness - 0.5).xxxx) * Contrast) + 0.5.xxxx;
   retval.a = 1.0;

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

