// @Maintainer jwrl
// @Released 2018-12-27
// @Author jwrl
// @Created 2018-05-23
// @see https://www.lwks.com/media/kunena/attachments/6375/NightVision_640.png

/**
This effect uses three possible profiles.  One partially inverts red, one partially inverts
blue, and the third takes the red channel of an image and partially subtracts blue and
green channels from it.  Highlights are then burned out, gamma is adjusted and video noise
added.  Finally the image is softened and coloured green.  Because this type of effect will
always be subjective, highlight burnout, gamma, grain, softness and green saturation are
all adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Night_Vision.fx
//
// This effect is a rewrite of my NightVision.fx from 2016.
//
// The blur and glow engines in that effect are a variant of my own radial blur.  While
// fairly GPU intensive they are more precise and allow a reduction in the number of
// passes required, so they have been retained.  In fact apart from some general code
// cleanup the major changes to the original are a revised profile 1 shader and the use
// of SetTechnique instead of using in-shader conditionals.
//
// Modified 2018-07-07 jwrl:
// Made glow resolution independent.
//
// Modified 7 December 2018 jwrl.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Night vision";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates infra-red night time photography";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

texture Gnoise : RenderColorTarget;
texture Glow_1 : RenderColorTarget;
texture Glow_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Input>; };
sampler s_Gnoise = sampler_state { Texture = <Gnoise>; };

sampler s_Glow_1 = sampler_state
{
   Texture   = <Glow_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Glow_2 = sampler_state
{
   Texture   = <Glow_2>;
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
   string Description = "Filter";
   string Enum = "Profile 1,Profile 2,Profile 3";
> = 0;

float Burn
<
   string Description = "Burnout";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Gamma
<
   string Description = "Gamma";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float Grain
<
   string Description = "Grain";
   float MinVal       = 0.00;
   float MaxVal       = 1.00;
> = 0.3333;

float Blur
<
   string Description = "Softness";
   float MinVal       = 0.0;
   float MaxVal       = 1.00;
> = 0.3333;

float Saturation
<
   string Description = "Saturation";
   float MinVal       = 0.0;
   float MaxVal       = 1.00;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LUMA     float3(0.2989, 0.5866, 0.1145)
#define GB_LUMA  float2(0.81356, 0.18644)

#define P1_SCALE 3.0
#define P2_SCALE 1.54576
#define P3_SCALE 0.5

#define KNEE     0.85
#define KNEE_FIX 5.6666666667

#define LOOP     9
#define DIVIDE   73

#define RADIUS_1 0.002
#define RADIUS_2 2.5

#define ANGLE    0.3490658504

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_noise (float2 xy : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy);

   float2 uv = saturate (xy + float2 (0.00013, 0.00123));
   float rand = frac ((dot (uv, float2 (uv.x + 123.0, uv.y + 13.0)) * ((Fgnd.g + 1.0) * uv.x)) + _Progress);

   rand = (rand * 1000.0) + sin (uv.x) + cos (uv.y);

   return saturate (frac (fmod (rand, 13.0) * fmod (rand, 123.0))).xxxx;
}

float4 ps_luma_0 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   float luma  = dot (Fgnd.rgb, LUMA);
   float gamma = (Gamma > 0.0) ? Gamma * 0.8 : Gamma * 4.0;

   luma = abs (luma - Fgnd.b) * P1_SCALE;
   luma = saturate (pow (luma, (1.0 - gamma)));

   return float4 (luma.xxx, Fgnd.a);
}

float4 ps_luma_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   float luma = abs (dot (Fgnd.gb, GB_LUMA) - (Fgnd.r * P2_SCALE));
   float gamma = (Gamma > 0.0) ? Gamma * 0.8 : Gamma * 4.0;

   luma = saturate (pow (luma, (1.0 - gamma)));

   return float4 (luma.xxx, Fgnd.a);
}

float4 ps_luma_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   float luma  = dot (Fgnd.gb, GB_LUMA);
   float reds  = Fgnd.r * (2.0 - Fgnd.r);
   float gamma = (Gamma * 0.75) - 0.25;

   if (luma > KNEE) { luma = (1.0 - luma) * KNEE_FIX; }

   gamma *= (gamma > 0.0) ? 0.8 : 4.0;
   luma   = saturate (reds - (luma * P3_SCALE));
   luma   = saturate (pow (luma, (1.0 - gamma)));

   return float4 (luma.xxx, Fgnd.a);
}

float4 ps_glow (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Glow_1, uv);
   float4 retval = Fgnd;

   float2 radius = float2 (1.0, _OutputAspectRatio) * RADIUS_1;
   float2 xy1, xy2;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy1.x, xy1.y);
      xy1 *= radius;
      xy2 = float2 (-xy1.x, xy1.y) * RADIUS_2;
      retval += tex2D (s_Glow_1, uv + xy1);
      retval += tex2D (s_Glow_1, uv - xy1);
      retval += tex2D (s_Glow_1, uv + xy2);
      retval += tex2D (s_Glow_1, uv - xy2);
      xy1 += xy1;
      xy2 += xy2;
      retval += tex2D (s_Glow_1, uv + xy1);
      retval += tex2D (s_Glow_1, uv - xy1);
      retval += tex2D (s_Glow_1, uv + xy2);
      retval += tex2D (s_Glow_1, uv - xy2);
   }

   retval = saturate (Fgnd + (retval * Burn / DIVIDE));

   float3 vid_grain = tex2D (s_Gnoise, (uv / 3.0)).rgb + retval.rgb - 0.5.xxx;

   return float4 (lerp (retval.rgb, vid_grain, Grain), retval.a);
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Glow_2, uv);

   if (Blur > 0.0) {
      float2 radius = float2 (1.0, _OutputAspectRatio) * Blur * RADIUS_1;
      float2 blur = retval.ga;
      float2 xy1, xy2;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy1.x, xy1.y);
         xy1 *= radius;
         xy2 = float2 (-xy1.x, xy1.y) * RADIUS_2;
         blur += tex2D (s_Glow_2, uv + xy1).ga;
         blur += tex2D (s_Glow_2, uv - xy1).ga;
         blur += tex2D (s_Glow_2, uv + xy2).ga;
         blur += tex2D (s_Glow_2, uv - xy2).ga;
         xy1 += xy1;
         xy2 += xy2;
         blur += tex2D (s_Glow_2, uv + xy1).ga;
         blur += tex2D (s_Glow_2, uv - xy1).ga;
         blur += tex2D (s_Glow_2, uv + xy2).ga;
         blur += tex2D (s_Glow_2, uv - xy2).ga;
      }

      retval = saturate (blur / DIVIDE).xxxy;
   }

   retval.rb  = retval.gg * float2 (0.2, 0.6);

   return float4 (lerp (retval.ggg, retval.rgb, Saturation), retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique nightVision_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Gnoise;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_luma_0 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique nightVision_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = Gnoise;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_luma_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique nightVision_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = Gnoise;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_luma_2 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
