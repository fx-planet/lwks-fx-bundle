// @Maintainer jwrl
// @Released 2018-12-04
// @Author msi
// @OriginalAuthor "Wojciech Toman (http://wtomandev.blogspot.com/2011/04/vintage-look.html)"
// @Created 2011-05-27
// @License "CC BY-NC-SA"
// @see https://www.lwks.com/media/kunena/attachments/6375/vintagelook_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect vintagelook.fx
//
// Vintage look, 2011 msi [CC BY-NC-SA] - simulates what happens when the dye layers
// of old colour film stock start to fade.  Uses Vintage Look routine by Wojciech
// Toman (http://wtomandev.blogspot.com/2011/04/vintage-look.html)
//
// Added subcategory for LW14 18 Feb 2017 - jwrl.
//
// Cross platform compatibility check 31 July 2017 jwrl.
// Explicitly define float4 variables to address the behavioural differences between
// the D3D and Cg compilers.
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
	string Description = "Vintage Look";
	string Category    = "Colour";
	string SubCategory = "Preset Looks";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique VintageLookFXTechnique
{
	pass SinglePass
	{
		PixelShader = compile PROFILE VintageLookFX();
	}
}
