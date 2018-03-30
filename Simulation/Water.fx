//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Water";       // The title
   string Category    = "Stylize";                  // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Simulation";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _Progress;

int iSeed = 15;


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

//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//

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

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// Note that pixels are processed out of order, in parallel.
// Using shader model 2.0, so there's a 64 instruction limit -
// use multple passes if you need more.
//--------------------------------------------------------------

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

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE Wavey();
   }
}

