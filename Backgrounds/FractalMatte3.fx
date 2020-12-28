// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Author trirop
// @Created 2020-12-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Fractal3_640.png

/**
 Fractal matte 3 produces backgrounds generated from fractal patterns.  Because those
 backgrounds are newly created  media they will be produced at the sequence resolution.
 This means that any background video will also be locked to that resolution.

 NOTE: Backgrounds are newly created  media and will be produced at the sequence resolution.
 This means that any background video will also be locked at that resolution.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FractalMatte3.fx
//
// The fractal generation component was first created by Robert Schütze (trirop) in GLSL
// sandbox (http://glslsandbox.com/e#29611.0).  It has been somewhat modified to better
// suit its use in this effect.
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal matte 3";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "Produces fractal patterns for background generation";
   bool CanSize       = false;
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

#define DefineSampler(S, T) \
                            \
 sampler S = sampler_state  \
 {                          \
   Texture   = <T>;         \
   AddressU  = ClampToEdge; \
   AddressV  = ClampToEdge; \
   MinFilter = Linear;      \
   MagFilter = Linear;      \
   MipFilter = Linear;      \
 }

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 DefineSampler (SAMPLER, TEXTURE);

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 DefineSampler (TSAMPLE, TARGET);

#define PI_2     6.28318530718

#define INVSQRT3 0.57735026919

#define R_WEIGHT 0.2989
#define G_WEIGHT 0.5866
#define B_WEIGHT 0.1145

float _Progress;
float _Length;

float _OutputAspectRatio;

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Input and target
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

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

float FracOffs
<
   string Description = "Fractal offset";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float FracRate
<
   string Description = "Fractal rate";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 Colour
<
   string Description = "Mix colour";
   string Group = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.77, 0.19, 1.0 };

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
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fractal (float2 xy : TEXCOORD) : COLOR
{
   float speed = _Progress * FracRate * _Length / 5.0;

   float4 retval = 1.0.xxxx;

   float3 f = float3 (xy, FracOffs);

   for (int i = 0; i < 75; i++) {
      f.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (f) / dot (f, f) - float3 (1.0, 1.0, speed * 0.5))));
   }

   retval.rgb = f;

   return retval;
}

float4 ps_main (float2 uv0 : TEXCOORD0, float2 uv1 : TEXCOORD1) : COLOR
{
   float4 Fgd = fn_tex2D (s_Input, uv1);

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

   float4 retval = fn_tex2D (s_Matte, xy);

   float luma   = dot (retval.rgb, float3 (R_WEIGHT, G_WEIGHT, B_WEIGHT));
   float buffer = dot (Colour.rgb, float3 (R_WEIGHT, G_WEIGHT, B_WEIGHT));

   buffer = saturate (buffer - 0.5);
   buffer = 1.0 / (buffer + 0.5);

   float4 temp = Colour * luma * buffer;

   retval = lerp (retval, temp, ColourMix);
   luma = (retval.r + retval.g + retval.b) / 3.0;

   float RminusG = retval.r - retval.g;
   float RminusB = retval.r - retval.b;
   float GammVal = (Gamma > 1.0) ? Gamma : Gamma * 0.9 + 0.1;
   float Hue_Val = acos ((RminusG + RminusB) / (2.0 * sqrt (RminusG * RminusG + RminusB * (retval.g - retval.b)))) / PI_2;
   float Sat_Val = 1.0 - min (min (retval.r, retval.g), retval.b) / luma;

   if (retval.b > retval.g) Hue_Val = 1.0 - Hue_Val;

   Hue_Val = frac (Hue_Val + (HueParam * 0.5));
   Sat_Val = saturate (Sat_Val * (SatParam + 1.0));

   float Hrange = Hue_Val * 3.0;
   float Hoffst = (2.0 * floor (Hrange) + 1.0) / 6.0;

   buffer = INVSQRT3 * tan ((Hue_Val - Hoffst) * PI_2);
   temp.x = (1.0 - Sat_Val) * luma;
   temp.y = ((3.0 * (buffer + 1.0)) * luma - (3.0 * buffer + 1.0) * temp.x) / 2.0;
   temp.z = 3.0 * luma - temp.y - temp.x;

   retval = (Hrange < 1.0) ? temp.zyxw : (Hrange < 2.0) ? temp.xzyw : temp.yxzw;
   temp   = (((pow (retval, 1.0 / GammVal) * Gain) + Brightness.xxxx - 0.5.xxxx) * Contrast) + 0.5.xxxx;
   retval = lerp (Fgd, temp, Opacity);

   retval.a = Fgd.a;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FractalMatte3
{
   pass P_1
   < string Script = "RenderColorTarget0 = Matte;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
