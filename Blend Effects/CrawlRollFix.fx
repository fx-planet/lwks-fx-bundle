// @Maintainer jwrl
// @Released 2021-08-11
// @Author jwrl
// @Created 2021-08-11
// @see https://www.lwks.com/media/kunena/attachments/6375/SmoothRoll_640.png

/**
 This effect provides a simple means of smoothing the movement of a credit roll or crawl.
 It does this by applying a small amount of directional blur to the title.  It then blends
 the result with the background video.

 To use it, add this effect after your roll or crawl and disconnect the input to any title
 effect used.  Select whether you're smoothing a roll or crawl then adjust the smoothing
 to give the best looking result.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CrawlRollFix.fx
//
// Version history:
//
// Rewrite 2021-08-11 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Crawl and roll fix";
   string Category    = "Key";
   string SubCategory = "Blend Effects";
   string Notes       = "Directionally blurs a roll or crawl to smooth its motion";
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

#define DefineTargetAddress(TARGET, SAMPLER, ADDRESS) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ADDRESS;               \
   AddressV  = ADDRESS;               \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define STRENGTH  0.00125

float _OutputAspectRatio;

float _gaussian[] = { 0.2255859375, 0.193359375, 0.120849609375, 0.0537109375, 0.01611328125, 0.0029296875, 0.000244140625 };

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTargetAddress (Title, s_Title, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Mode";
   string Group = "Disconnect LW roll or crawl inputs first!";
   string Enum = "Roll effect,Crawl effect,Video roll,Video crawl";
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

float4 ps_effect (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Foreground, uv);

   retval.a    = pow (retval.a, 0.5);
   retval.rgb /= retval.a;

   return retval;
}

float4 ps_video (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Foreground, uv);
}

float4 ps_main_R (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = tex2D (s_Title, uv3) * _gaussian [0];

   float2 xy1 = float2 (0.0, Smoothing * _OutputAspectRatio * STRENGTH);
   float2 xy2 = uv3 + xy1;

   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6]; xy2 = uv3 - xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_main_C (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = tex2D (s_Title, uv3) * _gaussian [0];

   float2 xy1 = float2 (Smoothing * STRENGTH, 0.0);
   float2 xy2 = uv3 + xy1;

   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 += xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6]; xy2 = uv3 - xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [1]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [2]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [3]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [4]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [5]; xy2 -= xy1;
   Fgnd += tex2D (s_Title, xy2) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique CrawlRollFix_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_effect)
   pass P_2 ExecuteShader (ps_main_R)
}

technique CrawlRollFix_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_effect)
   pass P_2 ExecuteShader (ps_main_C)
}

technique CrawlRollFix_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_video)
   pass P_2 ExecuteShader (ps_main_R)
}

technique CrawlRollFix_3
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_video)
   pass P_2 ExecuteShader (ps_main_C)
}

