// @Maintainer jwrl
// @Released 2021-10-28
// @Author jwrl
// @Created 2021-10-28
// @see https://www.lwks.com/media/kunena/attachments/6375/FrameLock_640.png

/**
 Frame lock locks the frame size and aspect ratio of the image to that of the sequence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FrameLock.fx
//
// Version history:
//
// This version built 2021-10-28 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup    = "GenericPixelShader";
   string Description    = "Frame lock";
   string Category       = "User";
   string SubCategory    = "Technical";
   string Notes          = "This effect locks the frame size and aspect ratio of the image";
   bool CanSize          = false;
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
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

// No parameters required.

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_Input, uv); }

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique FrameLock
{
   pass P_1 ExecuteShader (ps_main)
}

