// @Maintainer jwrl
// @Released 2018-04-05
// @Author khaver
// 
// @see https://www.lwks.com/media/kunena/attachments/6375/FocalBlur_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FocalBlur.fx
//
// A 3 pass 13 tap circular kernel blur.  The blur can be varied using the alpha channel
// or luma value of the source video or another video track.  Use a depth map for the
// mask for faux DoF, plus it's refocusable.
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
   string Description = "Focal Blur";           // The title
   string Category    = "Stylize";              // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Blurs and Sharpens";   // Added for v14 compatibility - jwrl.
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture V1;
texture V2;
texture MaskPass : RenderColorTarget;
texture Pass1 : RenderColorTarget;
texture Pass2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler v1 = sampler_state {
	Texture = <V1>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler v2 = sampler_state {
	Texture = <V2>;
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

bool swap
<
	string Description = "Swap Inputs";
> = false;

float blurry
<
	string Description = "De-Focus";
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

int focust
<
  string Description = "Focus Type";
  string Group = "Focus";
  string Enum = "None,Linear,Point";
> = 0;

float linfocus
<
   string Description = "Distance";
   string Group = "Focus";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float DoF
<
   string Description = "DoF";
   string Group = "Focus";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float FocusX
<
   string Description = "Point";
   string Flags = "SpecifiesPointX";
   string Group = "Focus";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float FocusY
<
   string Description = "Point";
   string Flags = "SpecifiesPointY";
   string Group = "Focus";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

bool show
<
	string Description = "Show";
	string Group = "Mask Adjustment";
> = false;

bool invert
<
	string Description = "Invert";
	string Group = "Mask Adjustment";
> = false;

int SetTechnique
<
   string Description = "Blur";
   string Enum = "No,Yes";
   string Group = "Mask Adjustment";
> = 0;

float mblur
<
	string Description = "Blur Strength";
	float MinVal = 0.0f;
	float MaxVal = 100.0f;
   	string Group = "Mask Adjustment";
> = 0.0f;

float adjust
<
	string Description = "Brightness";
	string Group = "Mask Adjustment";
	float MinVal = -1.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float contrast
<
	string Description = "Contrast";
	string Group = "Mask Adjustment";
	float MinVal = -1.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float thresh
<
	string Description = "Threshold";
	string Group = "Mask Adjustment";
	float MinVal = -1.0f;
	float MaxVal = 1.0f;
> = 0.0f;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 circle(float angle)
{
	return float2(cos(radians(angle)),sin(radians(angle)))/2.333f;
}

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float2 coord;
   float2 halfpix = pixelSize / 2.0f;
   float2 sample;

   float4 cOut = tex2D (tSource, texCoord);

   for (int tap = 0; tap < 12; tap++)
   {
   	  sample = (tap*30)+(run*10);
	  coord = saturate(texCoord.xy + (halfpix * circle(sample) * float(discRadius)));
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
	float DOF = (1.0 - DoF) * 2.0;
	float focusl = 1.0 - linfocus;
	float cont = (contrast + 1.0);

	if (cont > 1.0) cont = pow(cont,5.0);

	float4 orig, aff, opoint, mpoint;

	if (swap) {
		orig = tex2D( v2, Tex);
		aff = tex2D( v1, Tex);
		opoint = tex2D( v2, float2(FocusX, 1.0-FocusY));
		mpoint = tex2D( v1, float2(FocusX, 1.0-FocusY));
	}
	else {
		orig = tex2D( v1, Tex);
		aff = tex2D( v2, Tex);
		opoint = tex2D( v1, float2(FocusX, 1.0-FocusY));
		mpoint = tex2D( v2, float2(FocusX, 1.0-FocusY));
	}

	float themask;

	if (alpha==0) themask = 0.0f;

	if (alpha==1) {
		if (focust == 0) themask - orig.a;
		if (focust == 1) themask = 1.0-abs(orig.a - focusl);
		if (focust == 2) themask = 1.0-abs(orig.a - opoint.a);
	}
	if (alpha==2) {
		if (focust == 0) themask = dot(orig.rgb, float3(0.33f, 0.34f, 0.33f));
		if (focust == 1) themask = 1.0-abs(dot(orig.rgb, float3(0.3f, 0.59f, 0.11f)) - focusl);
		if (focust == 2) themask = 1.0-abs(dot(orig.rgb, float3(0.3f, 0.59f, 0.11f)) - dot(opoint.rgb, float3(0.3f, 0.59f, 0.11f)));
	}
	if (alpha==3) {
		if (focust == 0) themask = aff.a;
		if (focust == 1) themask = 1.0-abs(aff.a - focusl);
		if (focust == 2) themask = 1.0-abs(aff.a - mpoint.a);
	}
	if (alpha==4) {
		if (focust == 0) themask = dot(aff.rgb, float3(0.33f, 0.34f, 0.33f));
		if (focust == 1) themask = 1.0-abs(dot(aff.rgb, float3(0.33f, 0.34f, 0.33f)) - focusl);
		if (focust == 2) themask = 1.0-abs(dot(aff.rgb, float3(0.33f, 0.34f, 0.33f)) - dot(mpoint.rgb, float3(0.33f, 0.34f, 0.33f)));
	}

	themask = pow(themask,DOF);
	themask = ((themask - 0.5) * max(cont, 0.0)) + 0.5;
	themask = themask + adjust;
	themask = saturate(themask);

	if (thresh > 0.0) {
		if (themask<thresh) themask = 0.0f;
	}
	if (thresh < 0.0) {
		if (themask>1.0-abs(thresh)) themask = 1.0;
	}

	if (invert) themask = 1.0f - themask;

	return themask.xxxx;
}

float4 PSMain(  float2 Tex : TEXCOORD1, uniform int test, uniform bool mask ) : COLOR
{  
	float blur = blurry;
	float themask = tex2D(masktex, Tex).a;

	if (big) blur *= 10.0f;

	float2 pixsize = float2(1.0, _OutputAspectRatio) / _OutputWidth;

	float4 cout;

	if (test==0) {
		if (mask) cout = GrowablePoissonDisc13FilterRGBA(masktex, Tex, pixsize,mblur,0);
		else {
			if (!swap) cout = GrowablePoissonDisc13FilterRGBA(v1, Tex, pixsize,blur*(1.0-themask),0);
			else cout = GrowablePoissonDisc13FilterRGBA(v2, Tex, pixsize,blur*(1.0-themask),0);
		}
	}
	if (test==1) {
		if (mask) cout = GrowablePoissonDisc13FilterRGBA(s1, Tex, pixsize,mblur,1);
		else cout = GrowablePoissonDisc13FilterRGBA(s1, Tex, pixsize,blur*(1.0-themask),1);
	}
	if (test==2) {
		if (mask) cout = GrowablePoissonDisc13FilterRGBA(s2, Tex, pixsize,mblur,2);
		else cout = GrowablePoissonDisc13FilterRGBA(s2, Tex, pixsize,blur*(1.0-themask),2);
	}

	return cout;
}

float4 Combine( float2 Tex : TEXCOORD1 ) : COLOR
{
	if (show) return tex2D (masktex, Tex);

	if (blurry > 0.0) return tex2D (s1, Tex);

	return swap ? tex2D (v2, Tex) : tex2D (v1, Tex);
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
