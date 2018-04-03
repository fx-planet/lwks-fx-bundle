// @Maintainer jwrl
// @Released 2018-03-31
// @Author "Juha Hartikainen"
// @AuthorEmail "juha@linearteam.org"
//--------------------------------------------------------------
// 
// JH Stylize Vignette v1.0 - Juha Hartikainen - juha@linearteam.org
// - Lens vignette effect
//
// Version 14 update 18 Feb 2017 jwrl.
//
// Added subcategory to effect header.
//
// Cross platform compatibility check 1 August 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly defined float3 variables to fix the behavioural
// differences between the D3D and Cg compilers.
//--------------------------------------------------------------

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "JH Vignette";
   string Category    = "Stylize";
   string SubCategory = "Vignettes";
> = 0;

//--------------------------------------------------------------
// Inputs
//--------------------------------------------------------------

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

//--------------------------------------------------------------
// Parameters
//--------------------------------------------------------------

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

//--------------------------------------------------------------
// Shader
//--------------------------------------------------------------

half4 VignettePS(float2 xy : TEXCOORD1) : COLOR
{
    float4 c = tex2D(FgSampler, xy);

    float2 tc = xy - (0.5, 0.5);
    float v = length(tc) / Radius;
    c.rgb += (pow(v, Softness) * Amount).xxx;

    return c;	
}

technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE VignettePS();
   }
}

