// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2016-07-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Optical_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalDissolve.mp4

/**
 This is an attempt to simulate the look of the classic film optical dissolve.  To do this
 it applies a non-linear curve to the transition, and at the centre mixes in a stretched
 blend with a touch of black crush.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Optical_Dx.fx
//
// Version history:
//
// Modified 2020-07-29 jwrl.
// Reformatted the effect header.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Update August 10 2017 by jwrl.
// Renamed from OpticalDx.fx for consistency across the dissolve range.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Explicitly defined float4 variable to address the differing behaviours of the D3D
// and Cg compilers.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Optical dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Simulates the burn effect of a film optical dissolve";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

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

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float cAmount = sin (Amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (Amount * PI)) / 2.0;

   float4 fgPix = tex2D (s_Foreground, xy1);
   float4 bgPix = tex2D (s_Background, xy2);
   float4 retval = lerp (min (fgPix, bgPix), bgPix, Amount);

   fgPix = lerp (fgPix, min (fgPix, bgPix), Amount);
   retval = lerp (fgPix, retval, aAmount);

   cAmount += 1.0;

   return saturate ((retval * cAmount) - bAmount.xxxx);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Optical_Dx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
