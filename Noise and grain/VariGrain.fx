// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Subcategory added by jwrl 10 Feb 2017
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// When a height parameter is needed _OutputHeight returns
// only half the actual frame height when interlaced media is
// playing.  Now the output height is obtained by dividing
// _OutputWidth by _OutputAspectRatio  This fix is reliable
// regardless of the pixel aspect ratio.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Grain(Variable)";       // The title
   string Category    = "Stylize";                  // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Grain and Noise";
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
    float rand;
	rand = frac((dot(co.xy,float2(co.x+123,co.y+13))) * seed + _Progress);
	return rand;
}

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

