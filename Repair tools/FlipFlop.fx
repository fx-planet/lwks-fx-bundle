// @Maintainer jwrl
// @Released 2018-12-26
// @Author jwrl
// @Created 2018-03-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Flip_Flop_640.png

/**
This emulates a similar effect in other NLEs.  The resemblance to Editshare's flip and
flop routines is low , because the maths operations to achieve the result have been
halved.  It uses the same GPU resources needed by either a flip or flop effect alone.
That means that using this instead of two effects actually requires less than half the
GPU processing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlipFlop.fx
//
// This is a complete rewrite of this effect.  The original version has been withdrawn.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 29 August 2018 jwrl.
// Added notes to header.
//
// Modified 2018-12-05 jwrl.
// Changed subcategory.
//
// Modified 26 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flip flop";
   string Category    = "DVE";
   string SubCategory = "Repair tools";
   string Notes       = "A combined flip and flop effect.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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
