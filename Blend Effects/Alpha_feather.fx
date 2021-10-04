// @Maintainer jwrl
// @Released 2021-08-10
// @Author khaver
// @Created 2012-12-10
// @see https://www.lwks.com/media/kunena/attachments/6375/AlphaFeather_640.png

/**
 The Alpha Feather effect was created to help bed an externally generated graphic with
 an alpha channel into an existing background after it was noticed that the standard LW
 Blend/In Front effect can give foreground images sharp, slightly aliased edges.  It will
 allow feathering the edges of the foreground image with the background image by blurring
 both in the blend region.  The blurring is a true gaussian blur and provides controls to
 allow you to change the blur radius and threshold.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Alpha_feather.fx
//
// Version history:
//
// Rewrite 2021-08-10 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Upgrades before 2020-11-08:
// Modifications primarily related cross-platform issues.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha Feather";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Helps bed an externally generated graphic with transparency into a background";
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

#define DefineTargetAddress(TARGET, SAMPLER, ADDRESS) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ADDRESS;               \
   AddressV  = ADDRESS;               \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputWidth;
float _OutputAspectRatio;

float offset[5] = {0.0, 1.0, 2.0, 3.0, 4.0 };
float weight[5] = {0.2734375, 0.21875 / 4.0, 0.109375 / 4.0,0.03125 / 4.0, 0.00390625 / 4.0};

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTargetAddress (RawFg, FgSampler, Mirror);
DefineTargetAddress (RawBg, BgSampler, Mirror);

DefineTargetAddress (composite, CompSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
	string Description = "Opacity";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 1.0f;

float thresh
<
	string Description = "Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.2f;

float Feather
<
	string Description = "Radius";
	float MinVal = 0.0f;
	float MaxVal = 2.0f;
> = 0.0f;

float Mix
<
	string Description = "Mix";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 1.0f;

bool Show
<
	string Description = "Show alpha";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 Composite (float2 uv : TEXCOORD3) : COLOR
{
   float4 fg = GetPixel (FgSampler, uv);
   float4 bg = GetPixel (BgSampler, uv);
   float4 ret = lerp (bg, fg, fg.a * Opacity);

   ret.a = fg.a;

   return ret;
}

float4 AlphaFeather(float2 uv : TEXCOORD3) : COLOR
{
	float2 pixel = float2(1.0, _OutputAspectRatio) / _OutputWidth;     // Corrects for Lightworks' output height bug with interlaced media - jwrl.
	float4 color;
	float4 Cout;
	float check;
	float4 orig = GetPixel(CompSampler,uv);
	check = orig.a;
	color = GetPixel(CompSampler, uv) * (weight[0]);
	for (int i=1; i<5; i++) {
		Cout = GetPixel(CompSampler, uv + (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv + (float2(pixel.x * offset[i],0.0f)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = GetPixel(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = GetPixel(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = GetPixel(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = GetPixel(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = GetPixel(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = GetPixel(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = GetPixel(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += GetPixel(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather)) * weight[i];
		else color += orig * (weight[i]);
	}

	color.a = 1.0;
	orig.a = 1.0;

	if (Show) return check.xxxx;
	else return lerp(orig,color,Mix);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Alph
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass one < string Script = "RenderColorTarget0 = composite;"; > ExecuteShader (Composite)
   pass two ExecuteShader (AlphaFeather)
}

