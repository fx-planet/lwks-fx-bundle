// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blur_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blur.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Blur.fx
//
// This effect is used to transition into or out of a title and composite the result
// over a background layer.
//
// During the process it also applies a directional blur, the angle and strength of
// which can be independently set for both the incoming and outgoing vision sources.
// A setting to tie both incoming and outgoing blurs together is also provided.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_Blur.fx, which provided the ability to
// dissolve between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha blur dissolve";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Directionally blurs a title as it fades in or out";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

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
   string Description = "Transition";
   string Enum = "Blur in,Blur out,";
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SAMPLES   60
#define SAMPSCALE 61

#define STRENGTH  0.01

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Super, uv);

   if (BlurSpread == 0.0) return Fgnd;

   float2 blurOffset, xy = uv;

   sincos (radians (BlurAngle + 180), blurOffset.y, blurOffset.x);
   blurOffset *= (BlurSpread * (1.0 - Amount) * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      xy += blurOffset;
      Fgnd += tex2D (s_Super, xy);
   }

   Fgnd = saturate (Fgnd / SAMPSCALE);

   if (Boost == 0) {
      Fgnd.a    = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   Fgnd.a *= saturate (((Amount - 0.5) * ((BlurStrength * 3.0) + 1.5)) + 0.5);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Super, uv);

   if (BlurSpread == 0.0) return Fgnd;

   float2 blurOffset, xy = uv;

   sincos (radians (BlurAngle), blurOffset.y, blurOffset.x);
   blurOffset *= (BlurSpread * Amount * STRENGTH);

   for (int i = 0; i < SAMPLES; i++) {
      xy += blurOffset;
      Fgnd += tex2D (s_Super, xy);
   }

   Fgnd = saturate (Fgnd / SAMPSCALE);

   if (Boost == 0) {
      Fgnd.a    = pow (Fgnd.a, 0.5);
      Fgnd.rgb /= Fgnd.a;
   }

   Fgnd.a *= 1.0 - saturate (((Amount - 0.5) * ((BlurStrength * 3.0) + 1.5)) + 0.5);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Blur_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Blur_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}
