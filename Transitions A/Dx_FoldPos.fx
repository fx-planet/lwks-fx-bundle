// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2018-03-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FoldPos_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_FoldPos.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_FoldPos.fx
//
// This transitions by adding one input to the other.  The overflowed result is then
// folded back into the legal video range.
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define WHITE 1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (FgSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);

   float4 retval = 1.0.xxxx - abs (1.0.xxxx - Fgd - Bgd);

   float amt1 = min (Amount * 2.0, 1.0);
   float amt2 = max ((Amount * 2.0 - 1.0), 0.0);

   retval = lerp (Fgd, retval, amt1);

   return lerp (retval, Bgd, amt2);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Addulate
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
