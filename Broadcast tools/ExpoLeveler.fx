//--------------------------------------------------------------//
// Exposure Leveler by khaver
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Exposure Leveler";       // The title
   string Category    = "Colour";        // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Technical";        // Governs the subcategory that the effect appears in version 14 and up
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _OutputAspectRatio;
float _OutputWidth;

#define OutputHeight (_OutputWidth/_OutputAspectRatio)

texture Input;
texture Frame;
texture IPass1 : RenderColorTarget;
texture IPass2 : RenderColorTarget;
texture FPass1 : RenderColorTarget;
texture FPass2 : RenderColorTarget;

sampler s0 = sampler_state {
	Texture = <Input>;
	AddressU = MirrorOnce;
	AddressV = MirrorOnce;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s1 = sampler_state {
	Texture = <IPass1>;
	AddressU = MirrorOnce;
	AddressV = MirrorOnce;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler s2 = sampler_state {
	Texture = <IPass2>;
	AddressU = MirrorOnce;
	AddressV = MirrorOnce;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler f0 = sampler_state {
	Texture = <Frame>;
	AddressU = MirrorOnce;
	AddressV = MirrorOnce;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler f1 = sampler_state {
	Texture = <FPass1>;
	AddressU = MirrorOnce;
	AddressV = MirrorOnce;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler f2 = sampler_state {
	Texture = <FPass2>;
	AddressU = MirrorOnce;
	AddressV = MirrorOnce;
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

float TUNE
<
	string Description = "Tune";
	float MinVal = -1.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float BLUR
<
	string Description = "Blur Amount";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.5f;

bool SWAP
<
	string Description = "Swap Tracks";
> = false;

bool ShowE
<
	string Description = "Show Example Frame";
> = false;

bool ShowVB
<
	string Description = "Show Video Blur";
> = false;

bool ShowFB
<
	string Description = "Show Example Blur";
> = false;

bool COMBINE
<
	string Description = "Use Example Points for Video";
> = true;

float F1X
<
   string Description = "E1";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float F1Y
<
   string Description = "E1";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float F2X
<
   string Description = "E2";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float F2Y
<
   string Description = "E2";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float F3X
<
   string Description = "E3";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float F3Y
<
   string Description = "E3";
   string Group = "Example Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float V1X
<
   string Description = "V1";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float V1Y
<
   string Description = "V1";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float V2X
<
   string Description = "V2";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float V2Y
<
   string Description = "V2";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float V3X
<
   string Description = "V3";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float V3Y
<
   string Description = "V3";
   string Group = "Video Samples";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;


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

float2 circle(float angle)
{
	return float2(cos(angle),sin(angle))/1.5f;
}

float colorsep(sampler samp, float2 xy)
{
	float3 col = tex2D(samp, xy).rgb;

	return (col.r + col.g + col.b) / 3.0;
}

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float2 halfpix = pixelSize / 2.0f;
   float2 coord, sample;

   float4 cOut = tex2D (tSource, texCoord+halfpix);

   for (int tap = 0; tap < 12; tap++) {
   	  sample = (tap*30)+(run*5);
	  coord = texCoord + (halfpix * circle(sample) * float(discRadius));
      cOut += tex2D (tSource, coord);
   }

   cOut /= 13.0f;

   return cOut;
}

float4 PSMain(  float2 Tex : TEXCOORD1, uniform int test ) : COLOR
{  
	float blur = BLUR * 500.0;
	float2 pixsize = float2(1.0f / _OutputWidth, 1.0f / OutputHeight);

	float4 cout;

	if (test==0) cout = GrowablePoissonDisc13FilterRGBA(s0, Tex, pixsize,blur,0);
	if (test==1) cout = GrowablePoissonDisc13FilterRGBA(s1, Tex, pixsize,blur,1);
	if (test==2) cout = GrowablePoissonDisc13FilterRGBA(s2, Tex, pixsize,blur,2);
	if (test==3) cout = GrowablePoissonDisc13FilterRGBA(s1, Tex, pixsize,blur,3);
	if (test==4) cout = GrowablePoissonDisc13FilterRGBA(s2, Tex, pixsize,blur,4);
	if (test==5) cout = GrowablePoissonDisc13FilterRGBA(s1, Tex, pixsize,blur,5);
	if (test==6) cout = GrowablePoissonDisc13FilterRGBA(f0, Tex, pixsize,blur,0);
	if (test==7) cout = GrowablePoissonDisc13FilterRGBA(f1, Tex, pixsize,blur,1);
	if (test==8) cout = GrowablePoissonDisc13FilterRGBA(f2, Tex, pixsize,blur,2);
	if (test==9) cout = GrowablePoissonDisc13FilterRGBA(f1, Tex, pixsize,blur,3);
	if (test==10) cout = GrowablePoissonDisc13FilterRGBA(f2, Tex, pixsize,blur,4);
	if (test==11) cout = GrowablePoissonDisc13FilterRGBA(f1, Tex, pixsize,blur,5);

	return cout;
}

float4 Process( float2 xy : TEXCOORD1) : COLOR
{
	float4 video, frame, cout;

	if (SWAP) {
		video = tex2D(f0, xy);
		frame = tex2D(s0, xy);
	}
	else {
		video = tex2D(s0, xy);
		frame = tex2D(f0, xy);
	}

	if (ShowE) return frame;

	float2 fp1 = float2(F1X, 1.0 - F1Y);
	float2 fp2 = float2(F2X, 1.0 - F2Y);
	float2 fp3 = float2(F3X, 1.0 - F3Y);
	float2 vp1 = float2(V1X, 1.0 - V1Y);
	float2 vp2 = float2(V2X, 1.0 - V2Y);
	float2 vp3 = float2(V3X, 1.0 - V3Y);

	if (COMBINE) {
		vp1 = fp1;
		vp2 = fp2;
		vp3 = fp3;
	}

	float va = video.a;
	float tune = pow(TUNE + 1.0, 0.1);
	float flum1, flum2, flum3, vlum1, vlum2, vlum3;

	if (SWAP) {
		if (ShowVB) return tex2D(f2, xy);
		if (ShowFB) return tex2D(s2, xy);

		flum1 = colorsep(s2, fp1);
		flum2 = colorsep(s2, fp2);
		flum3 = colorsep(s2, fp3);
		vlum1 = colorsep(f2, vp1);
		vlum2 = colorsep(f2, vp2);
		vlum3 = colorsep(f2, vp3);
	}
	else {
		if (ShowVB) return tex2D(s2, xy);
		if (ShowFB) return tex2D(f2, xy);

		flum1 = colorsep(f2, fp1);
		flum2 = colorsep(f2, fp2);
		flum3 = colorsep(f2, fp3);
		vlum1 = colorsep(s2, vp1);
		vlum2 = colorsep(s2, vp2);
		vlum3 = colorsep(s2, vp3);
	}

	float flumav = (flum1 + flum2 + flum3) / 3.0;
	float vlumav = (vlum1 + vlum2 + vlum3) / 3.0;
	float ldiff = 1.0 / (vlumav / (flumav / tune));

	cout = video;

	float ldiff1 = pow(ldiff, 0.5);
	float ldiff2 = pow(ldiff, 0.5);

	cout.rgb *= ldiff1;
	cout.rgb = pow(cout.rgb, 1.0 / ldiff2);
	cout.a = va;

	return cout;
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (6 passes total)
//--------------------------------------------------------------
technique SampleFxTechnique
{

   pass IPassA
   <
      string Script = "RenderColorTarget0 = IPass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(0);
   }
   pass IPassB
   <
      string Script = "RenderColorTarget0 = IPass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(1);
   }
   pass IPassC
   <
      string Script = "RenderColorTarget0 = IPass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(2);
   }
   pass IPassD
   <
      string Script = "RenderColorTarget0 = IPass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(3);
   }
   pass IPassE
   <
      string Script = "RenderColorTarget0 = IPass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(4);
   }
   pass IPassF
   <
      string Script = "RenderColorTarget0 = IPass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(5);
   }

   pass FPassA
   <
      string Script = "RenderColorTarget0 = FPass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(6);
   }
   pass FPassB
   <
      string Script = "RenderColorTarget0 = FPass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(7);
   }
   pass FPassC
   <
      string Script = "RenderColorTarget0 = FPass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(8);
   }
   pass FPassD
   <
      string Script = "RenderColorTarget0 = FPass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(9);
   }
   pass FPassE
   <
      string Script = "RenderColorTarget0 = FPass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(10);
   }
   pass FPassF
   <
      string Script = "RenderColorTarget0 = FPass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(11);
   }
   pass Final
   {
      PixelShader = compile PROFILE Process();
   }
}

