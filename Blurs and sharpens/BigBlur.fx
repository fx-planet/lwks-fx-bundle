// @Maintainer jwrl
// @Released 2018-04-05
// @Author khaver
// 
// @see https://www.lwks.com/media/kunena/attachments/6375/BigBlur.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect BigBlur.fx
//
// Smooth blur using a 12 tap circular kernel that rotates 5 degrees for each of 6
// passes.  There's a checkbox for a 10 fold increase in the blur amount.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Bug fix 26 February 2017 by jwrl:
// Added workaround for the interlaced media height bug in Lightworks effects.  THE BUG
// WAS NOT IN THE WAY THIS EFFECT WAS ORIGINALLY IMPLEMENTED.  When a height parameter is
// needed one cannot reliably use _OutputHeight with interlaced media.  It returns only
// half the actual frame height when interlaced media is stationary.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Big Blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Pass1 : RenderColorTarget;
texture Pass2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique BigBlur
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
