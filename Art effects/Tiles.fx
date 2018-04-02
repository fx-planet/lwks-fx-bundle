// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Bug fix 21 July 2017 by jwrl:
// This addresses a cross platform issue which could cause the
// effect to not behave as expected on Linux and Mac systems.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tiles";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _OutputWidth;

texture Input;

sampler FgSampler = sampler_state {
   Texture = <Input>;
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

float Size
<
   string Description = "Size";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.05; // Default value

float Threshhold
<
   string Description = "Edge Width";
   float MinVal       = 0.0;
   float MaxVal       = 2.0;
> = 0.15; // Default value

float4 EdgeColor
<
   string Description = "Color";
   bool SupportsAlpha = false;
> = { 0.7, 0.7, 0.7, 1.0 };

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

float4 tilesPS (float2 xy : TEXCOORD1) : COLOR
{
   if (Size <= 0.0) return tex2D (FgSampler, xy);

   float threshholdB =  1.0 - Threshhold;

   float2 Pbase = xy - fmod (xy, Size.xx);
   float2 PCenter = Pbase + (Size / 2.0).xx;
   float2 st = (xy - Pbase) / Size;

   float3 cTop = 0.0.xxx;
   float3 cBottom = 0.0.xxx;
   float3 invOff = 1.0.xxx - EdgeColor.rgb;

   if ((st.x > st.y) && any (st > threshholdB)) { cTop = invOff; }

   if ((st.x > st.y) && any (st < Threshhold)) { cBottom = invOff; }

   float4 tileColor = tex2D (FgSampler, PCenter);

   return float4 (max (0.0.xxx, (tileColor.rgb + cBottom - cTop)), tileColor.a);
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
      PixelShader = compile PROFILE tilesPS ();
   }
}

