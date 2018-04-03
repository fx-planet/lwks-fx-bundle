// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Strobe";        // The title
   string Category    = "Stylize";            // Governs the category that the effect appears in in Lightworks
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture fg;
texture bg;

sampler FGround = sampler_state {
        Texture = <fg>;
        AddressU = Clamp;
        AddressV = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler BGround = sampler_state {
        Texture = <bg>;
        AddressU = Clamp;
        AddressV = Clamp;
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

float _Progress;

bool swap
<
	string Description = "Swap";
> = false;

float strobe
<
	string Description = "Strobe Spacing";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 1.0f;

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

float4 Combine( float2 uv : TEXCOORD1 ) : COLOR
{
  float maxi = 20000;
  float theprogress = 20000.0 * _Progress;
  float mini = 20000 * strobe;
  float4 FG, BG;
  if (swap) {
	BG = tex2D( BGround, uv);
	FG = tex2D( FGround, uv);
  }
  else {
	BG = tex2D( FGround, uv);
	FG = tex2D( BGround, uv);
  }
  float rem = frac(ceil(theprogress/mini) / 2.0);
  if (rem == 0.0) return FG;
  else return BG;
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
   {
      PixelShader = compile PROFILE Combine();
   }
}

