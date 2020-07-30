// @Maintainer jwrl
// @Released 2020-07-30
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Stretch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Stretch.mp4

/**
 This effect stretches a delta key horizontally or vertically to transition in or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Stretch_Adx.fx
//
// Version history:
//
// Modified 2020-07-30 jwrl.
// Moved folded effect support into "Transition position".
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
   string Description = "Stretch dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Separates foreground from background then stretches it horizontally or vertically";
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
   string Enum = "At start (horizontal),At end (horizontal),At start (vertical),At end (vertical),H start (unfolded),V start (unfolded)";
> = 0;

float Stretch
<
   string Description = "Size";
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

#define CENTRE  (0.5).xx
#define EMPTY   (0.0).xxxx

#define PI      3.1415926536
#define HALF_PI 1.5707963268

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

float4 ps_horiz_F (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_horiz_O (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y  = lerp (xy.y, distort, stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_vert_F (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Foreground, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_vert_O (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x  = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

float4 ps_horiz_I (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_vert_I (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);

   float4 Fgnd = fn_tex2D (s_Super, xy + CENTRE);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Hstretch_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_horiz_F (); }
}

technique Adx_Hstretch_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_horiz_O (); }
}

technique Adx_Vstretch_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_vert_F (); }
}

technique Adx_Vstretch_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_vert_O (); }
}

technique Adx_Hstretch_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_horiz_I (); }
}

technique Adx_Vstretch_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_vert_I (); }
}
