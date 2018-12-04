// @Maintainer jwrl
// @Released 2018-12-04
// @Author juhartik
// @AuthorEmail "juha@linearteam.org"
// @Created 2011-04-29
// @see https://www.lwks.com/media/kunena/attachments/6375/jh_stylize_vignette_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect jh_stylize_vignette.fx
//
// Lens vignette effect v1.0 - Juha Hartikainen - juha@linearteam.org
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Explicitly defined float3 variables to allow for the behavioural differences between
// the D3D and Cg compilers.
//
// Modified by LW user jwrl 4 April 2018.
// Metadata header block added to better support GitHub repository.
// VignettePS() now returns float4 instead of half4.  This ensures that 32 bit floats
// will be properly supported as Lightworks moves into those areas.
//
// Modified 4 December 2018 jwrl.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "JH Vignette";
   string Category    = "Stylize";
   string SubCategory = "Vignettes";
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
   float MinVal       = 0.0f;
   float MaxVal       = 1.0f;
> = 1.0f; // Default value

float Amount
<
   string Description = "Amount";
   float MinVal       = -1.0f;
   float MaxVal       = 1.0f;
> = 0.0f; // Default value

float Softness
<
   string Description = "Softness";
   float MinVal       = 0.5f;
   float MaxVal       = 4.0f;
> = 2.0f; // Default value

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 VignettePS(float2 xy : TEXCOORD1) : COLOR
{
    float4 c = tex2D(FgSampler, xy);

    float2 tc = xy - (0.5, 0.5);
    float v = length(tc) / Radius;
    c.rgb += (pow(v, Softness) * Amount).xxx;

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
