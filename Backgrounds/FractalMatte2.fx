// @Maintainer jwrl
// @Released 2021-09-04
// @Author jwrl
// @Author trirop
// @Created 2021-09-04
// @see https://www.lwks.com/media/kunena/attachments/6375/Fractal1_640.png

/**
 Fractal matte 2 produces backgrounds generated from fractal patterns.  Because those
 backgrounds are newly created  media they will be produced at the sequence resolution.
 This means that any background video will also be locked to that resolution.

 NOTE: Backgrounds are newly created  media and will be produced at the sequence resolution.
 This means that any background video will also be locked at that resolution.
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
// Rewrite 2021-09-04 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal matte 2";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "Produces fractal patterns for background generation";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define Execute2param(SHD,P1,P2) { PixelShader = compile PROFILE SHD (P1, P2); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define TWO_PI     6.28318530718

#define INVSQRT3 0.57735026919

#define RGB_WEIGHT float3(0.2989, 0.5866, 0.1145)

#define SCL_RATE 224

#define LOOP     60

float _Progress;
float _Length;

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

DefineTarget (Image, s_Image);
DefineTarget (Matte, s_Matte);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Description = "Distortion";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Rate
<
   string Description = "Speed";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StartPoint
<
   string Description = "Start point";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Size
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointZ";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float4 Colour
<
   string Description = "Mix colour";
   string Group = "Colour";
   bool SupportsAlpha = true;
> = { 0.06, 0.5, 0.82, 1.0 };

float ColourMix
<
   string Description = "Mix level";
   string Group = "Colour";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float HueParam
<
   string Description = "Hue";
   string Group = "Colour";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float SatParam
<
   string Description = "Saturation";
   string Group = "Colour";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Gain
<
   string Description = "Gain";
   string Group = "Luminance";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

float Gamma
<
   string Description = "Gamma";
   string Group = "Luminance";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.00;

float Brightness
<
   string Description = "Brightness";
   string Group = "Luminance";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Contrast
<
   string Description = "Contrast";
   string Group = "Luminance";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fractals (float2 uv : TEXCOORD) : COLOR
{
   float progress = _Progress * _Length / 5.0;

   progress = ((progress + StartPoint) * TWO_PI) / sqrt (SCL_RATE + 1.0 - (SCL_RATE * Rate));

   float2 seed = float2 (cos (progress) * 0.3, sin (progress) * 0.5) + 0.5.xx;
   float2 xy = uv - float2 (Xcentre, 1.0 - Ycentre);

   float3 retval = float3 (xy / (Size + 0.075), seed.x);

   for (int i = 0; i < LOOP; i++) {
      retval.rbg = float3 (1.2, 0.999, 0.9) * (abs ((abs (retval) / dot (retval, retval) - float3 (1.0, 1.0, seed.y * 0.4))));
   }

   return float4 (saturate (retval), 1.0);
}

float4 ps_distort (float2 uv : TEXCOORD, uniform sampler s, uniform bool P2) : COLOR
{
   float4 Img = GetPixel (s, uv);

   if (Amount != 0.0) {
      float2 xy = P2 ? float2 (Img.b - Img.r, Img.g) : float2 (Img.b, Img.g - Img.r - 1.0);

      xy  = abs (uv + frac (xy * Amount));

      if (xy.x > 1.0) xy.x -= 1.0;

      if (xy.y > 1.0) xy.y -= 1.0;

      Img = GetPixel (s, xy);
   }

   return Img;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgd = GetPixel (s_Input, uv1);

   float2 xy = uv2;

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

   float4 retval = tex2D (s_Matte, xy);

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

   retval   = (Hrange < 1.0) ? temp.zyxw : (Hrange < 2.0) ? temp.xzyw : temp.yxzw;
   temp.rgb = (((pow (retval.rgb, 1.0 / GammVal) * Gain) + Brightness.xxx - 0.5.xxx) * Contrast) + 0.5.xxx;

   return lerp (Fgd, temp, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FractalMatte_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Matte;"; > ExecuteShader (ps_fractals)
   pass P_2 < string Script = "RenderColorTarget0 = Image;"; > Execute2param (ps_distort, s_Matte, true)
   pass P_3 < string Script = "RenderColorTarget0 = Matte;"; > Execute2param (ps_distort, s_Image, false)
   pass P_4 ExecuteShader (ps_main)
}

