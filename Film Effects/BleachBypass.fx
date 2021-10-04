// @Maintainer jwrl
// @Released 2021-09-17
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
// Update 2021-09-17 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// prior to 2018-12-23:
// Various cross-platform fixes and updates.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bleach bypass";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Emulates the altered contrast and saturation obtained by skipping the bleach step in classical colour film processing";
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

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, MsiBleachSampler);

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

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 Bleach_v2_FX( float2 uv: TEXCOORD1 ) : COLOR
{
   float4 source = GetPixel (MsiBleachSampler, uv);

   // BEGIN Bleach bypass routine by NVidia
   // (http://developer.download.nvidia.com/shaderlibrary/webpages/hlsl_shaders.html#post_bleach_bypass)

   float lum = dot (float3 (Red, Green, Blue), source.rgb);

   float3 result1 = 2.0 * source.rgb * lum.rrr;
   float3 result2 = 1.0.xxx - 2.0 * (1.0.xxx - lum.rrr) * (1.0.xxx - source.rgb);
   float3 newC = lerp (result1, result2, saturate (10.0 * (lum - 0.45)));
   float3 mixRGB = (BlendOpacity * source.a) * newC.rgb;

   mixRGB += ((1.0 - (BlendOpacity * source.a)) * source.rgb);

   // END Bleach bypass routine by NVidia

   return float4 (mixRGB, source.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BleachBypassFXTechnique
{
   pass SinglePass ExecuteShader (Bleach_v2_FX)
}

