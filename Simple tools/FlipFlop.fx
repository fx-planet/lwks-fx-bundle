// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2018-03-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Flip_Flop_640.png

/**
 This emulates a similar effect in other NLEs.  The resemblance to Lightworks' flip and
 flop routines is obvious.  However because the maths operations to achieve the result
 have been halved it uses roughly the same GPU resources needed by either a flip or flop
 effect alone.  That means that using this instead of those two effects requires about
 half the processing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlipFlop.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 4 January 2020 by user jwrl:
// Renamed subcategory to "Simple tools", changed notes to be more explicit.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 2018-12-05 jwrl.
// Changed subcategory.
//
// Modified 29 August 2018 jwrl.
// Added notes to header.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flip flop";
   string Category    = "DVE";
   string SubCategory = "Simple tools";
   string Notes       = "Rotates video by 180 degrees.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler InputSampler = sampler_state { Texture = <Input>; };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (InputSampler, (1.0).xx - uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FlipFlop
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}
