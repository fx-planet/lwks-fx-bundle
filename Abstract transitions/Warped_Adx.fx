// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Warp_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Warp.mp4

/**
This effect warps a delta key to reveal or remove titles or other supers from the video
background.  The warp pattern is driven by the background image, so it will be different
each time that it's used.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Warped_Adx.fx
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Warped dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Separates foreground from background then warps it to reveal or remove it";
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

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

float Distortion
<
   string Description = "Distortion";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268

#define EMPTY   (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Bgnd = tex2D (s_Background, xy1).rgb;
   float3 Fgnd = tex2D (s_Foreground, xy2).rgb;

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   return float4 (Bgnd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Bgnd = tex2D (s_Background, xy1).rgb;
   float3 Fgnd = tex2D (s_Foreground, xy2).rgb;

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   return float4 (Fgnd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Bgnd = tex2D (s_Foreground, xy2);
   float4 Fgnd = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy;

   float Amt = 1.0 - sin (Amount * HALF_PI);

   xy.x = saturate (xy1.x + (Fgnd.y - 0.5) * Amt);
   Amt *= 2.0;
   xy.y = saturate (xy1.y + (Fgnd.z - Fgnd.x) * Amt);
   Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 Fgnd = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy;

   float Amt = 1.0 - cos (Amount * HALF_PI);

   xy.y = saturate (xy1.y + (0.5 - Fgnd.x) * Amt);
   Amt *= 2.0;
   xy.x = saturate (xy1.x + (Fgnd.y - Fgnd.z) * Amt);
   Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Warped_Adx_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Warped_Adx_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

