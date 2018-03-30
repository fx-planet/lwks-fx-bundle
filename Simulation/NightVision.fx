//--------------------------------------------------------------//
// Lightworks user effect NightVision.fx
//
// Created by LW user jwrl 16 April 2016
// Updated by LW user jwrl 30 August 2016.
//
// The blur and glow engines in this version of the effect are
// a total rewrite, replacing the original Editshare versions
// previously used with a variant of my own radial blur.  While
// more GPU intensive it's also more precise and has allowed a
// reduction in the number of passes required.
//
// While updating this a bug was found in the profile 3 code
// which, while minor, affected the simulation significantly.
// That has now been fixed.
//
// Version 14 update 18 Feb 2017 by jwrl:
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//
// Cross platform compatibility check 3 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly defined float3 and float4 variables to address
// the behavioural difference between the D3D and Cg compilers.
//
// Removed overloading of "grain" variable.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Night vision";
   string Category    = "Stylize";
   string SubCategory = "Simulation";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

texture Gnoise : RenderColorTarget;
texture Glow_1 : RenderColorTarget;
texture Glow_2 : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler noiSampler = sampler_state
{
   Texture   = <Gnoise>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler g1_Sampler = sampler_state
{
   Texture   = <Glow_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler g2_Sampler = sampler_state
{
   Texture   = <Glow_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

int IRfilter
<
   string Description = "Filter";
   string Enum = "Profile 1,Profile 2,Profile 3";
> = 0;

float burn
<
   string Description = "Burnout";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float gamma
<
   string Description = "Gamma";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float grain
<
   string Description = "Grain";
   float MinVal       = 0.00;
   float MaxVal       = 1.00;
> = 0.3333;

float blurriness
<
   string Description = "Softness";
   float MinVal       = 0.0;
   float MaxVal       = 1.00;
> = 0.3333;

float saturation
<
   string Description = "Saturation";
   float MinVal       = 0.0;
   float MaxVal       = 1.00;
> = 1.0;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define R_LUMA   1.2
#define G_LUMA   0.81356
#define B_LUMA   0.18644
#define GB_SCALE 0.5

#define R_OFFSET 1.54576
#define B_OFFSET 0.81356

#define KNEE     0.85
#define KNEE_FIX 5.66667

#define RANGE    0.3
#define SOFT     0.5
#define MAXRANGE 0.8

#define LOOP     9
#define DIVIDE   73

#define RADIUS_1 4.0
#define RADIUS_2 2.5

#define ANGLE    0.34907

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_noise (float2 xy : TEXCOORD1) : COLOR
{
   float4 Fg = tex2D (InputSampler, xy);

   float2 uv = saturate (xy + float2 (0.00013, 0.00123));
   float rand = frac ((dot (uv, float2 (uv.x + 123, uv.y + 13)) * ((Fg.g + 1.0) * uv.x)) + _Progress);

   rand = (rand * 1000) + sin (uv.x) + cos (uv.y);

   return saturate (frac (fmod (rand, 13) * fmod (rand, 123))).xxxx;
}

float4 ps_luma (float2 xy : TEXCOORD1) : COLOR
{
   float4 Fg = tex2D (InputSampler, xy);
   float luma, Gamma;

   if (IRfilter < 2) {
      Gamma = gamma;
      luma = (IRfilter == 0) ? abs ((Fg.r * R_LUMA) + (Fg.g * G_LUMA) - (Fg.b * R_OFFSET))
                             : abs ((Fg.b * B_LUMA) + (Fg.g * G_LUMA) - (Fg.r * R_OFFSET));
   }
   else {
      float reds = 1.0 - Fg.r;

      Gamma = (gamma * 0.75) - 0.25;
      luma = (Fg.g * G_LUMA) + (Fg.b * B_LUMA);

      if (luma > KNEE) { luma = (1.0 - luma) * KNEE_FIX; }

      reds = 1.0 - (reds * reds);
      luma = saturate (reds - (luma * GB_SCALE));
   }

   float _gamma = (Gamma > 0.0) ? Gamma * 0.8 : Gamma * 4.0;

   luma = saturate (pow (luma, (1.0 - _gamma)));

   return float4 (luma.xxx, Fg.a);
}

float4 ps_glow (float2 xy : TEXCOORD1) : COLOR
{
   float4 Fg = tex2D (g1_Sampler, xy);
   float4 retval = Fg;

   float2 radius = float2 (1.0, _OutputAspectRatio) * RADIUS_1 / _OutputWidth;
   float2 uv1, uv2;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), uv1.x, uv1.y);
      uv1 *= radius;
      uv2 = float2 (-uv1.x, uv1.y) * RADIUS_2;
      retval += tex2D (g1_Sampler, xy + uv1);
      retval += tex2D (g1_Sampler, xy - uv1);
      retval += tex2D (g1_Sampler, xy + uv2);
      retval += tex2D (g1_Sampler, xy - uv2);
      uv1 += uv1;
      uv2 += uv2;
      retval += tex2D (g1_Sampler, xy + uv1);
      retval += tex2D (g1_Sampler, xy - uv1);
      retval += tex2D (g1_Sampler, xy + uv2);
      retval += tex2D (g1_Sampler, xy - uv2);
   }

   retval = saturate (Fg + (retval * burn / DIVIDE));

   float3 vid_grain = tex2D (noiSampler, (xy / 3.0)).rgb + retval.rgb - 0.5.xxx;

   return float4 (lerp (retval.rgb, vid_grain, grain), retval.a);
}

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (g2_Sampler, xy);

   if (blurriness > 0.0) {
      float2 radius = float2 (1.0, _OutputAspectRatio) * RADIUS_1 * blurriness / _OutputWidth;
      float2 blur = retval.ga;
      float2 uv1, uv2;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), uv1.x, uv1.y);
         uv1 *= radius;
         uv2 = float2 (-uv1.x, uv1.y) * RADIUS_2;
         blur += tex2D (g2_Sampler, xy + uv1).ga;
         blur += tex2D (g2_Sampler, xy - uv1).ga;
         blur += tex2D (g2_Sampler, xy + uv2).ga;
         blur += tex2D (g2_Sampler, xy - uv2).ga;
         uv1 += uv1;
         uv2 += uv2;
         blur += tex2D (g2_Sampler, xy + uv1).ga;
         blur += tex2D (g2_Sampler, xy - uv1).ga;
         blur += tex2D (g2_Sampler, xy + uv2).ga;
         blur += tex2D (g2_Sampler, xy - uv2).ga;
      }

      retval = saturate (blur / DIVIDE).xxxy;
   }

   retval.rb  = retval.gg * float2 (0.2, 0.6);

   return float4 (lerp (retval.ggg, retval.rgb, saturation), retval.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique nightVision
{
   pass P_1
   < string Script = "RenderColorTarget0 = Gnoise;"; >
   { PixelShader = compile PROFILE ps_noise (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Glow_1;"; >
   { PixelShader = compile PROFILE ps_luma (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Glow_2;"; >
   { PixelShader = compile PROFILE ps_glow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

