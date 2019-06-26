// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2017-05-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Subtract_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SubtractiveDx.mp4

/**
This is an inverted non-additive mix.  The incoming video is faded from white to normal
value at the 50% point, at which stage the outgoing video starts to fade to white.  The
two images are then mixed by giving the source with the lowest level the priority.  The
result is a subtractive effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Subtract_Dx.fx
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Swizzled two float variables to float4 to address the behavioural differences
// between D3D and Cg compilers.
//
// Update August 10 2017 by jwrl.
// Renamed from SubtractDx.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
// Changed "Fgd" input to "Fg" and "Bgd" input to "Bg".
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Subtractive dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "An inverted non-additive mix";
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

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float outAmount = 1.0 - min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = 1.0 - min (1.0, Amount * 2.0);

   float4 Fgnd = max (tex2D (s_Foreground, uv), outAmount.xxxx);
   float4 Bgnd = max (tex2D (s_Background, uv), in_Amount.xxxx);

   return min (Fgnd, Bgnd);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Subtract_Dx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
