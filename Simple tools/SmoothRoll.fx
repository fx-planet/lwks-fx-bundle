// @Maintainer jwrl
// @Released 2020-01-05
// @Author jwrl
// @Created 2020-01-05
// @see https://www.lwks.com/media/kunena/attachments/6375/SmoothRoll_640.png

/**
 This effect provides a simple means of smoothing the movement of a credit roll or crawl.
 It does this by applying a small amount of directional blur to the title.  No action is
 required apart from adjusting the smoothing to give the best looking result.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SmoothRoll.fx
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

#define SAMPLES   15
#define SAMPSCALE 31

#define STRENGTH  0.000675

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
   float4 Fgnd = tex2D (s_Title, xy1);

   float2 xy = 0.0.xx;

   float blurOffset = Smoothing * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      xy.y += blurOffset;
      Fgnd += tex2D (s_Title, xy - xy1);
      Fgnd += tex2D (s_Title, xy + xy1);
   }

   Fgnd  /= SAMPSCALE;
   Fgnd.a = pow (Fgnd.a, 0.5);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_main_C (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Title, xy1);

   float2 xy = 0.0.xx;

   float blurOffset = Smoothing * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      xy.x += blurOffset;
      Fgnd += tex2D (s_Title, xy - xy1);
      Fgnd += tex2D (s_Title, xy + xy1);
   }

   Fgnd  /= SAMPSCALE;
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

