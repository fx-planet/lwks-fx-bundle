// @Maintainer jwrl
// @Released 2018-04-08
// @Author khaver
// @see https://www.lwks.com/media/kunena/attachments/6375/VariGrain_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect VariGrain.fx
//
// This effect is an extended flexible means of adding grain to an image.  As well as
// intensity adjustment it's also possible to adjust the size and softness of the grain.
// The grain can be applied to the alpha channel alone with variable transparency.
// This is designed to help with grain blending when combined with other video sources.
//
// Subcategory added by jwrl 10 Feb 2017
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Grain(Variable)";
   string Category    = "Stylize";
   string SubCategory = "Grain and Noise";
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
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp1 = sampler_state
{
   Texture = <Tex1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp2 = sampler_state
{
   Texture = <Tex2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler Samp3 = sampler_state
{
   Texture = <Tex3>;
   AddressU  = Clamp;
   AddressV  = Clamp;
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
	float MaxVal = 100.0;
> = 0.0;

float Size
<
	string Description = "Size";
	float MinVal = 1.00;
	float MaxVal = 10.0;
> = 1.0;

float blur
<
	string Description = "Grain Blur";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

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

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float _rand(float2 co, float seed){
    float rand;
	rand = frac((dot(co.xy,float2(co.x+123,co.y+13))) * seed + _Progress);
	return rand;
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
   float4 graintex = {0.5f,0.5f,0.5f,0.5f};
   float4 source = tex2D( Samp0, xy );
   float x = sin(loc.x) + cos(loc.y) + _rand(loc,((source.g+1.0)*(loc.x+loc.y))) * 1000;
   float grain = frac(fmod(x, 13) * fmod(x, 123)) - 0.5f;

   grain = grain*(Strength/100);
   graintex = graintex + grain;
  
   return graintex;

}

float4 Blurry1( float2 Tex : TEXCOORD1 ) : COLOR
{  
float xpix = 1.0f / _OutputWidth;
float ypix = xpix * _OutputAspectRatio;
	float2 TexelKernel[13] =
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
	    {  6, 0 },
	};

	const float BlurWeights[13] =
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
	    0.002216,
	};


    float4 Color = 0.0.xxxx;
    float4 Orig = tex2D( Samp1, Tex);

    for (int i = 0; i < 13; i++)
    {    
        Color += tex2D( Samp1, Tex + (TexelKernel[i].yx * ypix)) * BlurWeights[i];
    }

    return Color;
}

float4 Blurry2( float2 Tex : TEXCOORD1 ) : COLOR
{  
float xpix = 1.0f / _OutputWidth;
float ypix = xpix * _OutputAspectRatio;
	float2 TexelKernel[13] =
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
	    {  6, 0 },
	};

	const float BlurWeights[13] =
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
	    0.002216,
	};


    float4 Color = 0;
    float4 Orig = tex2D( Samp2, Tex);

    for (int i = 0; i < 13; i++)
    {
        Color += tex2D( Samp2, Tex + (TexelKernel[i].xy * xpix)) * BlurWeights[i];
    }

    return Color;
}

float4 Combine( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 source = tex2D( Samp0, xy );
   float4 grainblur = tex2D( Samp3, ((xy-0.5f) / Size) + 0.5f);
   float4 grainorg = tex2D( Samp1, ((xy-0.5f) / Size) + 0.5f);
   float4 graintex = lerp(grainorg,grainblur,blur);
   if (!agrain) source = source + (graintex - 0.5f);
   else source = float4(source.rgb, graintex.a + aadjust);
  
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
