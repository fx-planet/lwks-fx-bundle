// @Maintainer jwrl
// @Released 2018-04-05
// @Author khaver
// @Created -unknown-
// @see https://www.lwks.com/media/kunena/attachments/6375/Bokeh.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bokeh.fx
//
// Blur with adjustable bokeh.  Uses 6 GPU passes for blur and 8 pass for bokeh creation.
// May not be playable in real time on slower systems.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in Lightworks effects.  THE BUG
// WAS NOT IN THE WAY THIS EFFECT WAS ORIGINALLY IMPLEMENTED.  When a height parameter is
// needed one cannot reliably use _OutputHeight with interlaced media.  It returns only
// half the actual frame height when interlaced media is stationary.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bokeh";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Mask : RenderColorTarget;
texture Pass1 : RenderColorTarget;
texture Pass2 : RenderColorTarget;
texture Bokeh1 : RenderColorTarget;
texture Bokeh2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s0 = sampler_state {
	Texture = <Input>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler m0 = sampler_state {
	Texture = <Mask>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s1 = sampler_state {
	Texture = <Pass1>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s2 = sampler_state {
	Texture = <Pass2>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler b1 = sampler_state {
	Texture = <Bokeh1>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler b2 = sampler_state {
	Texture = <Bokeh2>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float size
<
	string Description = "Size";
	float MinVal = 0.0f;
	float MaxVal = 50.0f;
> = 3.0f;

float thresh
<
	string Description = "Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float strength
<
	string Description = "Strength";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.8f;

float gamma
<
	string Description = "Gamma";
	float MinVal = 0.0f;
	float MaxVal = 3.0f;
> = 0.75f;

float focus
<
	string Description = "Focus";
	string Group = "Image";
	float MinVal = 0.0f;
	float MaxVal = 100.0f;
> = 10.0f;

float igamma
<
	string Description = "Gamma";
	string Group = "Image";
	float MinVal = 0.0f;
	float MaxVal = 3.0f;
> = 0.75f;

float bmix
<
	string Description = "Mix";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.5f;

bool smask
<
	string Description = "Show Bokeh Mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Declarations and definitions
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 circle(float angle)
{
	float ang = radians(angle);
	return float2(cos(ang),sin(ang));
}

float4 BlurDisc13FilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float2 coord;
   float2 halfpix = pixelSize / 2.0f;

   float sample;

   float4 cOut = tex2D (tSource, texCoord+halfpix);
   float4 orig = tex2D (tSource, texCoord);

   for (int tap = 0; tap < 12; tap++)
   {
   	  sample = (tap*30)+(run*5.0f);
	  coord = texCoord + (halfpix * circle(sample) * float(discRadius));
      cOut += tex2D (tSource, coord);
   }
   cOut /= 13.0f;
   return cOut;
}

float4 BokehFilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float4 color;

   float2 coord;
   float2 halfpix = pixelSize / 2.0f;

   float sample;

   float4 cOut = tex2D (tSource, texCoord+halfpix);

   for (int tap = 0; tap < 17; tap++)
   {
   	  sample = (tap*22.5f)+(run*3.75f);
	  coord = texCoord + (pixelSize * circle(sample) * float(discRadius));
	  color = tex2D(tSource, coord);
      cOut = max(color,cOut);
   }
   cOut.a = 1.0f;
   return cOut;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 FindBokeh( float2 Tex : TEXCOORD1) : COLOR
{
	float4 orig = tex2D(s0, Tex);
	float4 color = 0.0.xxxx;
	if (orig.r > thresh || orig.g > thresh || orig.b > thresh) color = pow(orig,1.0f/gamma);
	return color * strength;
}

float4 PSMain(  float2 Tex : TEXCOORD1, uniform int test) : COLOR
{  
	float blur = focus;
	float blur2 = size;
	float2 pixsize = float2(1.0,_OutputAspectRatio) / _OutputWidth;
	float2 halfpix = pixsize / 2.0f;
	float4 cout;
	if (test==0) cout = BlurDisc13FilterRGBA(s0, Tex+halfpix, pixsize,blur,0);
	if (test==1) cout = BlurDisc13FilterRGBA(s1, Tex+halfpix, pixsize,blur,1);
	if (test==2) cout = BlurDisc13FilterRGBA(s2, Tex+halfpix, pixsize,blur,2);
	if (test==3) cout = BlurDisc13FilterRGBA(s1, Tex+halfpix, pixsize,blur,3);
	if (test==4) cout = BlurDisc13FilterRGBA(s2, Tex+halfpix, pixsize,blur,4);
	if (test==5) cout = BlurDisc13FilterRGBA(s1, Tex+halfpix, pixsize,blur,5);
	if (test==6) cout = BlurDisc13FilterRGBA(b2, Tex+halfpix, pixsize,blur2/4.0f,0);
	if (test==7) cout = BlurDisc13FilterRGBA(b1, Tex+halfpix, pixsize,blur2/4.0f,1);
	return cout;
}

float4 PSBokeh(  float2 Tex : TEXCOORD1, uniform int test) : COLOR
{  
	float blur = size;
	float2 pixsize = float2(1.0,_OutputAspectRatio) / _OutputWidth;
	float2 halfpix = pixsize / 2.0f;
	float4 cout;
	if (test==0) cout = BokehFilterRGBA(m0, Tex+halfpix, pixsize,blur,0);
	if (test==1) cout = BokehFilterRGBA(b1, Tex+halfpix, pixsize,blur,1);
	if (test==2) cout = BokehFilterRGBA(b2, Tex+halfpix, pixsize,blur,2);
	if (test==3) cout = BokehFilterRGBA(b1, Tex+halfpix, pixsize,blur,3);
	if (test==4) cout = BokehFilterRGBA(b2, Tex+halfpix, pixsize,blur,4);
	if (test==5) cout = BokehFilterRGBA(b1, Tex+halfpix, pixsize,blur,5);
	return cout;
}

float4 Combine( float2 Tex : TEXCOORD1 ) : COLOR
{
	float2 pixsize = float2(1.0,_OutputAspectRatio) / _OutputWidth;
	float2 halfpix = pixsize / 2.0f;

	float4 orig = tex2D( s0, Tex+halfpix);
	float4 blurred = pow(tex2D( s2, Tex+halfpix),1.0f/igamma);
	float4 bokeh = tex2D( b2, Tex+halfpix);

	if (smask) return tex2D(m0, Tex);

	if (focus > 0.0f || size > 0.0f) {
		if (size == 0.0f) bokeh = blurred;
		blurred *= bmix;
		return 1.0.xxxx - ((1.0.xxxx - bokeh) * (1.0.xxxx - blurred));
	}

  return orig;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Bokeh
{

   pass BokehPass
   <
      string Script = "RenderColorTarget0 = Mask;";
   >
   {
      PixelShader = compile PROFILE FindBokeh();
   }
   pass BokehPass0
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE PSBokeh(0);
   }
   pass BokehPass1
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE PSBokeh(1);
   }
   pass BokehPass2
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE PSBokeh(2);
   }
   pass BokehPass3
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE PSBokeh(3);
   }
   pass BokehPass4
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE PSBokeh(4);
   }
   pass BokehLast
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE PSBokeh(5);
   }
   pass BokehBlurr1
   <
      string Script = "RenderColorTarget0 = Bokeh1;";
   >
   {
      PixelShader = compile PROFILE PSMain(6);
   }
   pass BokehBlurr2
   <
      string Script = "RenderColorTarget0 = Bokeh2;";
   >
   {
      PixelShader = compile PROFILE PSMain(7);
   }
   pass BlurPass0
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(0);
   }
   pass BlurPass1
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(1);
   }
   pass BlurPass2
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(2);
   }
   pass BlurPass3
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(3);
   }
   pass BlurPass4
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(4);
   }
   pass BlurPass5
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(5);
   }
   pass Last
   {
      PixelShader = compile PROFILE Combine();
   }
}
