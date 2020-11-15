// @Maintainer jwrl
// @Released 2020-11-15
// @Author jwrl
// @Created 2017-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/Swizzler_640.png

/**
 This "swizzles" the RGB channels to correct for bad channel assignments.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSwizzler.fx
//
// Version history:
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified by LW user jwrl 6 December 2018.
// Changed category and subcategory.
//
// Modified by LW user jwrl 26 September 2018.
// Added notes to header.
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
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
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   return tex2D (FgdSampler, uv);
}

float4 ps_main_RGB_BRG (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (FgdSampler, uv).brga;
}

float4 ps_main_RGB_GBR (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (FgdSampler, uv).gbra;
}

float4 ps_main_swap_RB (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (FgdSampler, uv).bgra;
}

float4 ps_main_swap_GB (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (FgdSampler, uv).rbga;
}

float4 ps_main_swap_RG (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (FgdSampler, uv).grba;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourSwizzler_0
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

technique ColourSwizzler_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_RGB_BRG (); }
}

technique ColourSwizzler_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_RGB_GBR (); }
}

technique ColourSwizzler_3
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_swap_RB (); }
}

technique ColourSwizzler_4
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_swap_GB (); }
}

technique ColourSwizzler_5
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_swap_RG (); }
}
