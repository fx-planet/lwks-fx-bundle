//--------------------------------------------------------------//
// Big Blur by khaver
//
// Smooth blur using a 12 tap circular kernel that rotates 5 degrees
// for each of 6 passes.  There's a checkbox for a 10 fold
// increase in the blur amount.
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// It appears that when a height parameter is needed one can
// not reliably use _OutputHeight.  It returns only half the
// actual frame height when interlaced media is playing and
// only when it is playing.  For that reason the output height
// should always be obtained by dividing _OutputWidth by
// _OutputAspectRatio until such time as the bug in the
// Lightworks code can be fixed.  It seems that after contact
// with the developers that is very unlikely to be soon.
//
// Note: This fix has been fully tested, and appears to be a
// reliable solution regardless of the pixel aspect ratio.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Big Blur";             // The title
   string Category    = "Stylize";              // Governs the category that the effect appears in in Lightworks
   string SubCategory = "Blurs and Sharpens";   // Added for v14 compatibility - jwrl.
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _OutputAspectRatio;
float _OutputWidth;

texture Input;
texture Pass1 : RenderColorTarget;
texture Pass2 : RenderColorTarget;

sampler s0 = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s1 = sampler_state {
   Texture   = <Pass1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s2 = sampler_state {
   Texture   = <Pass2>;
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

float blurry
<
   string Description = "Amount";
   float MinVal = 0.0f;
   float MaxVal = 100.0;
> = 0.0;

bool big
<
   string Description = "x10";
> = false;

bool red
<
   string Description = "Red";
   string Group = "Channels";
> = true;

bool green
<
   string Description = "Green";
   string Group = "Channels";
> = true;

bool blue
<
   string Description = "Blue";
   string Group = "Channels";
> = true;

bool alpha
<
   string Description = "Alpha";
   string Group = "Channels";
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

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float2 halfpix = pixelSize / 2.0;
   float2 coord, sample;

   float4 cOut = tex2D (tSource, texCoord - halfpix);
   float4 orig = tex2D (tSource, texCoord);

   for (int tap = 0; tap < 12; tap++) {
      sincos ((tap * 30) + (run * 5), sample.y, sample.x);
      coord = texCoord + (halfpix * sample * discRadius);
      cOut += tex2D (tSource, coord);
   }

   cOut /= 13.0;

   if (!red) cOut.r = orig.r;
   if (!green) cOut.g = orig.g;
   if (!blue) cOut.b = orig.b;
   if (!alpha) cOut.a = orig.a;

   return cOut;
}

float4 PSMain (float2 Tex : TEXCOORD1, uniform int test) : COLOR
{
   float blur = big ? blurry * 10.0 : blurry;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 halfpix = pixsize / 2.0;

   if (blurry <= 0.0) return tex2D (s0, Tex);

   if (test == 0) return GrowablePoissonDisc13FilterRGBA (s0, Tex, pixsize, blur, test);

   if ((test == 2) || (test == 4)) return GrowablePoissonDisc13FilterRGBA (s2, Tex, pixsize, blur, test);

   return GrowablePoissonDisc13FilterRGBA (s1, Tex, pixsize, blur, test);
}


//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (6 passes total)
//--------------------------------------------------------------
technique SampleFxTechnique
{

   pass PassA
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(0);
   }
   pass PassB
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(1);
   }
   pass PassC
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(2);
   }
   pass PassD
   <
      string Script = "RenderColorTarget0 = Pass2;";
   >
   {
      PixelShader = compile PROFILE PSMain(3);
   }
   pass PassE
   <
      string Script = "RenderColorTarget0 = Pass1;";
   >
   {
      PixelShader = compile PROFILE PSMain(4);
   }
   pass PassF
   {
      PixelShader = compile PROFILE PSMain(5);
   }
}

