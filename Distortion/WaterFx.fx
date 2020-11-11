// @Maintainer jwrl
// @Released 2020-11-11
// @Author khaver
// @Created 2014-11-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Water_640.png

/**
 Water makes waves as well as refraction, and provides X and Y adjustment of the
 parameters.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WaterFx.fx
//
// Version history:
//
// Update 2020-11-11 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 2018-12-23 jwrl:
// Added creation date.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14 update 18 Feb 2017 jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Water";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
   string Notes       = "This makes waves as well as refraction, and provides X and Y adjustment of the parameters";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Speed
<
	string Description = "Speed";
	float MinVal = 0.00;
	float MaxVal = 1000.0;
> = 0.0;

float WavesX
<
	string Description = "X Frequency";
	float MinVal = 0.00;
	float MaxVal = 100.0;
> = 0.0;

float StrengthX
<
	string Description = "X Strength";
	float MinVal = 0.0000;
	float MaxVal = 0.100;
> = 0.0;

float WavesY
<
	string Description = "Y Frequency";
	float MinVal = 0.00;
	float MaxVal = 100.0;
> = 0.0;

float StrengthY
<
	string Description = "Y Strength";
	float MinVal = 0.0000;
	float MaxVal = 0.100;
> = 0.0;

bool Flip
<
	string Description = "Waves";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

int iSeed = 15;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Wavey( float2 xy : TEXCOORD1 ) : COLOR
{
	int xx;
	int yy;
	float wavesx = WavesX * 2.0;
	float wavesy = WavesY * 2.0;
	if (Flip) {
		xy.x += sin((_Progress*Speed)+xy.y*wavesy)*StrengthY;
		xy.y += cos((_Progress*Speed)+xy.x*wavesx)*StrengthX;
	}
	else {
		xy.x += sin((_Progress*Speed)+xy.x*wavesx)*StrengthX;
		xy.y += cos((_Progress*Speed)+xy.y*wavesy)*StrengthY;
	}
	float4 Color = tex2D(FgSampler,xy);
	return Color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Water
{
   pass SinglePass
   {
      PixelShader = compile PROFILE Wavey();
   }
}
