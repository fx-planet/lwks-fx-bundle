// @Maintainer jwrl
// @Released 2018-12-27
// @Author khaver
// @Created 2017-05-05
// @see https://www.lwks.com/media/kunena/attachments/6375/VariFilmGrain_640.png

/**
Author's note:  This effect is based on my earlier Grain (Variable) effect.  This effect
rolls-off the strength of the grain as the luma values in the image approach 0 and 1,
much like real film.

Controls are:
   STRENGTH:         controls the amount of grain added.
   SIZE:             controls the size of the grain.
   DISTRIBUTION:     controls the space between grains.
   ROLL-OFF BIAS:    contols the roll-off curve between pure white and pure black.
   GRAIN BLUR:       adds blur to the grain.
   SHOW GRAIN:       lets you see just the grain.
   ALPHA GRAIN ONLY: replaces the source alpha channel with the grain passing the
                     RGB channels through from the source image untouched.
   ALPHA ADJUSTMENT: tweaks the alpha channel grain.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Variable_Film_Grain.fx
//
// Subcategory added by jwrl 10 Feb 2017
//
// Bug fix 8 May 2017 by jwrl.
// Added workaround for the interlaced media height bug in Lightworks effects.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Explicitly defined all float4 variables to address the behavioural difference
// between the D3D and Cg compilers.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 7 December 2018 jwrl.
// Corrected creation date.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Variable Film Grain";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "This effect reduces the grain as the luminance values approach their limits";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;
texture Tex3 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

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

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float _rand(float2 co, float seed){
	return frac((dot(co.xy,float2(co.x+123.0,co.y+13.0))) * seed + _Progress);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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
