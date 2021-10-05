// @Maintainer jwrl
// @Released 2021-10-05
// @Author josely
// @Created 2012-06-29
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromAb_640.png

/**
 Generates or removes chromatic aberration.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromaticAberration.fx
//
// Chromatic Abberation Copyright (c) Johannes Bausch (josely). All rights reserved.
//
// Version history:
//
// Update 2021-10-05 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Update 2020-11-12 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// This cross-platform conversion by jwrl April 28, 2016
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromatic aberration";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Generates or removes chromatic aberration";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define STEPS   12
#define STEPS_2 24               // STEPS * 2
#define STEPS_3 36               // STEPS * 3
#define STEP_RB 1.846            // STEPS / (1 - 0.5 * (STEPS + 1) + STEPS)

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Chromatic Band";
   string Enum = "Half,Full";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main_half (float2 uv : TEXCOORD2) : COLOR
{
   float4 fragColor = float4 (0.0, 0.0, 0.0, 1.0);

   float2 xy, color, coord = uv - 0.5.xx;

   float Scale, multiplier = length (coord) * (Amount / 100.0);

   coord *= multiplier;

   for (int i = 0; i < STEPS; i ++) {
      xy = uv - (i * coord);
      Scale = (float) i / STEPS;
      color = tex2D (s_Input, xy).rg / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.rg += color.xy;
   }

   for (int i = STEPS; i <= STEPS_2; i ++) {
      xy = uv - (i * coord);
      Scale = (float) (i - STEPS) / STEPS;
      color = tex2D (s_Input, xy).gb / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.gb += color.xy;
   }

   fragColor.rb *= STEP_RB;   // Half cycle correction

   return fragColor;
}

float4 ps_main_full (float2 uv : TEXCOORD2) : COLOR
{
   float4 fragColor = float4 (0.0, 0.0, 0.0, 1.0);

   float2 xy, color, coord = uv - 0.5.xx;

   float Scale, multiplier = length (coord) * (Amount / 50.0);

   coord *= multiplier;

   for (int i = 0; i < STEPS; i ++) {
      xy = uv - (i * coord);
      Scale = (float) i / STEPS;
      color = tex2D (s_Input, xy).rg / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.rg += color.xy;
   }

   for (int i = STEPS; i <= STEPS_2; i ++) {
      xy = uv - (i * coord);
      Scale = (float) (i - STEPS) / STEPS;
      color = tex2D (s_Input, xy).gb / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.gb += color.xy;
   }

   for (int i = STEPS_2; i < STEPS_3; i ++) {
      xy = uv - (i * coord);
      Scale = (float) (i - STEPS_2) / STEPS;
      color = tex2D (s_Input, xy).br / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.br += color.xy;
   }

   return fragColor;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Half
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_half)
}

technique Full
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_full)
}

