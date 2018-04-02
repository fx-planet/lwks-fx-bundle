// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Bug fix 13 July 2017 by jwrl:
// This addresses a cross platform issue which may have caused
// the effect not to behave as expected on either Linux or Mac
// systems.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Glass Tiles";       // The title
   string Category    = "Stylize";           // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Distortion";        // Added for LW14 - jwrl
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)
float _OutputWidth;
texture Input;


sampler FgSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
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
float Tiles
<
   string Description = "Tiles";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0f;
> = 15.0; // Default value

float BevelWidth
<
   string Description = "Bevel Width";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0f;
> = 15.0; // Default value

float Offset
<
   string Description = "Offset";
   float MinVal       = 0.0f;
   float MaxVal       = 200.0f;
> = 0.0; // Default value

float4 GroutColor
<
   string Description = "Grout Color";
   bool SupportsAlpha = true;
> = { 0.0f, 0.0f, 0.0f, 0.0f };


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

half4 GtilesPS(float2 uv : TEXCOORD1) : COLOR {
	float2 newUV1;
	newUV1.xy = uv.xy + tan((Tiles*2.5)*(uv.xy-0.5f) + Offset)*(BevelWidth/_OutputWidth);
	float4 c1 = tex2D(FgSampler, newUV1);
	if(newUV1.x<0 || newUV1.x>1 || newUV1.y<0 || newUV1.y>1)
	{
	c1 = GroutColor;
	}
	c1.a=1;
	return c1;
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass p0
   {
      PixelShader = compile PROFILE GtilesPS();
   }
}

