// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2018-03-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FoldNeg_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_FoldNeg.mp4

/**
 This dissolves through a negative mix of the two inputs.  The result is a sort of ghostly
 double transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FoldNeg_Dx.fx
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
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Folded neg dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Dissolves through a negative mix of one image to another";
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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 Neg = float4 (1.0.xxx - ((Fgd.rgb + Bgd.rgb) / 2.0), max (Fgd.a, Bgd.a));
   float4 Mix = lerp (Fgd, Neg, Amount);

   return lerp (Mix, Bgd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FoldNeg_Dx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
