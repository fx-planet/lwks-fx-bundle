// @Maintainer jwrl
// @Released 2018-03-31
// @Author msi
// @Created 2011
// @License "CC BY-NC-SA"
// ---------------------------------------------------------
// Vintage look, 2011 msi.
// [CC BY-NC-SA]
//
// Added subcategory for LW14 18 Feb 2017 - jwrl.
//
// Cross platform compatibility check 31 July 2017 jwrl.
//
// Explicitly define float4 variables to address the
// behavioural difference between the D3D and Cg compilers.
// ---------------------------------------------------------

int _LwksEffectInfo
<
	string EffectGroup = "GenericPixelShader";
	string Description = "Vintage Look";
	string Category    = "Colour";
	string SubCategory = "Preset Looks";
> = 0;

// ----------------------------------------
// Parameters
// ----------------------------------------

texture Input;

sampler MsiVintageSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

float4 Yellow
<
	string Description = "Yellow";
	string Group       = "Balance";
> = { 0.9843f, 0.9490f, 0.6392f, 1.0f };

float4 Magenta
<
	string Description = "Magenta";
	string Group       = "Balance";
> = { 0.9098f, 0.3960f, 0.7019f, 1.0f };

float4 Cyan
<
	string Description = "Cyan";
	string Group       = "Balance";
> = { 0.0352f, 0.2862f, 0.9137f, 1.0f };

float YellowLevel
<
	string Description = "Yellow";
	string Group       = "Overlay";
	float MinVal       = 0.0;
	float MaxVal       = 1.00;
> = 0.59;

float MagentaLevel
<
	string Description = "Magenta";
	string Group       = "Overlay";
	float MinVal       = 0.0;
	float MaxVal       = 1.00;
> = 0.2;

float CyanLevel
<
	string Description = "Cyan";
	string Group       = "Overlay";
	float MinVal       = 0.0;
	float MaxVal       = 1.00;
> = 0.17;

#pragma warning ( disable : 3571 )

// ----------------------------------------
// Shader
// ----------------------------------------

float4 VintageLookFX( float2 xy: TEXCOORD1 ) : COLOR
{
	float4 source = tex2D( MsiVintageSampler, xy );
	// BEGIN Vintage Look routine by Wojciech Toman
	// (http://wtomandev.blogspot.com/2011/04/vintage-look.html)
	float4 corrected = lerp( source, source * Yellow, YellowLevel );
	corrected = lerp( corrected, (1.0.xxxx - ((1.0.xxxx - corrected) * (1.0.xxxx - Magenta))), MagentaLevel);
	corrected = lerp( corrected, (1.0.xxxx - ((1.0.xxxx - corrected) * (1.0.xxxx - Cyan))), CyanLevel);
	// END Vintage Look routine by Wojciech Toman
	return corrected;	
}

// ----------------------------------------
// Technique
// ----------------------------------------

technique VintageLookFXTechnique
{
	pass SinglePass
	{
		PixelShader = compile PROFILE VintageLookFX();
	}
}
