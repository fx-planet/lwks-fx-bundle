// @Maintainer jwrl
// @Released 2021-10-05
// @Author khaver
// @Created 2011-05-25
// @see https://www.lwks.com/media/kunena/attachments/6375/AnaFlare_640.png

/**
 Anamorphic Lens Flare simulates the non-linear flare that an anamorphic lens produces.
 They are those purplish horizontal flares often seen on movie blockbusters.  Use the
 Threshold slider to isolate just the bright lights and the Length slider to adjust the
 size of the flare.  Checking the "Show Flare" checkbox will display the flare against
 black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AnamorphicLensFlare.fx
//
// Version history:
//
// Update 2021-10-05 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
// Simplified code considerably.
//
// Update 2020-11-12 jwrl.
// Added CanSize switch for LW 2021 support.
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
// Cross platform compatibility check 31 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Explicitly defined float4 variables to avoid the difference in behaviour between
// the D3D and Cg compilers.
//
// Modified by jwrl to add a V14 subcategory February 18, 2017.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Anamorphic lens flare";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Simulates the horizontal non-linear flare that an anamorphic lens produces";
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

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
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

float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, InputSampler);

DefineTarget (Sample1, Samp1);
DefineTarget (Sample2, Samp2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float BlurAmount
<
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 12.0;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float adjust
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Hue
<
   string Description = "Hue";
   float MinVal = -0.5;
   float MaxVal = 0.5;
> = 0.0;

bool flare
<
   string Description = "Show Flare";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_adjust (float2 uv : TEXCOORD1) : COLOR
{
   float4 Color = GetPixel (InputSampler, uv);
   float4 c_hue = float4 (0.1.xx, 1.2, 1.0);

   float luma = (Color.r + Color.g + Color.b) / 3.0;

   if (Hue < 0.0) c_hue.r += abs (Hue);

   if (Hue > 0.0) c_hue.g += Hue;

   if (luma < 1.0 - adjust) Color.rgb = 0.0.xxx;

   return Color * c_hue;
}

float4 ps_blur1 (float2 uv : TEXCOORD2) : COLOR
{
   float4 ret = 0.0.xxxx;

   float2 offset = 0.0.xx;
   float2 displacement = float2 (1.0 / _OutputWidth, 0.0);

   for (int count = 0; count < 24; count++) {
      ret += tex2D (Samp1, uv + offset);
      ret += tex2D (Samp1, uv - offset);
      offset += displacement;
   }

   ret /= 48.0;

   return ret;
}

float4 ps_blur2 (float2 uv : TEXCOORD2) : COLOR
{
   float4 ret = 0.0.xxxx;

   float2 offset = 0.0.xx;
   float2 displacement = float2 (BlurAmount / _OutputWidth, 0.0);

   for (int count = 0; count < 24; count++) {
      ret += tex2D (Samp2, uv + offset);
      ret += tex2D (Samp2, uv - offset);
      offset += displacement;
   }

   ret /= 24.0;

   return ret;
}

float4 ps_combine (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float3 blr = tex2D (Samp1, uv2).rgb;

   float4 source = GetPixel (InputSampler, uv1);
   float4 comb = saturate (float4 (source.rgb + blr, source.a));

   return (!flare) ? lerp (source, comb, Strength)
                   : float4 (blr * Strength * 2.0, source.a);
}
   
//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Blur
{
   pass P_1 < string Script = "RenderColorTarget0 = Sample1;"; > ExecuteShader (ps_adjust)
   pass P_2 < string Script = "RenderColorTarget0 = Sample2;"; > ExecuteShader (ps_blur1)
   pass P_3 < string Script = "RenderColorTarget0 = Sample1;"; > ExecuteShader (ps_blur2)
   pass P_4 ExecuteShader (ps_combine)
}

