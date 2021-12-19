// @Maintainer jwrl
// @Released 2021-12-19
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
// Update 2021-12-19 jwrl.
// Improved default settings.  Now defaults to full colour mode.
// Changed structure so that only two passes are needed and one function instead of two.
// Modulation is now completely independent of displacement.
// Edge roughness now actually does something.
//
// Update 2021-11-01 jwrl.
// Corrected foreground mislabel in ps_key_gen().
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define SCALE 0.01
#define MODLN 0.25
#define EDGE  9.0

float _Length;
float _LengthFrames;

float _Progress;

float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Key, s_Key);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int Mode
<
   string Group = "Glitch settings";
   string Description = "Glitch channels";
   string Enum = "Red - cyan,Green - magenta,Blue - yellow,Full colour";
> = 3;

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
> = 0.25;

float KeyGain
<
   string Group = "Key settings";
   string Description = "Key gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_key_gen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Fgnd.a == 0.0) return Fgnd.aaaa;

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

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   if (ShowKey == 1) return GetPixel (s_Key, uv3);

   float roughness = lerp (1.0, 0.25, saturate (EdgeRoughen)) * _OutputHeight;

   float2 xy = fn_noise (floor (uv3.y * roughness) / _OutputHeight);

   xy.x *= xy.y;

   float modulation = 1.0 - abs (dot (xy, 0.5.xx) * Modulation * MODLN);
   float x = dot (xy, Spread.xx) * SCALE;

   sincos (radians (Rotation), xy.y, xy.x);

   xy.y *= _OutputAspectRatio;
   xy *= x;

   if (Mode != 3) xy /= 2.0;

   float4 video = GetPixel (s_Background, uv2);
   float4 ret_1 = GetPixel (s_Key, uv3 + xy) * modulation;
   float4 ret_2 = GetPixel (s_Key, uv3 - xy) * modulation;
   float4 glitch;

   glitch.r = Mode == 0 ? lerp (video.r, ret_2.r, ret_2.a)
                        : lerp (video.r, ret_1.r, ret_1.a);
   glitch.g = Mode == 1 ? lerp (video.g, ret_2.g, ret_2.a)
                        : lerp (video.g, ret_1.g, ret_1.a);
   glitch.b = Mode == 2 ? lerp (video.b, ret_2.b, ret_2.a)
                        : lerp (video.b, ret_1.b, ret_1.a);
   glitch.a = video.a;

   return lerp (video, glitch, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Glitch
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_key_gen)
   pass P_2 ExecuteShader (ps_main)
}

