// @Maintainer jwrl
// @Released 2021-10-06
// @Author baopao
// @Created 2013-06-07
// @see https://www.lwks.com/media/kunena/attachments/6375/Ale_ChromaKey_640.png

/**
 This sophisticated chromakey has the same range of adjustments that you would expect to
 find on expensive commercial tools.  It's particularly effective on fine detail.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AleChromakey.fx
//
// Created by baopao (http://www.alessandrodallafontana.com).
//
// Version history:
//
// Update 2021-10-06 jwrl.
// Updated the original effect to support LW 2021 resolution independence.
//
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
//
// Modified 23 Dec 2018 by user jwrl:
// Added creation date.
// Reformatted the effect description for markup purposes.
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras", effect name and file name
// changed minimally .
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Version 14 update 18 Feb 2017 jwrl.
// Changed category from "Keying" to "Key", added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "ALE ChromaKey";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "A sophisticated chromakey that is particularly effective on fine detail";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (fg, FgSampler);
DefineInput (bg, BgSampler);
DefineInput (despill, BgBlurSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "ChromaKey";
   string Enum = "Green,Blue";
> = 0;

float RedAmount
<
   string Description = "RedAmount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float FgVal
<
   string Description = "FgVal";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.45;

float BgVal
<
   string Description = "BgVal";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float GammaFG
<
   string Description = "GammaFG";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 2.0;

float GammaBG
<
   string Description = "GammaBG";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 0.4;

float GammaMix
<
   string Description = "GammaMix";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 2.0;

float4 ColorReplace
<
   string Description = "ColorReplace";
> = { 0.5, 0.5, 0.5, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Green (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR 
{
   float4 color = GetPixel (FgSampler, uv1);                         // Color FG
   float4 colorBG = Overflow (uv2) ? BLACK : tex2D (BgSampler, uv2); // Color BG
   float4 colorBGblur = GetPixel (BgBlurSampler, uv3);               // BG Blur imput

   float MixRB  = saturate (color.g - lerp (color.r, color.b, RedAmount));
   float KeyG   = color.g - MixRB;
   float MaskFG = saturate (1.0 - MixRB * FgVal / KeyG);
   float MaskBG = saturate (MixRB / BgVal);

   MaskFG = pow (MaskFG, 1.0 / GammaFG);
   MaskBG = pow (MaskBG, 1.0 / GammaBG);

   float OverMask = 1.0 - MaskFG - MaskBG;

   color.g = KeyG;
   color   = lerp (color, ColorReplace + colorBGblur, MixRB);
   color  *= MaskFG;
   color  += colorBG * MaskBG;

   return lerp (color, pow (color, 1.0 / GammaMix), OverMask);
}

float4 Blue (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR 
{
   float4 color = GetPixel (FgSampler, uv1);
   float4 colorBG = Overflow (uv2) ? BLACK : tex2D (BgSampler, uv2);
   float4 colorBGblur = GetPixel (BgBlurSampler, uv3);

   float MixRB = saturate (color.b - lerp (color.r, color.g, RedAmount));
   float KeyG = color.b - MixRB;
   float MaskFG = saturate (1.0 - MixRB / KeyG / FgVal);
   float MaskBG = saturate (MixRB / BgVal);

   MaskFG = pow (MaskFG, 1.0 / GammaFG);
   MaskBG = pow (MaskBG, 1.0 / GammaBG);

   float OverMask = 1.0 - MaskFG - MaskBG;

   color.b = KeyG;
   color   = lerp (color, ColorReplace + colorBGblur, MixRB);
   color  *= MaskFG;
   color  += colorBG * MaskBG;

   return lerp (color, pow (color, 1.0 / GammaMix), OverMask);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Green2 { pass P_1 ExecuteShader (Green) }

technique Blue2 { pass P_1 ExecuteShader (Blue) }

