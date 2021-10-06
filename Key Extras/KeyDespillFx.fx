// @Maintainer jwrl
// @Released 2021-10-06
// @Author baopao
// @Released 2014-02-01
// @see https://www.lwks.com/media/kunena/attachments/6375/KeyDespill_640.png

/**
 Key despill is a background-based effect for removing the key colour spill in a chromakey
 composite.  It automatically separates the key from the background so that the defringing
 cannot pollute the background colour.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KeyDespillFx.fx
//
// Despill Background Based http://www.alessandrodallafontana.com/ (baopao)
//
// Version history:
//
// Update 2021-10-06 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
//
// Modified 23 December 2018 jwrl.
// Added creation date.
// Reformatted the effect description for markup purposes.
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras", effect name changed minimally.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Version 14 update 19 Feb 2017 jwrl.
// Changed category from "Keying" to "Key", added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Key despill";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "This is a background-based effect that removes key colour spill in a chromakey";
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
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define BdrPixel(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, FgSampler);
DefineInput (Bg, BgSampler);

DefineTarget (Key, s_Key);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Key";
   string Enum = "Green,Blue";
> = 0;

float RedAmount
<
   string Description = "Red amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_key_gen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (FgSampler, uv1);
   float4 Bgnd = BdrPixel (BgSampler, uv2);

   float cDiff = distance (Bgnd.rgb, Fgnd.rgb);

   Fgnd.a = smoothstep (0.0, 0.05, cDiff);

   return Fgnd;
}

float4 Green (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Back = BdrPixel (BgSampler, uv2);
   float4 color = tex2D (s_Key, uv3);

   float mask = saturate (color.g - lerp (color.r, color.b, RedAmount)) * color.a;

   color.g = color.g - mask;

   return color + (Back * mask);
}

float4 Blue (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Back = BdrPixel (BgSampler, uv2);
   float4 color = tex2D (s_Key, uv3);

   float mask = saturate (color.b - lerp (color.r, color.g, RedAmount)) * color.a;

   color.b = color.b - mask;

   return color + (Back * mask);
}

//-----------------------------------------------------------------------------------------//
//  Technique
//-----------------------------------------------------------------------------------------//

technique GreenDespill
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_key_gen)
   pass P_2 ExecuteShader (Green)
}

technique BlueDespill
{
   pass P_1 < string Script = "RenderColorTarget0 = Key;"; > ExecuteShader (ps_key_gen)
   pass P_2 ExecuteShader (Blue)
}

