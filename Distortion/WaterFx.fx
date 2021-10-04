// @Maintainer jwrl
// @Released 2021-08-30
// @Author khaver
// @Created 2014-11-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Water_640.png

/**
 Water makes waves as well as refraction, and provides X and Y adjustment of the
 parameters.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WaterFx.fx
//
// Version history:
//
// Update 2021-08-30 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Water";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
   string Notes       = "This makes waves as well as refraction, and provides X and Y adjustment of the parameters";
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

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _Progress;

int iSeed = 15;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

SetTargetMode (FixInp, FgSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Speed
<
	string Description = "Speed";
	float MinVal = 0.0;
	float MaxVal = 1000.0;
> = 0.0;

float WavesX
<
	string Description = "X Frequency";
	float MinVal = 0.0;
	float MaxVal = 100.0;
> = 0.0;

float StrengthX
<
	string Description = "X Strength";
	float MinVal = 0.0;
	float MaxVal = 0.1;
> = 0.0;

float WavesY
<
	string Description = "Y Frequency";
	float MinVal = 0.0;
	float MaxVal = 100.0;
> = 0.0;

float StrengthY
<
	string Description = "Y Strength";
	float MinVal = 0.0;
	float MaxVal = 0.1;
> = 0.0;

bool Flip
<
	string Description = "Waves";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 Wavey (float2 uv : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{
   if (Overflow (uv)) return EMPTY;

	int xx;
	int yy;
	float wavesx = WavesX * 2.0;
	float wavesy = WavesY * 2.0;
	if (Flip) {
		xy.x += sin((_Progress*Speed)+xy.y*wavesy)*StrengthY;
		xy.y += cos((_Progress*Speed)+xy.x*wavesx)*StrengthX;
	}
	else {
		xy.x += sin((_Progress*Speed)+xy.x*wavesx)*StrengthX;
		xy.y += cos((_Progress*Speed)+xy.y*wavesy)*StrengthY;
	}
	float4 Color = tex2D(FgSampler,xy);
	return Color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Water
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass SinglePass ExecuteShader (Wavey)
}

