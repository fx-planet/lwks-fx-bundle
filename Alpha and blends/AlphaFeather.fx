// @Maintainer jwrl
// @Released 2018-04-05
// @Author khaver
// @Created -unknown-
// @see http://www.lwks.com/media/kunena/attachments/1246/AFExample.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect AlphaFeather.fx
//
// The Alpha Feather effect was created to help bed an externally generated graphic with
// alpha channel into an existing background after it was noticed that the standard LW
// Blend/In Front effect can give foreground images sharp, slightly aliased edges.  It
// will allow feathering the edges of the foreground image with the background image by
// blurring both in the blend region.  The blurring is a true gaussian blur and provides
// controls allow you to change the blur radius and threshold.
//
// Cross platform compatibility check 26 July 2017 jwrl.
// Explicitly defined samplers to correct a cross-platform default sampler bug.
// Added workaround for the interlaced media height bug in Lightworks effects.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects on GitHub.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha Feather";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture fg;
texture bg;

texture composite : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture   = <fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler CompSampler = sampler_state {
   Texture   = <composite>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputWidth;
float _OutputAspectRatio;

float offset[5] = {0.0, 1.0, 2.0, 3.0, 4.0 };
float weight[5] = {0.2734375, 0.21875 / 4.0, 0.109375 / 4.0,0.03125 / 4.0, 0.00390625 / 4.0};

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Composite(float2 xy1 : TEXCOORD1) : COLOR
{
	float4 fg = tex2D( FgSampler, xy1 );
	float4 bg = tex2D( BgSampler, xy1 );
	
	float4 ret = lerp( bg, fg, fg.a * Opacity );
	ret.a = fg.a;
	
	return ret;
}

float4 AlphaFeather(float2 uv : TEXCOORD1) : COLOR
{
	float2 pixel = float2(1.0, _OutputAspectRatio) / _OutputWidth;     // Corrects for Lightworks' output height bug with interlaced media - jwrl.
	float4 color;
	float4 Cout;
	float check;
	float4 orig = tex2D(CompSampler,uv);
	check = orig.a;
	color = tex2D(CompSampler, uv) * (weight[0]);
	for (int i=1; i<5; i++) {
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i],0.0f)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather)) * weight[i];
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
