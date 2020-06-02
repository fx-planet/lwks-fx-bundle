// @Maintainer jwrl
// @Released 2020-06-02
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
// Modified jwrl 2018-12-28
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
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

bool Ftype
<
   string Description = "Folded effect";
> = true;

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
   float3 Fgnd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgnd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   return Ftype ? float4 (Bgnd, smoothstep (0.0, KeyGain, kDiff))
                : float4 (Fgnd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgnd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgnd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   return float4 (Fgnd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = Ftype ? tex2D (s_Foreground, uv) : tex2D (s_Background, uv);

   float3 warp = (Bgnd.rgb - 0.5.xxx) * Distortion * 4.0;

   float2 xy;

   float Amt = 1.0 - sin (Amount * HALF_PI);

   xy.x = saturate (uv.x + (warp.y - 0.5) * Amt);
   Amt *= 2.0;
   xy.y = saturate (uv.y + (warp.z - warp.x) * Amt);

   float4 Fgnd = fn_tex2D (s_Title, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 Bgnd = tex2D (s_Background, uv);

   float3 warp = (Bgnd.rgb - 0.5.xxxx) * Distortion * 4.0;

   float2 xy;

   float Amt = 1.0 - cos (Amount * HALF_PI);

   xy.y = saturate (uv.y + (0.5 - warp.x) * Amt);
   Amt *= 2.0;
   xy.x = saturate (uv.x + (warp.y - warp.z) * Amt);

   float4 Fgnd = fn_tex2D (s_Title, xy);

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
