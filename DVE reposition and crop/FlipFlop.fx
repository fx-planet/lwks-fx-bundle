//--------------------------------------------------------------//
// FlipFlop.fx
//
// Written by jwrl - I wanted to emulate a similar effect in
// other NLEs.  The uncanny resemblance to Editshare's flip
// and flop routines is caused by the very limited number of
// ways that this can be done.  I can't think of any other
// technique as simple!
//
// This requires roughly half the GPU processing needed by
// combining the functionality of the flip and flop effects.
//
// Cross platform compatibility check 31 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
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

sampler InputSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   return tex2D (InputSampler, float2 (1.0 - xy.x, 1.0 - xy.y));
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique FlipFlop
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
