// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Flip_Flop.fx
// Rewritten by LW user jwrl 14 March 2018
// @Author jwrl
// @Created "14 March 2018"
//
// This is a complete rewrite of this effect. It emulates a
// similar effect in other NLEs.  The uncanny resemblance to
// Editshare's flip and flop routines is now reduced, because
// I've halved the maths operations to achieve the result.
//
// This exerts the same amount of GPU processing needed by
// either a flip or flop effect alone.  It means that using
// this instead of two effects actually requires less than
// half the processing.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Flip/flop";
   string Category    = "DVE";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state { Texture = <Input>; };

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (InputSampler, (1.0).xx - uv);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Flip_Flop
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}
