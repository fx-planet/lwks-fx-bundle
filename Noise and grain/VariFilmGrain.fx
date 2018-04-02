// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect VariFilmGrain.fx
//
// Created by LW user khaver May 3, 2017
// @Author khaver
// @CreationDate "3 May 2017"
//
// Variable Film Grain
//
// This effect is based on my earlier Grain(Variable) effect.
// This effect rolls-off the strength of the grain as the luma
// values in the image approach 0 and 1, much like real film.
// Controls are:
// STRENGTH: controls the amount of grain added.
// SIZE: controls the size of the grain.
// DISTRIBUTION: controls the space between grains.
// ROLL-OFF BIAS: contols the roll-off curve between
// pure white and pure black.
// GRAIN BLUR: adds blur to the grain.
//  SHOW GRAIN: lets you see just the grain.
// ALPHA GRAIN ONLY: replaces the source alpha channel
// with the grain passing the RGB channels through from the
// source image untouched.
// ALPHA ADJUSTMENT: tweaks the alpha channel grain.
//
// Subcategory added by jwrl 10 Feb 2017
//
// Frame height bugfix 8 May 2017 by jwrl: Added workaround
// for the interlaced media height bug in Lightworks effects.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly defined all float4 variables to address the
// behavioural difference between the D3D and Cg compilers.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup		= "GenericPixelShader";
   string Description		= "Variable Film Grain";		// The title
   string Category		= "Stylize";				// Governs the category that the effect appears in in Lightworks
   string SubCategory		= "Grain and Noise";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

texture Input;
texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;
texture Tex3 : RenderColorTarget;

sampler Samp0 = sampler_state
{
   Texture = <Input>;
	AddressU = Clamp;
	AddressV = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp1 = sampler_state
{
   Texture = <Tex1>;
	AddressU = Wrap;
	AddressV = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp2 = sampler_state
{
   Texture = <Tex2>;
	AddressU = Wrap;
	AddressV = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp3 = sampler_state
{
   Texture = <Tex3>;
	AddressU = Wrap;
	AddressV = Wrap;
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

float Strength
<
	string Description = "Strength";
	float MinVal = 0.00;
	float MaxVal = 1.0;
> = 0.1;

float Size
<
	string Description = "Size";
	float MinVal = 0.25;
	float MaxVal = 4.0;
> = 0.67;

float Shape
<
	string Description = "Distribution";
	float MinVal = 0.00;
	float MaxVal = 1.0;
> = 0.9;

float Bias
<
	string Description = "Roll-off Bias";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.50;

float blur
<
	string Description = "Grain Blur";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.50f;

bool show
<
	string Description = "Show grain";
> = false;


bool agrain
<
	string Description = "Alpha grain only";
	string Group = "Alpha";
> = false;

float aadjust
<
	string Description = "Alpha adjustment";
	string Group = "Alpha";
	float MinVal = -1.0;
	float MaxVal = 1.0;
> = 0.0;

float2 _TexelKernel[13] =
	{
	    { -6, 0 },
	    { -5, 0 },
	    { -4, 0 },
	    { -3, 0 },
	    { -2, 0 },
	    { -1, 0 },
	    {  0, 0 },
	    {  1, 0 },
	    {  2, 0 },
	    {  3, 0 },
	    {  4, 0 },
	    {  5, 0 },
	    {  6, 0 }
	};

float _BlurWeights[13] =
	{
	    0.002216,
	    0.008764,
	    0.026995,
	    0.064759,
	    0.120985,
	    0.176033,
	    0.199471,
	    0.176033,
	    0.120985,
	    0.064759,
	    0.026995,
	    0.008764,
	    0.002216
	};

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

float _rand(float2 co, float seed){
	return frac((dot(co.xy,float2(co.x+123.0,co.y+13.0))) * seed + _Progress);
}

float4 Grain( float2 xy : TEXCOORD1 ) : COLOR
{
   float2 loc;
   loc.x = xy.x + 0.00013f;
   loc.y = xy.y + 0.00123f;
   if (loc.x > 1.0f) loc.x = 1.0f;
   if (loc.y > 1.0f) loc.y = 1.0f;
   float4 graintex = 0;
   float x = sin(loc.x) + cos(loc.y) + _rand(loc,((xy.x+1.123)*(loc.x+loc.y))) * 1000.0;
   float grain = frac(fmod(x, 13.0) * fmod(x, 123.0)); // - 0.5f;
   if (grain > Shape || grain < (1.0 - Shape)) grain = 0.5;
   grain = ((grain - 0.5) * (Strength * 5.0)) + 0.5;
   
   return grain.xxxx;
}

float4 Blurry1( float2 Tex : TEXCOORD1 ) : COLOR
{  
    float xpix = 1.0f / _OutputWidth;
    float ypix = xpix * _OutputAspectRatio;

    float4 Color = 0;

    for (int i = 0; i < 13; i++)
    {    
        Color += tex2D( Samp1, (((Tex-0.5f) / Size) + 0.5f) + ((_TexelKernel[i].yx * blur) * xpix)) * _BlurWeights[i];
    }

    return Color;
}

float4 Blurry2( float2 Tex : TEXCOORD1 ) : COLOR
{  
    float xpix = 1.0f / _OutputWidth;
    float ypix = xpix * _OutputAspectRatio;

    float4 Color = 0.0.xxxx;

    for (int i = 0; i < 13; i++)
    {
        Color += tex2D( Samp2, (((Tex-0.5f) / Size) + 0.5f) + ((_TexelKernel[i].xy * blur) * ypix)) * _BlurWeights[i];
    }

    return Color;
}

float4 Combine( float2 xy : TEXCOORD1 ) : COLOR
{
   float lum1, lum2, lum3;
   float4 source = tex2D( Samp0, xy );
   lum1 = (source.r + source.g + source.b) / 3.0;
   lum3 = 1.0;
	if (lum1 < Bias) {
		lum2 = (lum1 / Bias) * 90.0;
		lum3 = sin(radians(lum2));
	}
	if (lum1 > Bias) {
		lum2 = ((1.0 - lum1) / (1.0 - Bias)) * 90.0;
		lum3 = sin(radians(lum2));
	}
		
   float4 grainblur = tex2D( Samp3, xy);
   if (!agrain) source = source + ((grainblur - 0.5.xxxx) * lum3);
   else source = float4 (source.rgb, ((grainblur.a - 0.5) * lum3 * 2.0) + aadjust);
   if (show) source = ((grainblur - 0.5.xxxx) * lum3) + 0.5.xxxx;
  
   return source;
}

//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------

technique VariGrain
{
   pass Pass1 // Get from Input
   <
      string Script = "RenderColorTarget0 = Tex1;";
   >
   {
      PixelShader = compile PROFILE Grain();
   }
   
   pass Pass2 // Get from Tex1
   <
      string Script = "RenderColorTarget0 = Tex2;";
   >
   {
      PixelShader = compile PROFILE Blurry1();
   }
   
   pass Pass3 // Get from Tex2
   <
      string Script = "RenderColorTarget0 = Tex3;";
   >
   {
      PixelShader = compile PROFILE Blurry2();
   }
   
   pass Pass4 // Get from Tex4
   {
      PixelShader = compile PROFILE Combine();
   }

}

