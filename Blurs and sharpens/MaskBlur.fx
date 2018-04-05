// @Maintainer jwrl
// @Released 2018-04-05
// @Author khaver
// @Created -unknown-
// @see https://www.lwks.com/media/kunena/attachments/6375/MaskBlur.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect MaskBlur.fx
//
// A 3 pass 13 tap circular kernel blur.  The blur can be masked using the alpha channel
// or luma value of the source video or another video track.
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
   string Description = "Masked Blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";   // Added for v14 compatibility - jwrl.
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Mask;
texture MaskPass : RenderColorTarget;
texture Pass1 : RenderColorTarget;
texture Pass2 : RenderColorTarget;

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

sampler affector = sampler_state {
	Texture = <Mask>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler masktex = sampler_state {
	Texture = <MaskPass>;
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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float blurry
<
	string Description = "Amount";
	float MinVal = 0.0f;
	float MaxVal = 100.0f;
> = 0.0f;

bool big
<
	string Description = "x10";
> = false;

int alpha
<
	string Description = "Mask Type";
	string Group = "Mask";
	string Enum = "None,Source_Alpha,Source_Luma,Mask_Alpha,Mask_Luma";
> = 0;

int SetTechnique
<
   string Description = "Blur Mask";
   string Enum = "No,Yes";
   string Group = "Mask";
> = 0;

float adjust
<
	string Description = "Brightness";
	string Group = "Mask";
	float MinVal = -1.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float contrast
<
	string Description = "Contrast";
	string Group = "Mask";
	float MinVal = 0.0f;
	float MaxVal = 10.0f;
> = 0.0f;

float thresh
<
	string Description = "Threshold";
	string Group = "Mask";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

bool invert
<
	string Description = "Invert";
	string Group = "Mask";
> = false;

bool show
<
	string Description = "Show";
	string Group = "Mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 circle(float angle)
{
	return float2(cos(angle),sin(angle))/2.333f;
}

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float2 coord;
   float2 halfpix = pixelSize / 2.0f;
   float2 sample;

   float4 cOut = tex2D (tSource, texCoord+halfpix);
   float4 orig = tex2D (tSource, texCoord);

   for (int tap = 0; tap < 12; tap++)
   {
   	  sample = (tap*30)+(run*10);
	  coord = texCoord.xy + (halfpix * circle(sample) * float(discRadius));
      cOut += tex2D (tSource, coord);
   }

   cOut /= 13.0f;

   return cOut;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Masking( float2 Tex : TEXCOORD1) : COLOR
{
	float4 orig = tex2D( s0, Tex);
	float4 aff = tex2D( affector, Tex);

	float themask;

	if (alpha==0) themask = 0.0f;
	if (alpha==1) themask = orig.a;
	if (alpha==2) themask = dot(orig.rgb, float3(0.33f, 0.34f, 0.33f));
	if (alpha==3) themask = aff.a;
	if (alpha==4) themask = dot(aff.rgb, float3(0.33f, 0.34f, 0.33f));

	themask = (themask + adjust) * (1.0f+contrast)/1.0f;

	if (themask<thresh) themask = 0.0f;
	if (invert) themask = 1.0f - themask;

	return themask.xxxx;
}

float4 PSMain(  float2 Tex : TEXCOORD1, uniform int test, uniform bool mask ) : COLOR
{  
	float blur = blurry;

	if (big) blur *= 10.0f;

	float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
	float2 halfpix = pixsize / 2.0f;

	if (test==1) return GrowablePoissonDisc13FilterRGBA(s1, Tex+halfpix, pixsize,blur,1);

	if (test==2) return GrowablePoissonDisc13FilterRGBA(s2, Tex+halfpix, pixsize,blur,2);

	if (mask) return GrowablePoissonDisc13FilterRGBA(masktex, Tex+halfpix, pixsize,blur,0);

	return GrowablePoissonDisc13FilterRGBA(s0, Tex+halfpix, pixsize,blur,0);
}

float4 Combine( float2 Tex : TEXCOORD1 ) : COLOR
{
	float blur = blurry;

	float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
	float2 halfpix = pixsize / 2.0f;

	float4 orig = tex2D( s0, Tex+halfpix);
	float4 masked, color, cout;

	if (blurry > 0.0f) {
		color = tex2D( s1, Tex+halfpix);
		masked = tex2D( masktex, Tex+halfpix);
		cout = lerp(color,orig,saturate(masked.a));
	}
	else {
		cout = orig;
		masked = tex2D( masktex, Tex+pixsize);
	}

	if (show) return masked;

	return cout;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique No
{

   pass PassMask
   <
      string Script = "RenderColorTarget0 = MaskPass;";
   >
   {
      PixelShader = compile PROFILE Masking();
   }
   pass Pass1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(0,false);
   }
   pass Pass2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(1,false);
   }
   pass Pass3
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(2,false);
   }
   pass Last
   {
      PixelShader = compile PROFILE Combine();
   }
}

technique Yes
{

   pass PassMask
   <
      string Script = "RenderColorTarget0 = MaskPass;";
   >
   {
      PixelShader = compile PROFILE Masking();
   }
   pass MBlur1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(0,true);
   }
   pass MBlur2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(1,true);
   }
   pass MBlur3
   <
      string Script = "RenderColorTarget0 = MaskPass;";
   >
   {
      PixelShader = compile PROFILE PSMain(2,true);
   }
   pass Pass1
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(0,false);
   }
   pass Pass2
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(1,false);
   }
   pass Pass3
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(2,false);
   }
   pass Last
   {
      PixelShader = compile PROFILE Combine();
   }
}
