// @Maintainer jwrl
// @Released 2020-08-01
// @Author jwrl
// @Created 2020-08-01
// @see https://www.lwks.com/media/kunena/attachments/6375/TrueSepia_640.png

/**
 This effect is an attempt to get as near as it's possible to get to a true filmstock
 sepia tone.  As it is increased it converts the image progressively, starting with
 the lightest silver density areas.  In other words, the lighter areas change colour
 first.  This matches the way that the silver sulphide that causes the sepia tone
 develops in actual black and white filmstocks.  The colour of the sepia effect has
 been visually matched with photographic prints as closely as possible.

 Four different black and white conversion presets have been supplied.  There is the
 standard video luminance conversion, a modified RGB average, and two that mimic black
 and white filmstocks, panchromatic and orthochromatic.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TrueSepia.fx
//
// Version history:
//
// Built 2020-08-01 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "True sepia";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "This produces an adjustable true sepia tone";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Greyscale profile";
   string Enum = "Luminance,RGB averaging,Panchromatic film,Orthochromatic film";
> = 2;

float Colour
<
   string Description = "Black and white";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float SepiaAge
<
   string Description = "Sepia tone";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.55;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_L (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float3 sepia = retval.rgb;

   float luma = 1.0 - dot (sepia, float3 (0.299, 0.587, 0.114));

   sepia.r = 1.0 - (luma * 0.732);
   sepia.g = 1.0 - (luma * 0.899);
   sepia.b = 1.0 - luma;

   float SepiaMix = min (1.0, pow (2.0 * (SepiaAge + sepia.b), 4.0) * min (1.0, SepiaAge * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaAge - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Colour), retval.a);
}

float4 ps_main_A (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float3 sepia = retval.rgb;

   float luma = (sepia.r + sepia.g + sepia.b) / 3.0;

   luma  = 1.0 - pow (luma, 1.2);
   luma *= luma;

   sepia.r = 1.0 - (luma * 0.732);
   sepia.g = 1.0 - (luma * 0.899);
   sepia.b = 1.0 - luma;

   float SepiaMix = min (1.0, pow (2.0 * (SepiaAge + sepia.b), 4.0) * min (1.0, SepiaAge * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaAge - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Colour), retval.a);
}

float4 ps_main_P (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float3 sepia = retval.rgb;

   float luma = 1.0 - pow (dot (sepia, float3 (0.217, 0.265, 0.518)), 1.375);

   luma *= luma;

   sepia.r = 1.0 - (luma * 0.732);
   sepia.g = 1.0 - (luma * 0.899);
   sepia.b = 1.0 - luma;

   float SepiaMix = min (1.0, pow (2.0 * (SepiaAge + sepia.b), 4.0) * min (1.0, SepiaAge * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaAge - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Colour), retval.a);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float3 sepia = retval.rgb;

   float luma = 1.0 - dot (sepia, float3 (0.055, 0.463, 0.482));

   luma *= luma;

   sepia.r = 1.0 - (luma * 0.732);
   sepia.g = 1.0 - (luma * 0.899);
   sepia.b = 1.0 - luma;

   float SepiaMix = min (1.0, pow (2.0 * (SepiaAge + sepia.b), 4.0) * min (1.0, SepiaAge * 1.5));
   float Gamma = 1.0 - (1.2 * max (0.0, SepiaAge - 0.5));

   sepia = lerp (sepia.bbb, pow (sepia, Gamma), SepiaMix);

   return float4 (lerp (retval.rgb, sepia, Colour), retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TrueSepia_0
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_L (); }
}

technique TrueSepia_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_A (); }
}

technique TrueSepia_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_P (); }
}

technique TrueSepia_3
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}

