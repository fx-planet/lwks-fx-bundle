// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2017-01-03
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Non_Add_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/NonAddMix.mp4

/**
 This effect emulates the classic analog vision mixer non-add mix.  It uses an algorithm
 that mimics reasonably closely what the electronics used to do.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAdd_Dx.fx
//
// Version history:
//
// Modified 2020-07-29 jwrl.
// Reformatted the effect header.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes".
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-additive mix";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Emulates the classic analog vision mixer non-add mix";
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

#define EMPTY 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = lerp (tex2D (s_Foreground, xy1), EMPTY, Amount);
   float4 Bgd = lerp (EMPTY, tex2D (s_Background, xy2), Amount);
   float4 Mix = max (Bgd, Fgd);

   float Gain = (1.0 - abs (Amount - 0.5)) * 2.0;

   return saturate (Mix * Gain);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Dx_NonAdd
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
