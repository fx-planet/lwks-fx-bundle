// @Maintainer jwrl
// @Released 2018-04-07
// @Author jwrl
// @Created 2018-03-14
// @see https://www.lwks.com/media/kunena/attachments/6375/FlipFlop.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Flip_Flop.fx
//
// This emulates a similar effect in other NLEs, and an earlier LW user effect.  The
// resemblance to Editshare's flip and flop routines is now reduced, because the maths
// operations to achieve the result have been halved.  It uses the same GPU resources
// needed by either a flip or flop effect alone.  That means that using this instead
// of two effects actually requires less than half the GPU processing.
//
// This is a complete rewrite of this effect.  The original version has been withdrawn.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flip/flop";
   string Category    = "DVE";
   string SubCategory = "User Effects";
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

technique Flip_Flop
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}
