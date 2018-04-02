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
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Also fully defined float3 variable to fix the behavioural
// differences between the D3D and Cg compilers in mathematical
// functions.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Grain";       // The title
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


texture Input;

sampler FgSampler = sampler_state
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

float Strength
<
	string Description = "Strength";
	string Group = "Master";
	float MinVal = 0.00;
	float MaxVal = 100.0;
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
   float4 source = tex2D( FgSampler, xy );
   float x = sin(loc.x) + cos(loc.y) + _rand(loc,((source.g+1.0)*loc.x)) * 1000;
   float grain = frac(fmod(x, 13) * fmod(x, 123)) - 0.5f;

   source.rgb = saturate (source.rgb + (grain * (Strength / 100)).xxx);
  
   return source;

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
      PixelShader = compile PROFILE Grain();
   }
}

