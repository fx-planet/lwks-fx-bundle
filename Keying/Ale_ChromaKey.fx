// @Maintainer jwrl
// @Released 2018-04-07
// @Author baopao
// @see https://www.lwks.com/media/kunena/attachments/6375/baopaoCkey1.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect ALE_ChromaKey.fx
//
// Created by baopao (http://www.alessandrodallafontana.com), this sophisticated chroma
// key has the same range of adjustments that you would expect to find on expensive
// commercial tools.  It's particularly effective on fine detail.
//
// Version 14 update 18 Feb 2017 jwrl.
// Changed category from "Keying" to "Key", added subcategory to effect header.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Ale_ChromaKey";
   string Category    = "Key";
   string SubCategory = "User Effects";
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

#pragma warning ( disable : 3571 )

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

