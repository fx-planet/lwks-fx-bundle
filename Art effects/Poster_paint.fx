// @Maintainer jwrl
// @Released 2021-08-07
// @Author jwrl
// @Created 2021-08-07
// @see https://www.lwks.com/media/kunena/attachments/6375/PosterPaint_640.png

/**
 Poster paint (PosterPaintFx) is an effect that posterizes the image.  The adjustment runs
 from 2 to 16, with two providing two steps of posterization (black and white) and sixteen
 giving almost normal video.  The input video can be graded before the posterization process.
 The input image can be used as-is giving the posterisation a hard edge, or blurred to allow
 it to blend more smoothly.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PosterPaint.fx
//
// Version history:
//
// Rewrite 2021-08-07 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Poster paint";
   string Category    = "Colour";
   string SubCategory = "Art Effects";
   string Notes       = "A fully adjustable posterize effect";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define ONE_THIRD  0.3333333333

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Pre, s_PreBlur);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Amount
<
   string Description = "Posterize amount";
   string Enum = "2,3,4,5,6,7,8,9,10,11,12,13,14,15,16";
> = 3;

float Smoothness
<
   string Group = "Major input adjustment";
   string Description = "Preblur";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Saturation
<
   string Group = "Major input adjustment";
   string Flags = "DisplayAsPercentage";
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

float Gamma
<
   string Group = "Major input adjustment";
   string Description = "Gamma";
   float MinVal = 0.1;
   float MaxVal = 4.0;
> = 1.0;

float Brightness
<
   string Group = "Minor input adjustment";
   string Flags = "DisplayAsPercentage";
   string Description = "Brightness";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Contrast
<
   string Group = "Minor input adjustment";
   string Flags = "DisplayAsPercentage";
   string Description = "Contrast";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float Gain
<
   string Group = "Minor input adjustment";
   string Flags = "DisplayAsPercentage";
   string Description = "Gain";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

float HueAngle
<
   string Group = "Minor input adjustment";
   string Description = "Hue (degrees)";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_HSLtoRGB (float3 HSL)
{
   float3 RGB;

   float dif = HSL.y - HSL.z;

   RGB.r = HSL.x + ONE_THIRD;
   RGB.b = HSL.x - ONE_THIRD;

   RGB.r = (RGB.r < 0.0) ? RGB.r + 1.0 : (RGB.r > 1.0) ? RGB.r - 1.0 : RGB.r;
   RGB.g = (HSL.x < 0.0) ? HSL.x + 1.0 : (HSL.x > 1.0) ? HSL.x - 1.0 : HSL.x;
   RGB.b = (RGB.b < 0.0) ? RGB.b + 1.0 : (RGB.b > 1.0) ? RGB.b - 1.0 : RGB.b;

   RGB *= 6.0;

   RGB.r = (RGB.r < 1.0) ? (RGB.r * dif) + HSL.z :
           (RGB.r < 3.0) ? HSL.y :
           (RGB.r < 4.0) ? ((4.0 - RGB.r) * dif) + HSL.z : HSL.z;

   RGB.g = (RGB.g < 1.0) ? (RGB.g * dif) + HSL.z :
           (RGB.g < 3.0) ? HSL.y :
           (RGB.g < 4.0) ? ((4.0 - RGB.g) * dif) + HSL.z : HSL.z;

   RGB.b = (RGB.b < 1.0) ? (RGB.b * dif) + HSL.z :
           (RGB.b < 3.0) ? HSL.y :
           (RGB.b < 4.0) ? ((4.0 - RGB.b) * dif) + HSL.z : HSL.z;

   return RGB;
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

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_preblur (float2 uv : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   // What follows is the horizontal component of a standard box blur.  The maths used
   // takes advantage of the fact that the shader language can do float2 operations as
   // efficiently as floats.  This way we save on having to manufacture a new float2
   // every time that we need a new address for the next tap.

   float2 xy0 = float2 (Smoothness / _OutputWidth, 0.0);
   float2 xy1 = uv + xy0;
   float2 xy2 = uv - xy0;

   retval += tex2D (s_Input, xy1); xy1 += xy0;
   retval += tex2D (s_Input, xy1); xy1 += xy0;
   retval += tex2D (s_Input, xy1); xy1 += xy0;
   retval += tex2D (s_Input, xy1); xy1 += xy0;
   retval += tex2D (s_Input, xy1); xy1 += xy0;
   retval += tex2D (s_Input, xy1);
   retval += tex2D (s_Input, xy2); xy2 -= xy0;
   retval += tex2D (s_Input, xy2); xy2 -= xy0;
   retval += tex2D (s_Input, xy2); xy2 -= xy0;
   retval += tex2D (s_Input, xy2); xy2 -= xy0;
   retval += tex2D (s_Input, xy2); xy2 -= xy0;
   retval += tex2D (s_Input, xy2);

   // Divide retval by 13 because there are 12 sampling taps plus the original image

   return retval / 13.0;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 RGB = tex2D (s_PreBlur, uv2);

   float alpha = RGB.a;

   // This is the vertical component of the box blur.

   float2 xy0 = float2 (0.0, Smoothness / _OutputHeight);
   float2 xy1 = uv2 + xy0;
   float2 xy2 = uv2 - xy0;

   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1); xy1 += xy0;
   RGB += tex2D (s_PreBlur, xy1);
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2); xy2 -= xy0;
   RGB += tex2D (s_PreBlur, xy2);

   RGB /= 13.0;

   float posterize = Amount + 2.0;

   // We now adjust the brightness, contrast, gamma and gain of the preblurred image.

   float3 proc = (((pow (RGB.rgb, 1.0 / Gamma) * Gain) + (Brightness - 0.5).xxx) * Contrast) + 0.5.xxx;
   float3 HSL = fn_RGBtoHSL (proc);

   HSL.y = saturate (HSL.y * Saturation);
   HSL.x = HSL.x + frac (HueAngle / 360.0);

   if (HSL.x < 0.0) HSL.x += 1.0;
   if (HSL.x > 1.0) HSL.x -= 1.0;

   HSL.yz = saturate (round (HSL.yz * posterize) / posterize);

   if (HSL.y == 0.0) return float4 (HSL.zzz, RGB.a);

   posterize *= 6.0;
   HSL.x = saturate (round (HSL.x * posterize) / posterize);

   float S = HSL.y * HSL.z;

   HSL.y = (HSL.z < 0.5) ? HSL.z + S : (HSL.y + HSL.z) - S;
   HSL.z = (2.0 * HSL.z) - HSL.y;

   RGB.rgb = fn_HSLtoRGB (HSL);

   return Overflow (uv1) ? EMPTY : lerp (EMPTY, RGB, alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PosterPaint
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = Pre;"; > ExecuteShader (ps_preblur)
   pass P_2 ExecuteShader (ps_main)
}

