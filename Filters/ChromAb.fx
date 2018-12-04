// @Maintainer jwrl
// @Released 2018-12-04
// @Author josely
// @Created 2012-06-29
// @see https://www.lwks.com/media/kunena/attachments/6375/ChromAb_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromAb.fx
//
// Chromatic Abberation Copyright (c) Johannes Bausch (josely). All rights reserved.
//
// This cross-platform conversion by jwrl April 28, 2016
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 4 December 2018 jwrl.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "JB's Chromatic Abberation";
   string Category    = "Stylize";
   string SubCategory = "Technical";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler texColor = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.10;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define STEPS   12
#define STEPS_2 24               // STEPS * 2
#define STEPS_3 36               // STEPS * 3
#define STEP_RB 1.846            // STEPS / (1 - 0.5 * (STEPS + 1) + STEPS)

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_half (float2 uv : TEXCOORD1) : COLOR
{
   float4 fragColor = float4 (0.0, 0.0, 0.0, 1.0);

   float2 xy, color, coord = uv - 0.5.xx;

   float Scale, multiplier = length (coord) * (Amount / 100.0);

   coord *= multiplier;

   for (int i = 0; i < STEPS; i ++) {
      xy = uv - (i * coord);
      Scale = (float) i / STEPS;
      color = tex2D (texColor, xy).rg / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.rg += color.xy;
   }

   for (int i = STEPS; i <= STEPS_2; i ++) {
      xy = uv - (i * coord);
      Scale = (float) (i - STEPS) / STEPS;
      color = tex2D (texColor, xy).gb / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.gb += color.xy;
   }

   fragColor.rb *= STEP_RB;   // Half cycle correction

   return fragColor;
}

float4 ps_main_full (float2 uv : TEXCOORD1) : COLOR
{
   float4 fragColor = float4 (0.0, 0.0, 0.0, 1.0);

   float2 xy, color, coord = uv - 0.5.xx;

   float Scale, multiplier = length (coord) * (Amount / 50.0);

   coord *= multiplier;

   for (int i = 0; i < STEPS; i ++) {
      xy = uv - (i * coord);
      Scale = (float) i / STEPS;
      color = tex2D (texColor, xy).rg / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.rg += color.xy;
   }

   for (int i = STEPS; i <= STEPS_2; i ++) {
      xy = uv - (i * coord);
      Scale = (float) (i - STEPS) / STEPS;
      color = tex2D (texColor, xy).gb / STEPS;
      color.x *= (1.0 - Scale);
      color.y *= Scale;
      fragColor.gb += color.xy;
   }

   for (int i = STEPS_2; i < STEPS_3; i ++) {
      xy = uv - (i * coord);
      Scale = (float) (i - STEPS_2) / STEPS;
      color = tex2D (texColor, xy).br / STEPS;
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
   pass Single_Pass
   {
      PixelShader = compile PROFILE ps_main_half ();
   }
}

technique Full
{
   pass Single_Pass
   {
      PixelShader = compile PROFILE ps_main_full ();
   }
}
