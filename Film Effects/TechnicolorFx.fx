// @Maintainer jwrl
// @Released 2021-10-02
// @Author khaver
// @Created 2011-04-20
// @see https://www.lwks.com/media/kunena/attachments/6375/Technicolor_640.png

/**
 Simulates the look of the classic 2-strip and 3-strip Technicolor film processes.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TechnicolorFx.fx
//
// Version history:
//
// Update 2021-10-02 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Technicolor";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Simulates the look of the classic 2-strip and 3-strip Technicolor film processes";
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
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Emulation";
   string Enum = "Two_Strip,Three_Strip";
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 Techni2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 source = GetPixel (FgSampler, uv);
   float4 output;

   output.r = source.r;
   output.g = (source.g/2.0) + (source.b/2.0);
   output.b = (source.b/2.0) + (source.g/2.0);
   output.a = 0;

   return output;
}

float4 Techni3 (float2 uv : TEXCOORD1) : COLOR
{
   float4 source = GetPixel (FgSampler, uv);
   float4 output;

   output.r = source.r - (source.g/2.0) + (source.b/2.0);
   output.g = source.g - (source.r/2.0) + (source.b/2.0);
   output.b = source.b - (source.r/2.0) + (source.g/2.0);
   output.a = 0;

   return output;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Two_Strip
{
   pass SinglePass ExecuteShader (Techni2)
}

technique Three_Strip
{
   pass SinglePass ExecuteShader (Techni3)
}

