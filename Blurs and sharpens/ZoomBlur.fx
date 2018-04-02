// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// ZoomBlur.fx created by Gary Hango (khaver) January 2012.
//
// This cross platform conversion by jwrl 20 July 2017.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Added LINUX and OSX test to allow support for changing
// "Clamp" to "ClampToEdge" on those platforms.  It will now
// function correctly when used with Lightworks versions 14.5
// and higher under Linux or OS-X and fixes a bug associated
// with using this effect with transitions on those platforms.
//
// The bug still exists when using older versions of Lightworks.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "ZoomBlur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler InputSampler = sampler_state {
	Texture = <Input>;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float CX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float CY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float BlurAmount
<
   string Description = "Strength";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR
{
   float4 c = 0.0.xxxx;

   float2 Center = float2 (CX, 1.0 - CY);
   float2 xy = uv - Center;

   float scale = 1.0;
   float sDiff = BlurAmount / 40.0;

   for (int i = 0; i < 41; i++) {
      c += tex2D (InputSampler, xy * scale + Center);
      scale -= sDiff;
   }

   return c / 41.0;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pass1
   {
      PixelShader = compile PROFILE main ();
   }
}

