// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Cross platform compatibility check 29 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Addressing has been changed from Clamp to Mirror to bypass
// a bug in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Chromatic Aberration Fixer";
   string Category    = "Colour";
   string SubCategory = "Repair";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _OutputAspectRatio;

texture V;

sampler VSampler = sampler_state
{
   Texture = <V>;
   AddressU  = Mirror;
   AddressV  = Mirror;
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

float radjust
<
   string Description = "Red adjust";
   float MinVal       = -1.0f;
   float MaxVal       = 1.0f;
> = 0.0f; // Default value

float gadjust
<
   string Description = "Green adjust";
   float MinVal       = -1.0f;
   float MaxVal       = 1.0f;
> = 0.0f; // Default value

float badjust
<
   string Description = "Blue adjust";
   float MinVal       = -1.0f;
   float MaxVal       = 1.0f;
> = 0.0f; // Default value

bool saton
<
   string Description = "Saturation";
   string Group = "Saturation";
> = false;

float sat
<
   string Description = "Adjustment";
   string Group = "Saturation";
   float MinVal       = 0.0f;
   float MaxVal       = 4.0f;
> = 2.0f; // Default value

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
float4 CAFix( float2 xy : TEXCOORD1 ) : COLOR
{
   float satad = sat;
   if (!saton) satad = 1.0f;
   float lumw = float3(0.299,0.587,0.114);
   float rad = ((radjust * 2 + 4)/100) + 0.96;
   float gad = ((gadjust * 2 + 4)/100) + 0.96;
   float bad = ((badjust * 2 + 4)/100) + 0.96;
   float red = tex2D(VSampler, float2( ((xy.x-0.5f)/(rad*_OutputAspectRatio/_OutputAspectRatio))+0.5f, ((xy.y-0.5f)/rad)+0.5f )).r;
   float green = tex2D(VSampler, float2( ((xy.x-0.5f)/(gad*_OutputAspectRatio/_OutputAspectRatio))+0.5f, ((xy.y-0.5f)/gad)+0.5f )).g;
   float blue = tex2D(VSampler, float2( ((xy.x-0.5f)/(bad*_OutputAspectRatio/_OutputAspectRatio))+0.5f, ((xy.y-0.5f)/bad)+0.5f )).b;
   float alpha = tex2D(VSampler,xy).a;
   float3 source = float3(red,green,blue);
   float3 lum = dot(source, lumw);
   float3 dest = lerp(lum, source, satad);
   return float4(dest,alpha);
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
      PixelShader = compile PROFILE CAFix();
   }
}

