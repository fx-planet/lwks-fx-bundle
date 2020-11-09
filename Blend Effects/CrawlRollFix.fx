// @Maintainer jwrl
// @Released 2020-11-08
// @Author jwrl
// @Created 2020-07-19
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
// Update 2020-11-08 jwrl.
// Added CanSize switch for 2021 support.
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
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define STRENGTH  0.00125

float _OutputAspectRatio;

float _gaussian[] = { 0.2255859375, 0.193359375, 0.120849609375, 0.0537109375, 0.01611328125, 0.0029296875, 0.000244140625 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_effect (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   retval.a    = pow (retval.a, 0.5);
   retval.rgb /= retval.a;

   return retval;
}

float4 ps_video (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Foreground, uv);
}

float4 ps_main_R (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Title, xy1) * _gaussian [0];

   float2 uv = float2 (0.0, Smoothing * _OutputAspectRatio * STRENGTH);
   float2 xy = xy1 + uv;

   Fgnd += tex2D (s_Title, xy) * _gaussian [1];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [2];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [3];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [4];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [5];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [6];

   xy = xy1 - uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [1];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [2];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [3];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [4];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [5];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_main_C (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Title, xy1) * _gaussian [0];

   float2 uv = float2 (Smoothing * STRENGTH, 0.0);
   float2 xy = xy1 + uv;

   Fgnd += tex2D (s_Title, xy) * _gaussian [1];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [2];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [3];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [4];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [5];
   xy += uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [6];

   xy = xy1 - uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [1];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [2];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [3];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [4];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [5];
   xy -= uv;
   Fgnd += tex2D (s_Title, xy) * _gaussian [6];

   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
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
