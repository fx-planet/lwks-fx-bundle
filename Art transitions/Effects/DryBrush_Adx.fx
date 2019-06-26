// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DryBrush_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DryBrush.mp4

/**
This mimics the Photoshop angled brush stroke effect to reveal or remove a delta key.
The stroke length and angle can be independently adjusted, and can be keyframed while
the transition progresses to make the effect more dynamic.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrush_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dry brush mix (delta)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Separates foreground from background then mimics the Photoshop angled brush effect to reveal or remove it";
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

float Length
<
   string Description = "Stroke length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Angle
<
   string Description = "Stroke angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 45.0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  (0.0).xxxx

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
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = frac (sin (dot ((uv1 - 0.5.xx), float2 (12.9898, 78.233))) * 43758.5453);
   float2 xy, xy2;

   xy1 *= stroke * (1.0 - Amount);
   sincos (angle, xy2.x, xy2.y);

   xy.x = xy1.x * xy2.x + xy1.y * xy2.y;
   xy.y = xy1.y * xy2.x - xy1.x * xy2.y;

   float4 Fgnd = fn_tex2D (s_Title, uv1 + xy);

   return lerp (tex2D (s_Foreground, uv2), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = frac (sin (dot ((uv1 - 0.5.xx), float2 (12.9898, 78.233))) * 43758.5453);
   float2 xy, xy2;

   xy1 *= stroke * Amount;
   sincos (angle, xy2.x, xy2.y);

   xy.x = xy1.x * xy2.x + xy1.y * xy2.y;
   xy.y = xy1.y * xy2.x - xy1.x * xy2.y;

   float4 Fgnd = fn_tex2D (s_Title, uv1 + xy);

   return lerp (tex2D (s_Background, uv2), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_DryBrush_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_DryBrush_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

