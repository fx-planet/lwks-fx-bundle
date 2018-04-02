// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Added subcategory for LW14 - jwrl 18 Feb 2017
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bulge";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;



//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//

float zoom
<
	string Description = "Zoom";
	float MinVal = -3.00;
	float MaxVal = 3.00;
> = 0.00;


float bulge_size
<
	string Description = "Bulge size";
	float MinVal = 0.00;
	float MaxVal = 0.50;
> = 0.25;


bool environment
<
	string Description = "Distort environment";
> = false;


bool black
<
	string Description = "Transparency on";
> = false;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;


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
   AddressU = Mirror;
   AddressV = Mirror;
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

float _OutputAspectRatio;
	

        


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

float4 universal (float2 xy : TEXCOORD1) : COLOR 
{ 
   float2 XYc = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = XYc - xy;
   float2 pos_zoom = float2 (xy1.x, xy1.y / _OutputAspectRatio);
   float distortion = 0;

   float _distance = distance ((0.0).xx, pos_zoom);

   if ((_distance < (bulge_size)) || (environment))
      distortion = zoom * sqrt (sin (bulge_size - _distance));
 
   if ((_distance > bulge_size) && (black))
      return (0.0).xxxx;

   xy1 = distortion * xy1 + xy;

   return tex2D (FgSampler, xy1);
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
      PixelShader = compile PROFILE universal ();
   }
}

