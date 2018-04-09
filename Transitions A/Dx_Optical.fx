// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2016-07-30
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalDx_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalDissolve.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Optical.fx
//
// This is an attempt to simulate the look of the classic film optical dissolve.  To do
// this it applies a non-linear curve to the transition, and at the centre mixes in a
// stretched blend with a touch of black crush.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Explicitly defined float4 variable to address the differing behaviours of the D3D
// and Cg compilers.
//
// Update August 10 2017 by jwrl.
// Renamed from OpticalDx.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Optical dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI 3.141593

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float cAmount = sin (Amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (Amount * PI)) / 2.0;

   float4 fgPix = tex2D (FgSampler, xy1);
   float4 bgPix = tex2D (BgSampler, xy2);
   float4 retval = lerp (min (fgPix, bgPix), bgPix, Amount);

   fgPix = lerp (fgPix, min (fgPix, bgPix), Amount);
   retval = lerp (fgPix, retval, aAmount);

   cAmount += 1.0;

   return saturate ((retval * cAmount) - bAmount.xxxx);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Optical
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
