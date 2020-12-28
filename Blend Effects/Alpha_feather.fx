// @Maintainer jwrl
// @Released 2020-12-28
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
// Rewrite 2020-12-28 jwrl.
// Modification of the original effect to support LW 2021 resolution independence.
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

#define DeclareInput( TEXTURE, SAMPLER ) \
                                         \
   texture TEXTURE;                      \
                                         \
   sampler SAMPLER = sampler_state       \
   {                                     \
      Texture   = <TEXTURE>;             \
      AddressU  = Mirror;                \
      AddressV  = Mirror;                \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define DeclareTarget( TARGET, TSAMPLE ) \
                                         \
   texture TARGET : RenderColorTarget;   \
                                         \
   sampler TSAMPLE = sampler_state       \
   {                                     \
      Texture   = <TARGET>;              \
      AddressU  = Mirror;                \
      AddressV  = Mirror;                \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

float _OutputWidth;
float _OutputAspectRatio;

float offset[5] = {0.0, 1.0, 2.0, 3.0, 4.0 };
float weight[5] = {0.2734375, 0.21875 / 4.0, 0.109375 / 4.0,0.03125 / 4.0, 0.00390625 / 4.0};

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DeclareInput (fg, FgSampler);
DeclareInput (bg, BgSampler);

DeclareTarget (composite, CompSampler);

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
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Composite (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 fg = fn_tex2D (FgSampler, uv1);
   float4 bg = fn_tex2D (BgSampler, uv2);
   float4 ret = lerp (bg, fg, fg.a * Opacity);

   ret.a = fg.a;

   return ret;
}

float4 AlphaFeather(float2 uv : TEXCOORD1) : COLOR
{
	float2 pixel = float2(1.0, _OutputAspectRatio) / _OutputWidth;     // Corrects for Lightworks' output height bug with interlaced media - jwrl.
	float4 color;
	float4 Cout;
	float check;
	float4 orig = fn_tex2D(CompSampler,uv);
	check = orig.a;
	color = fn_tex2D(CompSampler, uv) * (weight[0]);
	for (int i=1; i<5; i++) {
		Cout = fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i],0.0f)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = fn_tex2D(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = fn_tex2D(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = fn_tex2D(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = fn_tex2D(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += fn_tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather)) * weight[i];
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
	pass one
   	<
    	string Script = "RenderColorTarget0 = composite;";
   	>
	{
		PixelShader = compile PROFILE Composite();
	}

	pass two
	{
		PixelShader = compile PROFILE AlphaFeather();
	}
}
