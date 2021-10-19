// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/SmoothRoll_640.png

/**
 This effect provides a simple means of smoothing the movement of a credit roll or crawl.
 It does this by applying a small amount of directional blur to the title.

 Simply add this effect after your roll or crawl.  No action is required apart from
 adjusting the smoothing to give the best looking result and selecting roll or crawl mode.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SmoothRoll.fx
//
// Version history:
//
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Smooth roll";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "Directionally blurs a roll or crawl to smooth its motion";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define STRENGTH  0.00125

float _OutputAspectRatio;

float _gaussian[] = { 0.2255859375, 0.193359375, 0.120849609375, 0.0537109375, 0.01611328125, 0.0029296875, 0.000244140625 };

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (Title, s_Title);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Title mode";
   string Enum = "Roll,Crawl";
> = 0;

float Smoothing
<
   string Group = "Blur settings";
   string Description = "Smoothing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return BdrPixel (s_RawBg, uv); }

float4 ps_keygen (float2 uv : TEXCOORD3) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, uv).rgb;
   float3 Bgd = tex2D (s_Background, uv).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, 0.25, kDiff));
}

float4 ps_main_R (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgnd = tex2D (s_Title, uv) * _gaussian [0];

   float2 xy1 = float2 (0.0, Smoothing * _OutputAspectRatio * STRENGTH);
   float2 xy2 = uv + xy1;

   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6];

   xy2 = uv - xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

float4 ps_main_C (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgnd = tex2D (s_Title, uv) * _gaussian [0];

   float2 xy1 = float2 (Smoothing * STRENGTH, 0.0);
   float2 xy2 = uv + xy1;

   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6];

   xy2 = uv - xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SmoothRoll_I
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_4 ExecuteShader (ps_main_R)
}

technique SmoothRoll_O
{
   pass P_1 < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_2 < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_4 ExecuteShader (ps_main_C)
}

