// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-28
// @see https://www.lwks.com/media/kunena/attachments/6375/PosterPaint_640.png

/**
Poster paint (PosterPaintFx) is an effect that posterizes the image.  The adjustment runs
from 0 to 20, with zero providing two steps of posterization (black and white) and twenty
giving normal video.  The input video can be graded prior to the posterization process.
The posterized colours can be set to either switch on giving a hard edge, or smoothly blend.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PosterPaintFx.fx
//
// Modified 23 December 2018 jwrl.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Poster paint";
   string Category    = "Colour";
   string SubCategory = "Art Effects";
   string Notes       = "An adjustable posterize effect";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and Sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Foreground = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Posterize amount";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 20.0;

float Brightness
<
   string Group = "Input adjustment";
   string Description = "Brightness";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Contrast
<
   string Group = "Input adjustment";
   string Description = "Contrast";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float Gamma
<
   string Group = "Input adjustment";
   string Description = "Gamma";
   float MinVal = 0.1;
   float MaxVal = 4.0;
> = 1.0;

float Gain
<
   string Group = "Input adjustment";
   string Description = "Gain";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

float HueAngle
<
   string Group = "Input adjustment";
   string Description = "Hue (degrees)";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Saturation
<
   string Group = "Input adjustment";
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

int RampGrade
<
   string Group = "Input adjustment";
   string Description = "Input adjustment changes as posterization changes";
   string Enum = "By switching on,By fading on";
> = 1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define ONE_THIRD  0.3333333333

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_makeRGB (float hue, float a, float b)
{
   float Hue = hue;

   if (Hue < 0.0) Hue += 1.0;
   if (Hue > 1.0) Hue -= 1.0;

   Hue *= 6.0;

   if (Hue < 1.0) { return b + (a - b) * Hue; }
   else if (Hue < 3.0) { return a; }
   else if (Hue < 4.0) { return b + (a - b) * (4.0 - Hue); }

   return b;
}

float3 fn_RGBtoHSL (float3 RGB)
{
   float high  = max (RGB.r, max (RGB.g, RGB.b));
   float lows  = min (RGB.r, min (RGB.g, RGB.b));
   float range = high - lows;
   float Lraw  = high + lows;

   float Luma  = Lraw * 0.5;
   float Hue   = 0.0;
   float Satn  = 0.0;

   if (range != 0.0) {
      Satn = (Lraw < 1.0) ? range / Lraw : range / (2.0 - Lraw);

      if (RGB.r == high) { Hue = (RGB.g - RGB.b) / range; }
      else if (RGB.g == high) { Hue = 2.0 + (RGB.b - RGB.r) / range; }
      else { Hue = 4.0 + (RGB.r - RGB.g) / range; }

      Hue /= 6.0;
   }

   return float3 (Hue, Satn, Luma);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 RGB = tex2D (s_Foreground, uv);

   float posterize = max (floor (Amount + 2.0), 1.0);

   posterize *= 0.5;

   if (posterize < 11.0) {
      float3 HSL = ((((pow (RGB.rgb, 1.0 / Gamma ) * Gain ) + Brightness) - 0.5.xxx) * Contrast) + 0.5.xxx;

      float A = (RampGrade == 1) ? saturate (2.75 - (posterize * 0.25)) : 1.0;

      HSL = lerp (RGB.rgb, HSL, A);
      HSL = fn_RGBtoHSL (HSL);
      HSL.y = saturate (HSL.y * lerp (1.0, Saturation, A));
      HSL.yz = saturate (round (HSL.yz * posterize) / posterize);

      if (HSL.y == 0.0) return float4 (HSL.zzz, RGB.a);

      HSL.x = frac (HSL.x + (A * HueAngle / 360.0));
      posterize *= 6.0;
      HSL.x = saturate (round (HSL.x * posterize) / posterize);

      A = HSL.y * HSL.z;
      A = (HSL.z < 0.5) ? HSL.z + A : (HSL.y + HSL.z) - A;

      float B = (2.0 * HSL.z) - A;

      RGB.r = fn_makeRGB (HSL.x + ONE_THIRD, A, B);
      RGB.g = fn_makeRGB (HSL.x, A, B);
      RGB.b = fn_makeRGB (HSL.x - ONE_THIRD, A, B);
   }

   return RGB;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PosterPaintFx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

