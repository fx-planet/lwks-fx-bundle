// @Maintainer jwrl
// @Released 2021-07-11
// @Author jwrl
// @Created 2021-07-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Glitch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Glitch_720.mp4

/**
 To use this effect just add it on top of your existing effect, select the colours
 to affect, then the spread and the amount of edge roughness that you need.  That
 really is all that there is to it.  You can also control the edge jitter, the glitch
 rate and angle and the amount of video modulation that is applied to the image.

 The effect is built around a delta or difference key.  This ensures that the effect
 can be applied over an existing title, image key or key effect and will usually just
 automatically extract the foreground to apply the glitch to.  Should you need to,
 adjustments have been provided but it shouldn't often be necessary to touch them.

 Should the separation of the foreground from the background not be all that you
 would wish even after adjustment, you can use the alpha channel of your foreground.
 If you do that you will need to open the routing panel and manually disconnect any
 input to the foreground.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Glitch.fx
//
// Version history:
//
// Rewrite 2021-07-11 jwrl.
// The original version did not handle the keys well with resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glitch";
   string Category    = "Key";
   string SubCategory = "Special Effects";
   string Notes       = "Applies a glitch to titles or keys.  Just apply on top of your effect.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

// Standard header block (or near enough)

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

#define GetPixel(SHADER,XY)  (any (XY < 0.0) || any (XY > 1.0) ? EMPTY : tex2D (SHADER, XY))

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

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Key, s_Key);
DefineTarget (Glitch, s_Glitch);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
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

int ShowKey
<
   string Group = "Key settings";
   string Description = "Operating mode";
   string Enum = "Delta key,Show delta key,Use foreground alpha";
> = 0;

float KeyClip
<
   string Group = "Key settings";
   string Description = "Key clip";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float KeyGain
<
   string Group = "Key settings";
   string Description = "Key gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.95;

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

float4 ps_key_gen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Fgd.a == 0.0) return Fgnd.aaaa;

   if (ShowKey == 2) {
      Fgnd.a = pow (Fgnd.a, 0.5 + (KeyClip * 0.5));
      Fgnd.rgb /= lerp (1.0, Fgnd.a, KeyGain);
   }
   else {
      float3 Bgnd = GetPixel (s_Background, uv2).rgb;

      float cDiff = distance (Bgnd, Fgnd.rgb);
      float alpha = smoothstep (KeyClip, KeyClip - KeyGain + 1.0, cDiff);

      Fgnd.rgb *= alpha;
      Fgnd.a    = pow (alpha, 0.5);
   }

   return Fgnd;
}

float4 ps_glitch_0 (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv1.y);

   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = GetPixel (s_Key, uv1 + xy);

   retval.ra = GetPixel (s_Key, uv1 - xy).ra;

   return retval * modulation;
}

float4 ps_glitch_1 (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv1.y);

   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = GetPixel (s_Key, uv1 + xy);

   retval.ga = GetPixel (s_Key, uv1 - xy).ga;

   return retval * modulation;
}

float4 ps_glitch_2 (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv1.y);

   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = GetPixel (s_Key, uv1 + xy);

   retval.ba = GetPixel (s_Key, uv1 - xy).ba;

   return retval * modulation;
}

float4 ps_glitch_3 (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float modulation;

   float2 xy = fn_noise (uv1.y);

   xy.y *= xy.x;
   xy.x *= xy.y;

   xy = fn_glitch (xy, modulation);

   float4 retval = (xy.x >= 0.0) ? GetPixel (s_Key, uv1 + xy) : GetPixel (s_Key, uv1 - xy);

   return retval * modulation;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (ShowKey == 1) return GetPixel (s_Key, uv1);

   float4 Fgnd = GetPixel (s_Glitch, uv1);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Glitch_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_key_gen)
   pass P_2 < string Script = "RenderColorTarget0 = Glitch;"; > ExecuteShader (ps_glitch_0)
   pass P_3 ExecuteShader (ps_main)
}

technique Glitch_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_key_gen)
   pass P_2 < string Script = "RenderColorTarget0 = Glitch;"; > ExecuteShader (ps_glitch_1)
   pass P_3 ExecuteShader (ps_main)
}

technique Glitch_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_key_gen)
   pass P_2 < string Script = "RenderColorTarget0 = Glitch;"; > ExecuteShader (ps_glitch_2)
   pass P_3 ExecuteShader (ps_main)
}

technique Glitch_3
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_key_gen)
   pass P_2 < string Script = "RenderColorTarget0 = Glitch;"; > ExecuteShader (ps_glitch_3)
   pass P_3 ExecuteShader (ps_main)
}

