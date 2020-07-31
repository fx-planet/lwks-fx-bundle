// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Wave_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Wave.mp4

/**
 This an alpha transition that splits a delta key into sinusoidal strips or waves and
 compresses them to or expands them from zero height.  The vertical centring can be
 adjusted so that the title expands symmetrically.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WaveCollapse_Adx.fx
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Moved folded effect support into "Transition position".
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//
// Modified jwrl 2018-12-28
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Wave collapse (delta)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Separates foreground from background then expands or compresses it to sinusoidal strips or waves";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Super : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Super = sampler_state
{
   Texture   = <Super>;
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
> = 0;

float Spacing
<
   string Group = "Waves";
   string Description = "Spacing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Group = "Waves";
   string Description = "Vertical centre";
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

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

#define EMPTY    (0.0).xxxx

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

float4 ps_keygen_F (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgnd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgnd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   return float4 (Bgnd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgnd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgnd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   return float4 (Fgnd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_F (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (HALF_PI - (Amount * HALF_PI))) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (xy1.x + (sin (Width * xy1.y * PI) * (1.0 - Amount)));
   xy.y = saturate (((xy1.y - centreY) * Height) + centreY);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Foreground, xy2), Fgnd, Fgnd.a * saturate (Amount * 5.0));
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (Amount * HALF_PI)) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (xy1.x + (sin (Width * xy1.y * PI) * Amount));
   xy.y = saturate (((xy1.y - centreY) * Height) + centreY);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a * saturate ((1.0 - Amount) * 5.0));
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (HALF_PI - (Amount * HALF_PI))) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (xy1.x + (sin (Width * xy1.y * PI) * (1.0 - Amount)));
   xy.y = saturate (((xy1.y - centreY) * Height) + centreY);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a * saturate (Amount * 5.0));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WaveCollapse_Adx_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique WaveCollapse_Adx_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique WaveCollapse_Adx_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}
