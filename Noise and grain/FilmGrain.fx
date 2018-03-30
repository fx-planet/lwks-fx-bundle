//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Subcategory added by jwrl 10 Feb 2017
//
// Bug fix 26 February 2017 by jwrl:
// This corrects for a bug in the way that Lightworks handles
// interlaced media.  THE BUG WAS NOT IN THE WAY THIS EFFECT
// WAS ORIGINALLY IMPLEMENTED.
//
// The output height is now obtained by dividing _OutputWidth
// by _OutputAspectRatio.  This fix has been fully tested, and
// is reliable regardless of the pixel aspect ratio.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined all samplers so we aren't bitten by cross
// platform default sampler state differences.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film Grain";
   string Category    = "Stylize";
   string SubCategory = "Grain and Noise";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

float _Progress;

float _OutputAspectRatio;
float _OutputWidth;

texture fg;
texture Grain : RenderColorTarget;
texture Blur : RenderColorTarget;
texture Emboss : RenderColorTarget;

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

//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//

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

//---------------- rand function by Windsturm ------------------
float rand(float2 uv, float seed){
    float rn =  frac(sin(dot(uv, float2(12.9898,78.233)) + seed) * (43758.5453))-0.5f;
    return clamp(rn, -0.5f, 0.5f);
}
 
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


//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
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

