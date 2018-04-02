// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Version 14 update 18 Feb 2017 jwrl.
//
// Changed category from "Keying" to "Key", added subcategory
// to effect header.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "DeltaMask";
   string Category    = "Key";
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


bool show
<
	string Description = "Show";
> = false;

bool split
<
	string Description = "Split Screen";
> = false;

bool swap
<
	string Description = "Swap Tracks";
> = false;

bool red
<
	string Description = "Red";
> = true;

float rthresh
<
	string Description = "Red Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

bool green
<
	string Description = "Green";
> = true;

float gthresh
<
	string Description = "Green Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

bool blue
<
	string Description = "Blue";
> = true;

float bthresh
<
	string Description = "Blue Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float mthresh
<
	string Description = "Master Threshold";
	float MinVal = -1.0f;
	float MaxVal = 1.0f;
> = 0.0f;

float bgain
<
	string Description = "Background Gain";
	float MinVal = 0.0f;
	float MaxVal = 2.0f;
> = 1.0f;

bool invert
<
	string Description = "Invert Mask";
> = false;



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

float4 DoIt( float2 uv : TEXCOORD1 ) : COLOR
{
  float4 FG, BG, ocolor;
  float delt;
  float ralph, galph, balph, alph;
  if (swap) {
    BG = tex2D( FGround, uv);
    FG = tex2D( BGround, uv);
  }
  else {
    BG = tex2D( BGround, uv);
    FG = tex2D( FGround, uv);
  }
  BG *= bgain;
 if (split && !show) {
    if (uv.x < 0.5) ocolor = FG; 
    else  ocolor = BG;
	return ocolor;
  }	
  ralph = abs(BG.r - FG.r);
  galph = abs(BG.g - FG.g);
  balph = abs(BG.b - FG.b);
  if (!red) ralph = 0.0;
  if (!green) galph = 0.0;
  if (!blue) balph = 0.0;
  if (ralph <= rthresh + mthresh && galph <= gthresh + mthresh && balph <= bthresh + mthresh) alph = 0.0;
  else alph = 1.0;
  if (invert) alph = 1.0 - alph;
  if (show) ocolor = float4(alph, alph, alph, 1.0);
  else ocolor = float4(FG.r, FG.g, FG.b, alph);
  return ocolor;
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
      PixelShader = compile PROFILE DoIt();
   }
}

