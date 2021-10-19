// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
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
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, 1.0.xx - uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FlipFlop { pass P_1 ExecuteShader (ps_main) }

