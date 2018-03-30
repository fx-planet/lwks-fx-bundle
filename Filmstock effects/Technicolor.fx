//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Added subcategory for LW14 18 February 2017 - jwrl.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Technicolor";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
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
int SetTechnique
<
   string Description = "Emulation";
   string Enum = "Two_Strip,Three_Strip";
> = 0;

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
float4 Techni2( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 source = tex2D( FgSampler, xy );

   float4 output;
   output.r = source.r;
   output.g = (source.g/2.0) + (source.b/2.0);
   output.b = (source.b/2.0) + (source.g/2.0);
   output.a = 0;
   return output;
}
float4 Techni3( float2 xy : TEXCOORD1 ) : COLOR
{
   float4 source = tex2D( FgSampler, xy );

   float4 output;
   output.r = source.r - (source.g/2.0) + (source.b/2.0);
   output.g = source.g - (source.r/2.0) + (source.b/2.0);
   output.b = source.b - (source.r/2.0) + (source.g/2.0);
   output.a = 0;
   return output;
}

//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique Two_Strip
{
   pass SinglePass
   {
      PixelShader = compile PROFILE Techni2();
   }
}

technique Three_Strip
{
   pass SinglePass
   {
      PixelShader = compile PROFILE Techni3();
   }
}

