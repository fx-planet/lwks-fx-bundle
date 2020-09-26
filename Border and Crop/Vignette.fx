// @Maintainer jwrl
// @Released 2019-09-26
// @Author juhartik
// @AuthorEmail "juha@linearteam.org"
// @Created 2011-04-29
// @see https://www.lwks.com/media/kunena/attachments/6375/jh_stylize_vignette_640.png

/**
 A lens vignette effect created by Juha Hartikainen
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Vignette.fx
//
// Version history:
//
// Update 2020-09-26 jwrl.
// Reformatted header block.
//
// Modified 6 January 2019 jwrl.
// Added colour setting for the surround.
// Changed default values of radius and amount.
// Renamed "Softness" to "Hardness" because reducing the value increases the softness.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Changed category and subcategory.
// Changed name from jh_stylize_vignette.fx to Vignette.fx.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified by LW user jwrl 4 April 2018.
// Metadata header block added to better support GitHub repository.
// VignettePS() now returns float4 instead of half4.  This ensures that 32 bit floats
// will be properly supported as Lightworks moves into those areas.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Explicitly defined float3 variables to allow for the behavioural differences between
// the D3D and Cg compilers.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Vignette";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "A lens vignette effect created by Juha Hartikainen";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
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

float Radius
<
   string Description = "Radius";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.67;                                 // Originally 1.0 - jwrl

float Amount
<
   string Description = "Amount";
   float MinVal       = -1.0;
   float MaxVal       = 1.0;
> = 1.0;                                  // Originally 0.0 - jwrl

float Hardness
<
   string Description = "Hardness";       // Originally "Softness" - jwrl
   float MinVal       = 0.5;
   float MaxVal       = 4.0;
> = 2.0;

// New parameter - jwrl

float4 Colour
<
   string Description = "Colour";
> = { 0.69, 0.78, 0.82, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 VignettePS (float2 xy : TEXCOORD1) : COLOR
{
   float4 c = tex2D (FgSampler, xy);

   float2 tc = xy - 0.5.xx;

   float v = length (tc) / Radius;

   // Four new lines replace the original [c.rgb += (pow (v, Softness) * Amount).xxx] to
   // support the vignette colour.  Negative values of Amount still invert colour - jwrl.

   float a = c.a;

   v = saturate (pow (v, Hardness) * abs (Amount));
   c = (Amount >= 0.0) ? lerp (c, Colour, v) : lerp (c, 1.0.xxxx - Colour, v);
   c.a = a;

   return c;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Vignette
{
   pass p0
   {
      PixelShader = compile PROFILE VignettePS();
   }
}
