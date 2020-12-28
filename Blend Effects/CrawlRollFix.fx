// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-12-28
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
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
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

#define STRENGTH  0.00125

float _OutputAspectRatio;

float _gaussian[] = { 0.2255859375, 0.193359375, 0.120849609375, 0.0537109375, 0.01611328125, 0.0029296875, 0.000244140625 };

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Title, s_Title);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Disconnect LW roll or crawl inputs first!";
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

float4 ps_effect (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = fn_tex2D (s_Foreground, uv);

   retval.a    = pow (retval.a, 0.5);
   retval.rgb /= retval.a;

   return retval;
}

float4 ps_video (float2 uv : TEXCOORD1) : COLOR
{
   return fn_tex2D (s_Foreground, uv);
}

float4 ps_main_R (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Title, xy1) * _gaussian [0];

   float2 uv = float2 (0.0, Smoothing * _OutputAspectRatio * STRENGTH);
   float2 xy = xy1 + uv;

   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [1];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [2];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [3];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [4];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [5];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [6];

   xy = xy1 - uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [1];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [2];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [3];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [4];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [5];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (fn_tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_main_C (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Title, xy1) * _gaussian [0];

   float2 uv = float2 (Smoothing * STRENGTH, 0.0);
   float2 xy = xy1 + uv;

   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [1];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [2];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [3];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [4];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [5];
   xy += uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [6];

   xy = xy1 - uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [1];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [2];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [3];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [4];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [5];
   xy -= uv;
   Fgnd += fn_tex2D (s_Title, xy) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (fn_tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique CrawlRollFix_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_effect (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_R (); }
}

technique CrawlRollFix_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_effect (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_C (); }
}

technique CrawlRollFix_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_video (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_R (); }
}

technique CrawlRollFix_3
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_video (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_C (); }
}
