// @Maintainer jwrl
// @Released 2021-11-03
// @Author jwrl
// @Released 2021-07-11
// @see https://forum.lwks.com/attachments/videoglitch_640-png.39494/

/**
 To use this effect just apply it, select the colours to affect, then the spread and
 the amount of edge roughness that you need.  That really is all that there is to it.
 You can also control the edge jitter, the glitch rate and angle and the amount of
 video modulation that is applied to the image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VideoGlitch.fx
//
// Version history:
//
// Created 2021-11-03 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Video glitch";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Applies a glitch effect to video.";
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

#define DefineTarget(TEXTURE, SAMPLER) \
                                       \
 texture TEXTURE : RenderColorTarget;  \
                                       \
 sampler SAMPLER = sampler_state       \
 {                                     \
   Texture   = <TEXTURE>;              \
   AddressU  = ClampToEdge;            \
   AddressV  = ClampToEdge;            \
   MinFilter = Linear;                 \
   MagFilter = Linear;                 \
   MipFilter = Linear;                 \
 }

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define SCALE  0.01
#define MODLN  0.25
#define MODN1  0.125
#define EDGE   9.0

float _Length;
float _LengthFrames;

float _Progress;

float _OutputWidth;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Glitch settings";
   string Description = "Glitch channels";
   string Enum = "Red - cyan,Green - magenta,Blue - yellow,Full colour";
> = 0;

float GlitchRate
<
   string Group = "Glitch settings";
   string Description = "Glitch rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Modulation
<
   string Group = "Glitch settings";
   string Description = "Modulation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Rotation
<
   string Group = "Glitch settings";
   string Description = "Rotation";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 0.0;

float Spread
<
   string Group = "Glitch settings";
   string Description = "Spread";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeRoughen
<
   string Group = "Glitch settings";
   string Description = "Edge roughen";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeJitter
<
   string Group = "Glitch settings";
   string Description = "Edge jitter";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_noise (float y)
{
   float edge = _OutputWidth * _OutputAspectRatio;
   float rate = floor (_LengthFrames / _Length);

   edge  = floor ((edge * y) / ((EdgeJitter * EDGE) + 1.0)) / edge;
   rate -= (rate - 1.0) * ((GlitchRate * 0.2) + 0.8);
   rate *= floor ((_LengthFrames * _Progress) / rate) / _LengthFrames;

   float3 seed = frac (float3 (_Length, _LengthFrames, 1.0) * rate * 19.0);

   float n1 = 8192.0 * sin (dot (seed, float3 (17.0, 53.0, 7.0)));
   float n2 = 1024.0 * sin (((n1 / 1024.0) + edge) * 59.0);

   return frac (float2 (abs (n1), n2) * 256.0);
}

float2 fn_glitch (float2 uv, out float m)
{
   float c, s, x = dot (uv, float2 (EdgeRoughen, Spread)) * SCALE;

   sincos (radians (Rotation), s, c);

   m = 1.0 - (abs (uv.x) * Modulation * MODLN);

   return float2 (c, s * _OutputAspectRatio) * x;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main_0 (float2 uv : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv.y);

   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = GetPixel (s_Input, uv + xy);

   retval.ra = GetPixel (s_Input, uv - xy).ra;

   retval *= modulation;

   return lerp (GetPixel (s_Input, uv), retval, retval.a * Amount);
}

float4 ps_main_1 (float2 uv : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv.y);

   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = GetPixel (s_Input, uv + xy);

   retval.ga = GetPixel (s_Input, uv - xy).ga;

   retval *= modulation;

   return lerp (GetPixel (s_Input, uv), retval, retval.a * Amount);
}

float4 ps_main_2 (float2 uv : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv.y);

   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = GetPixel (s_Input, uv + xy);

   retval.ba = GetPixel (s_Input, uv - xy).ba;

   retval *= modulation;

   return lerp (GetPixel (s_Input, uv), retval, retval.a * Amount);
}

float4 ps_main_3 (float2 uv : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv.y);

   xy.y *= xy.x;
   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = (xy.x >= 0.0) ? GetPixel (s_Input, uv + xy) : GetPixel (s_Input, uv - xy);

   retval *= modulation;

   return lerp (GetPixel (s_Input, uv), retval, retval.a * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Video_Glitch_0
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_0)
}

technique Video_Glitch_1
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_1)
}

technique Video_Glitch_2
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_2)
}

technique Video_Glitch_3
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_3)
}

