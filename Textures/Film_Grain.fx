// @Maintainer jwrl
// @Released 2018-12-27
// @Author khaver
// @Created 2013-06-07
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmGrain_640.png

/**
This effect adds grain to an image either as film-style grain or as random noise.
The grain can be applied to the luminance, chroma, luminance and chroma, or RGB.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Film_Grain.fx
//
// Subcategory added by jwrl 10 Feb 2017
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles interlaced media.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined all samplers to fix crossplatform default sampler state differences.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 7 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film Grain";
   string Category    = "Stylize";
   string SubCategory = "Textures";
   string Notes       = "Adds grain to an image either as film-style grain or as random noise";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture fg;
texture Grain : RenderColorTarget;
texture Blur : RenderColorTarget;
texture Emboss : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler Input = sampler_state {
        Texture = <fg>;
        AddressU = Wrap;
        AddressV = Wrap;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler GSamp = sampler_state {
        Texture = <Grain>;
        AddressU = Mirror;
        AddressV = Mirror;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler BSamp = sampler_state {
        Texture = <Blur>;
        AddressU = Mirror;
        AddressV = Mirror;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler ESamp = sampler_state {
        Texture = <Emboss>;
        AddressU = Mirror;
        AddressV = Mirror;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int show
<
	string Description = "Grain Type";
	string Enum = "Bypass,Plain,Blurred,Film";
> = 3;

int gtype
<
	string Description = "Applied to";
	string Enum = "Luma,Chroma,Luma+Chroma,RGB";
> = 0;

float Mstrength
<
	string Description = "Master Strength";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.1f;

float Lstrength
<
	string Description = "Luma Strength";
	float MinVal = 0.0f;
	float MaxVal = 2.0f;
> = 1.0f;

float Cstrength
<
	string Description = "Chroma Strength";
	float MinVal = 0.0f;
	float MaxVal = 2.0f;
> = 1.0f;

float zoomit
<
	string Description = "Grain Size";
	float MinVal = 0.05f;
	float MaxVal = 5.0f;
> = 1.0f;

float Xbias
<
	string Description = "X";
	float MinVal = -3.0f;
	float MaxVal = 3.0f;
	string Group = "Film Grain Bias";
> = -1.0f;

float Ybias
<
	string Description = "Y";
	float MinVal = -3.0f;
	float MaxVal = 3.0f;
	string Group = "Film Grain Bias";
> = 1.0f;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

//---------------- rand function by Windsturm ------------------
float rand(float2 uv, float seed){
    float rn =  frac(sin(dot(uv, float2(12.9898,78.233)) + seed) * (43758.5453))-0.5f;
    return clamp(rn, -0.5f, 0.5f);
}
 
//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

//---------------------- Generate grain ------------------------
float4 Graintex( float2 xy : TEXCOORD1) : COLOR
{
	float Prog = _Progress + 0.5f;
	float Crand = rand(xy,Prog*xy.y);
	float Rrand = 0.5f + (Crand * (Mstrength * Lstrength));
	Crand = rand(xy,Prog*xy.x);
	float Grand = 0.5f + (Crand * (Mstrength * Cstrength));
	Crand = rand(xy,Prog*(1.0f-xy.x));
	float Brand = 0.5f + (Crand * (Mstrength * Cstrength));
	return float4(Rrand,Grand,Brand,1);
}

//---------------------- Blur the grain ------------------------
float4 Blurtex( float2 xy : TEXCOORD1) : COLOR
{
float2 _pixel = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
	float4 bout = tex2D(GSamp,xy);
	bout += tex2D(GSamp,xy + (_pixel * float2(-1,-1)));
	bout += tex2D(GSamp,xy + (_pixel * float2(0,-1)));
	bout += tex2D(GSamp,xy + (_pixel * float2(1,-1)));
	bout += tex2D(GSamp,xy + (_pixel * float2(-1,0)));
	bout += tex2D(GSamp,xy + (_pixel * float2(1,0)));
	bout += tex2D(GSamp,xy + (_pixel * float2(-1,1)));
	bout += tex2D(GSamp,xy + (_pixel * float2(0,1)));
	bout += tex2D(GSamp,xy + (_pixel * float2(1,1)));
	bout /= 9.0f;
	return bout;
}

//---------------------- Emboss the grain -----------------------
float4 Embosstex( float2 xy : TEXCOORD1) : COLOR
{
	float2 _pixel = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
	float r22 = tex2D(BSamp,xy).r;
	float r11 = tex2D(BSamp,xy + (_pixel * float2(-1*Xbias,-1*Ybias))).r * -1.5f;
	float r33 = tex2D(BSamp,xy + (_pixel * float2(1*Xbias,1*Ybias))).r * 1.5;
	
	float g22 = tex2D(BSamp,xy).g;
	float g11 = tex2D(BSamp,xy + (_pixel * float2(-1*Xbias,-1*Ybias))).g * 1.5f;
	float g33 = tex2D(BSamp,xy + (_pixel * float2(1*Xbias,1*Ybias))).g * -1.5;

	float b22 = tex2D(BSamp,xy).b;
	float b11 = tex2D(BSamp,xy + (_pixel * float2(-1*Xbias,-1*Ybias))).b * -1.5f;
	float b33 = tex2D(BSamp,xy + (_pixel * float2(1*Xbias,1*Ybias))).b * 1.5;
	
	return float4(r11+r22+r33,g11+g22+g33,b11+b22+b33,1);
}

//---------------------- Select the grain -----------------------
float4 Combine( float2 uv : TEXCOORD1 ) : COLOR
{
  float4 cout = 0.0f;
  float R,G,B;
  //------------Zoom the grain------------
  float2 xy = uv - 0.5;
  xy = (xy / zoomit) + 0.5f;
  if (xy.x > 0.99f) xy.x = frac(xy.x);
  if (xy.y > 0.99f) xy.y = frac(xy.y);
  if (xy.x < 0.01f) xy.x = abs(frac(xy.x));
  if (xy.y < 0.01f) xy.y = abs(frac(xy.y));
  
  if (show == 0) return tex2D(Input, uv);     //-----Bypass-----
  
  if (show == 1) {					//------Plain Grain-------
  	R = tex2D( GSamp, xy).r-0.5f;
  	G = tex2D( GSamp, xy).g-0.5f;
  	B = tex2D( GSamp, xy).b-0.5f;
  }
  
  if (show == 2) {					//-----Blurred Grain------
  	R = tex2D( BSamp, xy).r-0.5f;
  	G = tex2D( BSamp, xy).g-0.5f;
  	B = tex2D( BSamp, xy).b-0.5f;
  }
  
  if (show == 3) {					//-----Embossed Grain-----
  	R = tex2D( ESamp, xy).r-0.5f;
  	G = tex2D( ESamp, xy).g-0.5f;
  	B = tex2D( ESamp, xy).b-0.5f;
  }
  
  float4 orig = tex2D(Input, uv);
  
  //----------------Convert RGB to YUV--------------
  float Y = (0.299f * orig.r) + (0.587f * orig.g) + (0.114f * orig.b);
  float Cb = ((-0.168736f * orig.r) + (-0.331264f * orig.g) + (0.5f * orig.b))+0.5f;
  float Cr = ((0.5f * orig.r) + (-0.418688f * orig.g) - (0.081312f * orig.b))+0.5f;

  //--Adjust grain strength according to luma level - Black>Grey>White = 0.0>1.0>0.0
  float Ydelta = 1.0f-abs((Y - 0.5)*2.0f);
  if (gtype == 0 || gtype == 2) Y += (R*Ydelta);							//-----Luma & Luma+Chroma
  if (gtype == 1 || gtype == 2) {Cb += (G*Ydelta); Cr += (B*Ydelta); }		//-----Chroma & Luma+Chroma
  
  //----------------Convert YUV to RGB--------------   
  Cb -= 0.5f;
  Cr -= 0.5f;
  cout.r = Y + (0.0f * Cb) + (1.402f * Cr);
  cout.g = Y + (-0.34414f * Cb) + (-0.71414 * Cr);
  cout.b = Y + (1.772f * Cb) + (0.0f * Cr);
  if (gtype == 3) {cout.r += (B*Ydelta); cout.g += (R*Ydelta); cout.b += (G*Ydelta); } //-----RGB
  cout.a = 1;

  return cout;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FilmGrain
{

   pass Pass1
   <
   string Script = "RenderColorTarget0 = Grain;";
   >
   {
      PixelShader = compile PROFILE Graintex();
   }

   pass Pass2
   <
   string Script = "RenderColorTarget0 = Blur;";
   >
   {
      PixelShader = compile PROFILE Blurtex();
   }
   
   pass Pass3
   <
   string Script = "RenderColorTarget0 = Emboss;";
   >
   {
      PixelShader = compile PROFILE Embosstex();
   }

   pass Pass4
   {
      PixelShader = compile PROFILE Combine();
   }
}
