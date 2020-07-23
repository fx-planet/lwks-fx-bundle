// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blur_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blur.mp4

/**
 This effect applies a directional blur to the title, the angle and strength of which
 can be adjusted.  It then progressively reduces the blur to reveal the key or increases
 the blur of the key as it fades it out.

 IMPORTANT NOTE:  WHEN USED WITH THE MICROSOFT WINDOWS OPERATING SYSTEM THIS EFFECT IS
 ONLY SUITABLE FOR LIGHTWORKS VERSION 14.5 AND BETTER.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlurDissolve_Adx.fx
//
// Version history:
//
// Modified 2020-07-23:
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
   string Description = "Blur dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Separates foreground from background and directionally blurs it as it fades in or out";
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
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
> = 0;

float BlurAngle
<
   string Group = "Blur settings";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float BlurStrength
<
   string Group = "Blur settings";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float BlurSpread
<
   string Group = "Blur settings";
   string Description = "Spread";
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

#ifndef _LENGTH   // This effect is only available for version 14.5 and up
Bad_LW_version    // Forces a compiler error if the Lightworks version is less.
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SAMPLES   60
#define SAMPSCALE 61

#define STRENGTH  0.01

#define EMPTY     0.0.xxxx

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

float4 ps_main_F (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Title, xy1);

   if (BlurSpread == 0.0) return Fgnd;

   float2 blurOffset, xy = xy1;

   sincos (radians (BlurAngle + 180), blurOffset.y, blurOffset.x);
   blurOffset *= (BlurSpread * (1.0 - Amount) * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      xy += blurOffset;
      Fgnd += fn_tex2D (s_Title, xy);
   }

   Fgnd = saturate (Fgnd / SAMPSCALE);
   Fgnd.a *= saturate (((Amount - 0.5) * ((BlurStrength * 3.0) + 1.5)) + 0.5);

   return lerp (tex2D (s_Foreground, xy2), Fgnd, Fgnd.a);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Title, xy1);

   if (BlurSpread == 0.0) return Fgnd;

   float2 blurOffset, xy = xy1;

    sincos (radians (BlurAngle), blurOffset.y, blurOffset.x);
   blurOffset *= (BlurSpread * Amount * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      xy += blurOffset;
      Fgnd += fn_tex2D (s_Title, xy);
   }

   Fgnd = saturate (Fgnd / SAMPSCALE);
   Fgnd.a *= 1.0 - saturate (((Amount - 0.5) * ((BlurStrength * 3.0) + 1.5)) + 0.5);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Title, xy1);

   if (BlurSpread == 0.0) return Fgnd;

   float2 blurOffset, xy = xy1;

   sincos (radians (BlurAngle + 180), blurOffset.y, blurOffset.x);
   blurOffset *= (BlurSpread * (1.0 - Amount) * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      xy += blurOffset;
      Fgnd += fn_tex2D (s_Title, xy);
   }

   Fgnd = saturate (Fgnd / SAMPSCALE);
   Fgnd.a *= saturate (((Amount - 0.5) * ((BlurStrength * 3.0) + 1.5)) + 0.5);

   return lerp (tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BlurDissolve_Adx_F
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_F (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique BlurDissolve_Adx_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique BlurDissolve_Adx_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}
