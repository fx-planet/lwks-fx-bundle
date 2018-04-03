// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Cross platform compatibility check 27 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly defined float3 variable to address behavioural
// differences between the D3D and Cg compilers.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Toon";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
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
float RedStrength
<
   string Description = "RedStrength";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 1.00;
   float MaxVal       = 100.00;
> = 4.0; // Default value

float GreenStrength
<
   string Description = "GreenStrength";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 1.00;
   float MaxVal       = 100.00;
> = 4.0; // Default value

float BlueStrength
<
   string Description = "BlueStrength";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 1.00;
   float MaxVal       = 100.00;
> = 4.0; // Default value

float Threshold
<
   string Description = "Threshold";
   string Group       = "Master"; // Causes this parameter to be displayed in a group called 'Master'
   float MinVal       = 0.00;
   float MaxVal       = 10.00;
> = 0.1; // Default value

#pragma warning ( disable : 3571 )

#define NUM 9

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
float4 dirtyToonPS( float2 xy : TEXCOORD1 ) : COLOR
{
   // Read a pixel from the source image at position 'xy'
   // and place it in the variable 'color'
   float4 color = tex2D( FgSampler, xy );

	color.r = round(color.r*RedStrength)/RedStrength;
	color.g = round(color.g*GreenStrength)/GreenStrength;
	color.b = round(color.b*BlueStrength)/BlueStrength;
	
	const float threshold = Threshold;

	float2 c[NUM] =
	{
		float2(-0.0078125, 0.0078125), 
		float2( 0.00 ,     0.0078125),
		float2( 0.0078125, 0.0078125),
		float2(-0.0078125, 0.00 ),
		float2( 0.0,       0.0),
		float2( 0.0078125, 0.007 ),
		float2(-0.0078125,-0.0078125),
		float2( 0.00 ,    -0.0078125),
		float2( 0.0078125,-0.0078125),
	};	

	int i;
	float3 col[NUM];
	for (i=0; i < NUM; i++)
	{
		col[i] = tex2D(FgSampler, xy + 0.2*c[i]).rgb;
	}
	
	float3 rgb2lum = float3(0.30, 0.59, 0.11);
	float lum[NUM];
	for (i = 0; i < NUM; i++)
	{
		lum[i] = dot(col[i].xyz, rgb2lum);
	}
	float x = lum[2]+  lum[8]+2*lum[5]-lum[0]-2*lum[3]-lum[6];
	float y = lum[6]+2*lum[7]+  lum[8]-lum[0]-2*lum[1]-lum[2];
	float edge =(x*x + y*y < threshold)? 1.0:0.0;
	
	color.rgb *= edge;
	return color;
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
      PixelShader = compile PROFILE dirtyToonPS();
   }
}

