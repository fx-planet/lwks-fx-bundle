//--------------------------------------------------------------//
// VHS by khaver - cross-platform V2 mod by jwrl
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
//
// Code cleanup 25 February 2017 by jwrl:
// Unused parameter to set the Y value in the distortion source
// group removed.  A new group "Distortion" was added because
// removing the Y parameter left an empty line in the settings.
//
// "Distortion Strength", "Distortion Threshold" and also
// "Distortion Bias" are now grouped there and changed to
// "Strength", "Threshold" and "Bias" respectively.  This
// addresses a problem with the originals displaying as
// "Distortion Strengt" and "Distortion Thresho".
//
// For consistency two additional groups have been added,
// "Noise" and "Roll".
//
// All samplers have been explicitly declared to address the
// differing Windows - Mac/Linux defaults.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "VHS v2";
   string Category    = "Stylize";
   string SubCategory = "Simulation";
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

sampler InputSampler = sampler_state { Texture = <Input>;
	AddressU = Border;
        AddressV = Wrap;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler Samp1 = sampler_state { Texture = <Tex1>;
	AddressU = Border;
        AddressV = Wrap;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
};
sampler Samp2 = sampler_state { Texture = <Tex2>;
	AddressU = Border;
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

float Lines
<
	string Description = "Vertical Resolution";
	float MinVal = 0.00;
	float MaxVal = 1.00;
> = 1.0;

float ORGX
<
	string Group = "Distortion";
	string Description = "Source X pos";
	float MinVal = 0.00;
	float MaxVal = 1.00;
> = 0.02;

bool Invert
<
	string Group = "Distortion";
	string Description = "Negate Source";
> = false;

float Strength
<
	string Group = "Distortion";
	string Description = "Strength";
	float MinVal = 0.00;
	float MaxVal = 1.00;
> = 0.1;

float Threshold
<
	string Group = "Distortion";
	string Description = "Threshold";
	float MinVal = 0.00;
	float MaxVal = 1.00;
> = 0.5;

float Bias
<
	string Group = "Distortion";
	string Description = "Bias";
	float MinVal = -0.50;
	float MaxVal = 0.50;
> = 0.0;

float WNoise
<
	string Group = "Noise";
	string Description = "White Noise";
	float MinVal = 0.00;
	float MaxVal = 1.00;
> = 0.1;

float RNoise
<
	string Group = "Noise";
	string Description = "Red Noise";
	float MinVal = 0.00;
	float MaxVal = 1.00;
> = 0.1;

float BNoise
<
	string Group = "Noise";
	string Description = "Blue Noise";
	float MinVal = 0.00;
	float MaxVal = 1.00;
> = 0.1;

int RMult
<
	string Group = "Roll";
	string Description = "Speed Multiplier";
	string Enum = "x1,x10,x100";
> = 0;

float Roll
<
	string Group = "Roll";
	string Description = "Speed";
	float MinVal = -10.00;
	float MaxVal = 10.00;
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


float random( float2 p )
{
	const float2 r = float2(
		23.1406926327792690,  // e^pi (Gelfond's constant)
		2.6651441426902251); // 2^sqrt(2) (Gelfond–Schneider constant)
	return frac( cos( fmod( 123456789., 1e-7 + 256. * dot(p,r) ) ) );  
}

float4 main( float2 uv : TEXCOORD1 ) : COLOR
{
	float4 source = float4(0,0,0,1);
	float4 ret = source;
	float4 strip = tex2D(InputSampler,float2(ORGX,uv.y));
	float luma = (strip.r + strip.g + strip.b) / 3.0;
	if (Invert) luma = 1.0-((abs(luma - (0.5 + Bias))) * 2.0);
	else luma = abs(luma - (0.5 + Bias)) * 2.0;
	if (luma >= Threshold)
	{
		if (random(float2((uv.x+0.5)*luma,(_Progress+0.5)*uv.y)) / Strength < (WNoise / 5.0)) ret = float4(1,1,1,1);
		if (random(float2((uv.y+0.5)*luma,(_Progress+0.4)*uv.x)) / Strength < (RNoise / 10.0)) ret = float4(0.75,0,0,1) * (1.0-(luma - Threshold));
		if (random(float2((uv.x+0.5)*luma,(_Progress+0.3)*uv.x)) / Strength < (BNoise / 10.0)) ret = float4(0,0,0.75,1) * (1.0-(luma - Threshold));
	}
	if (min(WNoise,Strength) == 0.0 && min(RNoise,Strength) == 0.0 && min(BNoise,Strength) == 0.0) return source;
	else return ret;
}

float4 main0( float2 uv : TEXCOORD1 ) : COLOR
{
	float4 ret;
	float4 source = tex2D(InputSampler,uv);
	float xSize = 5.0 / (Lines * _OutputWidth);                 // 1.0/((Lines/5.0) * _OutputWidth) rewritten to clean up code - jwrl
	float ySize = _OutputAspectRatio / (Lines * _OutputWidth);  // 1.0/(Lines * _OutputHeight) changed to fix LW bug - jwrl
	ret = tex2D( InputSampler, 
		float2( uv.x - 0.5,
			round(( uv.y - 0.5) / ySize ) * ySize) + 0.5);
	return ret;
}

float4 main1( float2 uv : TEXCOORD1 ) : COLOR
{
	float xSize = 5.0 / (Lines * _OutputWidth);                 // 1.0/((Lines/5.0) * _OutputWidth) rewritten to clean up code - jwrl
	float ySize = _OutputAspectRatio / (Lines * _OutputWidth);  // 1.0/(Lines * _OutputHeight) changed to fix LW bug - jwrl
	float rmult = ceil (pow (10.0, (float) RMult));             // Rewritten to resolve an ambiguous overload - jwrl
	float flip = _Progress * Roll * rmult;                      // Rewritten to remove a redundant (float) cast - jwrl
	uv = float2(uv.x, uv.y + flip);
	float4 orig = tex2D(Samp2,uv);
	float4 noise;
	float4 strip = tex2D(Samp2,float2(ORGX,uv.y));
	float luma = (strip.r + strip.g + strip.b) / 3.0;
	if (Invert) luma = 1.0-((abs(luma - (0.5 + Bias))) * 2.0);
	else luma = abs(luma - (0.5 + Bias)) * 2.0;
	float2 newuv = uv;
	float2 noiseuv = float2( round(( uv.x - 0.5) / xSize ) * xSize,
				round(( uv.y - 0.5) / ySize ) * ySize) + 0.5;
 	if (luma >= Threshold)
	{
		newuv.x = uv.x - ((luma - Threshold) * Strength);
		noiseuv.x = noiseuv.x - ((luma - Threshold) * Strength);
		orig.r = tex2D(Samp2,float2(newuv.x+(xSize * (luma - Threshold) * Strength * 33.0),newuv.y)).r;
		orig.g = tex2D(Samp2,newuv).g;
		orig.b = tex2D(Samp2,float2(newuv.x-(xSize * (luma - Threshold) * Strength * 33.0),newuv.y)).b;
		noise = tex2D(Samp1,noiseuv);
		orig = max(orig,noise);
	}
	return orig;
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass Pass1
   <
   string Script = "RenderColorTarget0 = Tex1;";
   >
   {
      PixelShader = compile PROFILE main();
   }
   
   pass Pass2
   <
   string Script = "RenderColorTarget0 = Tex2;";
   >
   {
      PixelShader = compile PROFILE main0();
   }
   
   pass Pass3
   {
      PixelShader = compile PROFILE main1();
   }
   
}

