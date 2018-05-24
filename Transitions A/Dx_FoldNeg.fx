// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2018-03-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FoldNeg_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_FoldNeg.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_FoldNeg.fx
//
// This dissolves through a negative mix of the two inputs.  The result is a sort of
// ghostly double transition.
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
   string SubCategory = "Special FX";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state { Texture = <Fg>; };

sampler BgSampler = sampler_state { Texture = <Bg>; };

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
   float4 Fgd = tex2D (FgSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 Neg = float4 (1.0.xxx - ((Fgd.rgb + Bgd.rgb) / 2.0), max (Fgd.a, Bgd.a));
   float4 Mix = lerp (Fgd, Neg, Amount);

   return lerp (Mix, Bgd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Subtractify
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
