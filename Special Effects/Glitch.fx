// @Maintainer jwrl
// @Released 2020-10-02
// @Author jwrl
// @Created 2020-10-02
// @see https://www.lwks.com/media/kunena/attachments/6375/Glitch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Glitch.mp4

/**
 To use this effect just add it on top of your existing effect, select the colours
 to affect, then the spread and the amount of edge jitter that you need.  That
 really is all that there is to it.

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
// Built 2020-10-02 by jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glitch";
   string Category    = "Key";
   string SubCategory = "Special Effects";
   string Notes       = "Applies a glitch to titles or keys.  Just apply on top of your effect.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Key    : RenderColorTarget;
texture Glitch : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Key = sampler_state { Texture = <Key>; };

sampler s_Glitch = sampler_state
{
   Texture   = <Glitch>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   string Enum = "Red - cyan,Green - magenta,Blue - yellow,Normal colour";
> = 0;

float Spread
<
   string Group = "Glitch settings";
   string Description = "Spread";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float Jitter
<
   string Group = "Glitch settings";
   string Description = "Jitter";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Coarseness
<
   string Group = "Glitch settings";
   string Description = "Coarseness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

int ShowKey
<
   string Group = "Key settings";
   string Description = "Operating mode";
   string Enum = "Delta key,Show delta key,Use foreground alpha";
> = 0;

float Clip
<
   string Group = "Key settings";
   string Description = "Clip";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Gain
<
   string Group = "Key settings";
   string Description = "Gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.95;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH   // Only available in version 14.5 and up
Bad_LW_version    // Forces a compiler error if the Lightworks version is bad.
#endif

#define EMPTY  0.0.xxxx

#define SCALE  0.01
#define EDGE   9.0

float _Length;
float _LengthFrames;

float _Progress;

float _OutputWidth;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_noise (float y)
{
   float edge = _OutputWidth * _OutputAspectRatio;

   edge = floor ((edge * y) / ((Coarseness * EDGE) + 1.0)) / edge;

   float3 seed = frac (float3 (_Length, _LengthFrames, 1.0) * (_Progress + 0.1) * 19.0);

   float n1 = 8192.0 * sin (dot (seed, float3 (17.0, 53.0, 7.0)));
   float n2 = 1024.0 * sin (((n1 / 1024.0) + edge) * 59.0);

   return frac (float2 (abs (n1), n2) * 256.0);
}

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if ((xy.x > 0.5) || (xy.y > 0.5)) return EMPTY;

   return tex2D (s, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_key_gen (float2 uv : TEXCOORD1) : COLOR
{
   if (ShowKey == 2) {
      float4 aKey = tex2D (s_Foreground, uv);

      aKey.a = pow (aKey.a, 0.5);
      aKey.rgb /= aKey.a;

      return aKey;
   }

   float3 Fgnd = tex2D (s_Foreground, uv).rgb;
   float3 Bgnd = tex2D (s_Background, uv).rgb;

   float cDiff = distance (Bgnd, Fgnd);

   float alpha = smoothstep (Clip, Clip - Gain + 1.0, cDiff);

   Fgnd *= alpha;
   alpha = pow (alpha, 0.5);

   return float4 (Fgnd, alpha);
}

float4 ps_glitch_0 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = fn_noise (uv.y);

   xy.y *= xy.x;
   xy *= float2 (Spread, Jitter) * SCALE;

   float2 xy1 = uv + float2 (xy.x + xy.y, 0.0);
   float2 xy2 = uv - float2 (xy.x - xy.y, 0.0);

   float4 retval = fn_tex2D (s_Key, xy1);

   retval.r   = 0.0;
   retval.ra += fn_tex2D (s_Key, xy2).ra;
   retval.a  /= 2.0;

   return retval;
}

float4 ps_glitch_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = fn_noise (uv.y);

   xy.y *= xy.x;
   xy *= float2 (Spread, Jitter) * SCALE;

   float2 xy1 = uv + float2 (xy.x + xy.y, 0.0);
   float2 xy2 = uv - float2 (xy.x - xy.y, 0.0);

   float4 retval = fn_tex2D (s_Key, xy1);

   retval.g   = 0.0;
   retval.ga += fn_tex2D (s_Key, xy2).ga;
   retval.a  /= 2.0;

   return retval;
}

float4 ps_glitch_2 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = fn_noise (uv.y);

   xy.y *= xy.x;
   xy *= float2 (Spread, Jitter) * SCALE;

   float2 xy1 = uv + float2 (xy.x + xy.y, 0.0);
   float2 xy2 = uv - float2 (xy.x - xy.y, 0.0);

   float4 retval = fn_tex2D (s_Key, xy1);

   retval.b   = 0.0;
   retval.ba += fn_tex2D (s_Key, xy2).ba;
   retval.a  /= 2.0;

   return retval;
}

float4 ps_glitch_3 (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = fn_noise (uv.y);

   xy.y *= xy.x;
   xy *= float2 (Spread, Jitter) * SCALE;

   float2 xy1 = uv + float2 (xy.x + xy.y, 0.0);
   float2 xy2 = uv - float2 (xy.x - xy.y, 0.0);

   return (fn_tex2D (s_Key, xy1) + fn_tex2D (s_Key, xy2)) / 2.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   if (ShowKey == 1) return tex2D (s_Key, uv);

   float4 Fgnd = tex2D (s_Glitch, uv);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Glitch_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glitch;"; >
   { PixelShader = compile PROFILE ps_glitch_0 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique Glitch_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glitch;"; >
   { PixelShader = compile PROFILE ps_glitch_1 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique Glitch_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glitch;"; >
   { PixelShader = compile PROFILE ps_glitch_2 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique Glitch_3
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glitch;"; >
   { PixelShader = compile PROFILE ps_glitch_3 (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

