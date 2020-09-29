// @Maintainer jwrl
// @Released 2020-09-29
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
// Update 2020-09-29 jwrl.
// Revised header block.
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
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture fg;
texture bg;
texture despill;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgBlurSampler = sampler_state
{
   Texture   = <despill>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   float MaxVal = 1.00;
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

float4 Green(float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR 
{
// Color FG
    float4 color = tex2D (FgSampler, xy1);
// Color BG
    float4 colorBG = tex2D (BgSampler, xy2);
// BG Blur imput
    float4 colorBGblur = tex2D (BgBlurSampler, xy3);

// MixRB
    float MixRB = saturate (color.g-lerp(color.r, color.b, RedAmount));

// KeyG
    float KeyG = color.g - MixRB;

// MaskFG
    float MaskFG = saturate (1.0 - MixRB * FgVal / KeyG);

    MaskFG = pow (MaskFG, 1.0 / GammaFG);

// MaskBG
    float MaskBG = saturate (MixRB / BgVal);

    MaskBG = pow (MaskBG, 1.0 / GammaBG);

    float OverMask = (1.0 - MaskFG) - MaskBG;

    color.g = KeyG;
    color = lerp (color, ColorReplace + colorBGblur, MixRB);

    color *= MaskFG;

    color += colorBG * MaskBG;

    return lerp (color, pow (color, 1.0 / GammaMix), OverMask);
}

float4 Blue(float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2, float2 xy3 : TEXCOORD3) : COLOR 
{
// Color FG
    float4 color = tex2D (FgSampler, xy1);
// Color BG
    float4 colorBG = tex2D (BgSampler, xy2);
// BG Blur imput
    float4 colorBGblur = tex2D (BgBlurSampler, xy3);

// MixRB
    float MixRB = clamp(color.b-lerp(color.r, color.g, RedAmount), 0, 1);

// KeyG
    float KeyG = color.b-MixRB;

// MaskFG
    float MaskFG = clamp(1-MixRB/KeyG/FgVal, 0, 1);

    MaskFG = pow(MaskFG, 1/GammaFG);

// MaskBG
    float MaskBG = clamp(MixRB/BgVal, 0, 1);

    MaskBG = pow(MaskBG, 1/GammaBG);

    float OverMask = (1-MaskFG)-MaskBG;

    color.b = KeyG;
    color = lerp(color, ColorReplace+colorBGblur, MixRB);

    color *= MaskFG;

    color += colorBG*MaskBG;

    return lerp(color, pow(color, 1/GammaMix), OverMask);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Green2
{
   pass Single_Pass
   {
      PixelShader = compile PROFILE Green();
   }
}

technique Blue2
{
   pass Single_Pass
   {
      PixelShader = compile PROFILE Blue();
   }
}
