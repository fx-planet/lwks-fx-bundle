// @Maintainer jwrl
// @Released 2021-10-05
// @Author khaver
// @Created 2011-05-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Flare_640.png

/**
 Flare is an original effect by khaver which creates an adjustable lens flare effect.
 The origin of the flare can be positioned by adjusting the X and Y sliders or by
 dragging the on-viewer icon with the mouse.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlareFx.fx
//
// Version history:
//
// Update 2021-10-05 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
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
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Bug fix 26 February 2017 by jwrl.
// Corrects for a problem with the way that Lightworks handles interlaced media.
//
// Modified 11 February 2017 by jwrl.
// Added subcategory to effect header for version 14.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flare";
   string Category    = "Stylize";
   string SubCategory = "Filters";
   string Notes       = "Creates an adjustable lens flare effect";
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

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp, InputSampler);
DefineTarget (Sample, Samp1);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CentreX
<
   string Description = "Origin";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CentreY
<
   string Description = "Origin";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Stretch
<
   string Description = "Stretch";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 5.0;

float adjust
<
   string Description = "Adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_adjust (float2 uv : TEXCOORD2) : COLOR
{
   float4 Color = GetPixel (InputSampler, uv);

   if (Color.r < 1.0 - adjust) Color.r = 0.0;
   if (Color.g < 1.0 - adjust) Color.g = 0.0;
   if (Color.b < 1.0 - adjust) Color.b = 0.0;

   return Color;
}

float4 ps_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 source = GetPixel (InputSampler, uv);
   float4 negative = tex2D (Samp1, uv);

   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 amount = float2 (1.0, _OutputAspectRatio) * Stretch / _OutputWidth;
   float2 adj = amount;
   float2 xy = uv - centre;

   float scale = 0.0;
   
   float4 ret = tex2D (Samp1, (xy * adj) + centre);

   for (int count = 1; count < 13; count++) {
      scale += Strength;
      adj += amount;
      ret += tex2D (Samp1, (xy * adj) + centre) * scale;
   }

   ret /= 15.0;
   ret.a = 0.0;

   return saturate (ret + source);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Blur
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = Sample;"; > ExecuteShader (ps_adjust)
   pass P_2 ExecuteShader (ps_main)
}

