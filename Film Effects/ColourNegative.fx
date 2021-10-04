// @Maintainer jwrl
// @Released 2021-10-01
// @Author jwrl
// @Created 2021-10-01
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmNeg_640.png

/**
 This simulates the look of 35 mm masked film negative.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourNegative.fx
//
// Version history:
//
// Rewrite 2021-10-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour negative";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Simulates the look of 35 mm colour film dye-masked negative";
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

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, FgSampler);

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (FgSampler, uv);

   retval.rgb  = (float3 (2.0, 1.33, 1.0) - retval.rgb) / 2.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourNegative
{
   pass P_1 ExecuteShader (ps_main)
}

