// @Maintainer jwrl
// @Released 2021-10-28
// @Author jwrl
// @Created 2021-10-28
// @see https://www.lwks.com/media/kunena/attachments/6375/Swizzler_640.png

/**
 This "swizzles" the RGB channels to correct for bad channel assignments.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSwizzler.fx
//
// Version history:
//
// Rewrite 2021-10-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour swizzler";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "This 'swizzles' the RGB channels to correct for bad channel assignments";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Swizzle channels";
   string Enum = "Pass through,RGB > BRG,RGB > GBR,Swap R/B,Swap G/B,Swap R/G"; 
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, uv);
}

float4 ps_main_RGB_BRG (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, uv).brga;
}

float4 ps_main_RGB_GBR (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, uv).gbra;
}

float4 ps_main_swap_RB (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, uv).bgra;
}

float4 ps_main_swap_GB (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, uv).rbga;
}

float4 ps_main_swap_RG (float2 uv : TEXCOORD1) : COLOR
{
   return GetPixel (s_Input, uv).grba;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourSwizzler_0 { pass P_1 ExecuteShader (ps_main) }
technique ColourSwizzler_1 { pass P_1 ExecuteShader (ps_main_RGB_BRG) }
technique ColourSwizzler_2 { pass P_1 ExecuteShader (ps_main_RGB_GBR) }
technique ColourSwizzler_3 { pass P_1 ExecuteShader (ps_main_swap_RB) }
technique ColourSwizzler_4 { pass P_1 ExecuteShader (ps_main_swap_GB) }
technique ColourSwizzler_5 { pass P_1 ExecuteShader (ps_main_swap_RG) }

