// @Maintainer jwrl
// @Released 2021-07-26
// @Author khaver
// @Created 2011-04-18
// @see https://www.lwks.com/media/kunena/attachments/6375/Toon_640.png

/**
 In Toon (ToonFx.fx) the image is posterized, then outlines are developed from the image
 edges.  These are then applied on top of the already posterized image to give the final
 result.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Toon.fx
//
// Version history:
//
// Update 2021-07-26 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 23 December 2018:
// Various changes to better support cross platform versions.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Toon";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "The image is posterized then outlines derived from the edges are added to produce a cartoon-like result";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define NUM 9

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, FgSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float RedStrength
<
   string Description = "RedStrength";
   string Group       = "Master";
   string Flags       = "DisplayAsPercentage";
   float MinVal       = 1.0;
   float MaxVal       = 100.0;
> = 4.0; // Default value

float GreenStrength
<
   string Description = "GreenStrength";
   string Group       = "Master";
   string Flags       = "DisplayAsPercentage";
   float MinVal       = 1.0;
   float MaxVal       = 100.0;
> = 4.0; // Default value

float BlueStrength
<
   string Description = "BlueStrength";
   string Group       = "Master";
   string Flags       = "DisplayAsPercentage";
   float MinVal       = 1.0;
   float MaxVal       = 100.0;
> = 4.0; // Default value

float Threshold
<
   string Description = "Threshold";
   string Group       = "Master";
   float MinVal       = 0.0;
   float MaxVal       = 10.0;
> = 0.1; // Default value

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 dirtyToonPS (float2 uv : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{
   // Read a pixel from the source image at position 'xy'
   // and place it in the variable 'color'
   float4 color = tex2D( FgSampler, xy );

   float alpha = color.a;

	color.r = round(color.r*RedStrength)/RedStrength;
	color.g = round(color.g*GreenStrength)/GreenStrength;
	color.b = round(color.b*BlueStrength)/BlueStrength;

	const float threshold = Threshold;

	float2 c[NUM] =
	{
		float2(-0.0078125, 0.0078125),
		float2( 0.00 ,     0.0078125),
		float2( 0.0078125, 0.0078125),
		float2(-0.0078125, 0.00 ),
		float2( 0.0,       0.0),
		float2( 0.0078125, 0.007 ),
		float2(-0.0078125,-0.0078125),
		float2( 0.00 ,    -0.0078125),
		float2( 0.0078125,-0.0078125),
	};

	int i;
	float3 col[NUM];
	for (i=0; i < NUM; i++)
	{
		col[i] = tex2D(FgSampler, xy + 0.2*c[i]).rgb;
	}

	float3 rgb2lum = float3(0.30, 0.59, 0.11);
	float lum[NUM];
	for (i = 0; i < NUM; i++)
	{
		lum[i] = dot(col[i].xyz, rgb2lum);
	}
	float x = lum[2]+  lum[8]+2*lum[5]-lum[0]-2*lum[3]-lum[6];
	float y = lum[6]+2*lum[7]+  lum[8]-lum[0]-2*lum[1]-lum[2];
	float edge =(x*x + y*y < threshold)? 1.0:0.0;

	color.rgb *= edge;

        if (Overflow (uv)) color = EMPTY;

	return lerp (EMPTY, color, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Toon
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass SinglePass ExecuteShader (dirtyToonPS)
}

