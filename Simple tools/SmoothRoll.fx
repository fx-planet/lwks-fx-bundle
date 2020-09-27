// @Maintainer jwrl
// @Released 2020-09-07
// @Author jwrl
// @Created 2020-01-05
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
// Update 2020-09-27 jwrl.
// Modified header block.
//
// Modified 6 January 2020 by user jwrl:
// Changed blur from linear to a bi-directional 6 tap gaussian blur.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Smooth roll";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "Directionally blurs a roll or crawl to smooth its motion";
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define STRENGTH  0.00125

float _OutputAspectRatio;

float _gaussian[] = { 0.2255859375, 0.193359375, 0.120849609375, 0.0537109375, 0.01611328125, 0.0029296875, 0.000244140625 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, 0.25, kDiff));
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

technique SmoothRoll_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_R (); }
}

technique SmoothRoll_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_C (); }
}
