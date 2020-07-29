// @Maintainer jwrl
// @Released 2020-07-29
// @Author jwrl
// @Created 2018-03-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FoldPos_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_FoldPos.mp4

/**
 This transitions between the two inputs by adding one to the other.  The overflowed result
 is then folded back into the legal video range.  Anything above white or below black becomes
 inverted in the process.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FoldPos_Dx.fx
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
   string Description = "Folded pos dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Dissolves through a positive mix of one image to another";
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

#define WHITE 1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float4 retval = 1.0.xxxx - abs (1.0.xxxx - Fgd - Bgd);

   float amt1 = min (Amount * 2.0, 1.0);
   float amt2 = max ((Amount * 2.0 - 1.0), 0.0);

   retval = lerp (Fgd, retval, amt1);

   return lerp (retval, Bgd, amt2);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FoldPos_Dx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
