// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Added subcategory for LW14 18 Feb 2017 - jwrl.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Old Time Movie";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _Progress;

texture Noise;
texture Input;

sampler NoiseSampler = sampler_state
{
   Texture   = <Noise>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
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

bool UseSource
<
	string Description = "Use source video";
> = true;

float ScratchAmount
<
   string Description = "Scratch Amount";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.05; // Default value

float NoiseAmount
<
   string Description = "Noise Amount";
   float MinVal       = 0.0;
   float MaxVal       = 0.1;
> = 0.000001; // Default value

float R1X
<
   string Description = "Origin 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float R1Y
<
   string Description = "Origin 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;
float R2X
<
   string Description = "Origin 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float R2Y
<
   string Description = "Origin 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

bool NoiseTrack
<
	string Description = "Show noise track";
> = false;

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
float4 main( float2 uv : TEXCOORD1 ) : COLOR
{
   float2 RandomCoord1 = float2(R1X,R1Y);
   float2 RandomCoord2 = float2(R2X,R2Y);
   float2 randpoint = float2(lerp(R1X,R2X,_Progress),lerp(R1Y,R2Y,_Progress));
   float ScratchAmountInv = 1.0 / ScratchAmount;
   float4 color;
   if (UseSource) color = tex2D(NoiseSampler,uv);
   else color = tex2D(InputSampler,uv);
   
   float2 sc = randpoint * float2(0.001f, 0.4f);
   sc.x = frac(uv.x + sc.x);
   float scratch;
   scratch = 1.0f - tex2D(NoiseSampler, sc.yx).g;
   scratch = 2.0f * scratch * ScratchAmountInv;
   scratch = 1.0f - abs(1.0f - scratch);
   scratch = max(0, scratch);
   color.rgb += scratch.rrr;
   
   float2 rCoord = (uv + randpoint) * 0.5;
   float3 rand;
   rand = tex2D(NoiseSampler, rCoord.yx/2.0f);
   
   if(NoiseAmount > rand.g)
   {
   		color.rgb = 1.0f;
   	}
   	
   	float gray = dot(color, float4(0.3,0.59,0.11,0));
   	color = float4(gray * float3(0.9,0.8,0.6), 1);
   	
   	float2 dist = 0.5 - uv;
   	
   	float fluc = tex2D(NoiseSampler, randpoint.yx).g/2.0f;
   	
   	color.rgb *= (0.4 + fluc - dot(dist, dist)) * 2.5;
   	
   	if (NoiseTrack){
   		return tex2D(NoiseSampler,uv);
   	}
   	else return color;
   	
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE main();
   }
}

