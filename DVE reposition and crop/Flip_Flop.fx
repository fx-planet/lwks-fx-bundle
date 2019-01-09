// @Maintainer jwrl
// @Released 2018-12-05
// @Author jwrl
// @Created 2018-03-14
// @see https://www.lwks.com/media/kunena/attachments/6375/Flip_Flop_640.png
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
//
// Modified 29 August 2018 jwrl.
// Added notes to header.
//
// Modified 13 November 2018 jwrl.
// Edited header notes, changed "Input" to "Inp" to improve routing display.
//
// Modified 2018-12-05 jwrl.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flip flop";
   string Category    = "DVE";
   string SubCategory = "Repair tools";
   string Notes       = "A reference combined flip and flop effect.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (s_Input, 1.0.xx - uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Flip_Flop
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}
