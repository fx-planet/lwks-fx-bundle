// @Maintainer jwrl
// @Released 2020-07-22
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Transmogrify_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Transmogrify.mp4

/**
 This is a truly bizarre transition which can transition into or out of a delta key.
 The outgoing delta key is blown apart into individual pixels which then swirl away.
 The incoming key materialises from a pixel cloud.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transmogrify_Adx.fx
//
// Version history:
//
// Modified jwrl 2020-07-22
// Improved support for unfolded effects.
// Corrected a bug that would have affected particle position on Linux/OS-X.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//
// Modified jwrl 2018-12-23
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Transmogrify (delta)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Separates foreground from background and breaks it into a cloud of particles which waft apart";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Key : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Key = sampler_state
{
   Texture   = <Key>;
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

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SCALE 0.000545

#define EMPTY (0.0).xxxx

float _OutputAspectRatio;
float _Progress;

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
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_F (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = uv * float2 (1.0, _OutputAspectRatio) * SCALE;

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);

   float4 Fgnd = fn_tex2D (s_Key, lerp (float2 (xy.x, 1.0 - xy.y), uv, Amount));

   return lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = uv * float2 (1.0, _OutputAspectRatio) * SCALE;

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float2 xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);

   float4 Fgnd = fn_tex2D (s_Key, lerp (float2 (xy.x, 1.0 - xy.y), uv, Amount));

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixSize = uv * float2 (1.0, _OutputAspectRatio) * SCALE;

   float rand = (uv * frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754)) - 0.5;

   pixSize += rand.xx;

   float4 Fgnd = fn_tex2D (s_Key, lerp (uv, saturate (pixSize + sqrt (_Progress).xx), Amount));

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Transmogrify_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique Adx_Transmogrify_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique Adx_Transmogrify_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}
