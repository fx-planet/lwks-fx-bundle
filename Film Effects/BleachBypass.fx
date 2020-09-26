// @Maintainer jwrl
// @Released 2020-09-27
// @Author msi
// @Created 2011-05-27
// @License "CC BY-NC-SA"
// @see https://www.lwks.com/media/kunena/attachments/6375/bleachbypass_640.png

/**
 This effect emulates the altered contrast and saturation obtained by skipping the bleach
 step in classical colour film processing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BleachBypass.fx
//
// [CC BY-NC-SA]
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Bug fix 31 July 2017 by jwrl.
// Explicitly defined sampler to ensure cross platform default sampler state
// compatibility.
//
// Added subcategory for LW14 - jwrl, 18 Feb 2017.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bleach bypass";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Emulates the altered contrast and saturation obtained by skipping the bleach step in classical colour film processing";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler MsiBleachSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Red
<
	string Description = "Red Channel";
	string Group = "Luminosity";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.25;

float Green
<
	string Description = "Green Channel";
	string Group = "Luminosity";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.65;

float Blue
<
	string Description = "Blue Channel";
	string Group = "Luminosity";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.11;

float BlendOpacity
<
	string Description = "Blend Opacity";
	string Group       = "Overlay";
	float MinVal       = 0.0;
	float MaxVal       = 1.0;
> = 1.0;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 Bleach_v2_FX( float2 xy: TEXCOORD1 ) : COLOR
{
	float4 source = tex2D( MsiBleachSampler, xy );
	// BEGIN Bleach bypass routine by NVidia
	// (http://developer.download.nvidia.com/shaderlibrary/webpages/hlsl_shaders.html#post_bleach_bypass)
	float lum = dot( float3( Red, Green, Blue ), source.rgb );
	float3 result1 = 2.0f * source.rgb * lum.rrr;
	float3 result2 = 1.0f - 2.0f * ( 1.0f - lum.rrr ) * ( 1.0f - source.rgb );
	float3 newC = lerp( result1, result2, min( 1, max( 0, 10 * ( lum - 0.45 ) ) ) );
	float3 mixRGB = ( BlendOpacity * source.a ) * newC.rgb;
	mixRGB += ( ( 1.0f - ( BlendOpacity * source.a ) ) * source.rgb );
	// END Bleach bypass routine by NVidia
	return float4( mixRGB, source.a );
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BleachBypassFXTechnique
{
	pass SinglePass
	{
		PixelShader = compile PROFILE Bleach_v2_FX();
	}
}
