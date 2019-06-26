// @Maintainer jwrl
// @Released 2018-12-27
// @Author khaver
// @Created 2014-11-19
// @see https://www.lwks.com/media/kunena/attachments/6375/VHSv2_640.png

/**
This effect simulates a damaged VHS tape.  Use the Source X pos slider to locate the
vertical strip down the frame that affects the distortion.  The horizontal distortion
uses the luminance value along this vertical strip.  The threshold adjusts the value
that triggers the distortion and white, red and blue noise can be added.  There's also
a Roll control to roll the image up or down at different speeds.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VHSsimulator.fx
//
// VHS by khaver (cross-platform V2 mod by jwrl)
//
// LW 14+ version by jwrl 12 February 2017 - added subcategory.
//
// Code cleanup 25 February 2017 by jwrl:
// Bug fix to correct for a bug in the way that Lightworks handles interlaced media.
// All samplers explicitly declared to fix the differing Windows - Mac/Linux defaults.
// Unused parameter to set the Y value in the distortion source group removed.
// A new group "Distortion" was added because removing the Y parameter left an empty
// line in the settings.
// "Distortion Strength", "Distortion Threshold" and "Distortion Bias" are now grouped
// in the new "Distortion" group and changed to "Strength", "Threshold" and "Bias".
// For consistency two additional groups have been added, "Noise" and "Roll".
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 7 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "VHS simulator";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Simulates a damaged VHS tape";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Tex1 : RenderColorTarget;
texture Tex2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

float random( float2 p )
{
	const float2 r = float2(
		23.1406926327792690,  // e^pi (Gelfond's constant)
		2.6651441426902251); // 2^sqrt(2) (Gelfond–Schneider constant)
	return frac( cos( fmod( 123456789., 1e-7 + 256. * dot(p,r) ) ) );  
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

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
