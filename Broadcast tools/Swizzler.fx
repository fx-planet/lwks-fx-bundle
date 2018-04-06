// @Maintainer jwrl
// @Released 2018-04-06
// @Author jwrl
// @Created 2017-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/Swizzler_1.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Swizzler.fx
//
// This "swizzles" the RGB channels to correct for bad channel assignments
//
// Modified 6 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour swizzler";
   string Category    = "Colour";
   string SubCategory = "User effects";
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

technique Swizzler_0
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

technique Swizzler_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_RGB_BRG (); }
}

technique Swizzler_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_RGB_GBR (); }
}

technique Swizzler_3
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_swap_RB (); }
}

technique Swizzler_4
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_swap_GB (); }
}

technique Swizzler_5
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_swap_RG (); }
}
