// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2017-05-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Subtract_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SubtractiveDx.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Subtract.fx
//
// This is an inverted non-additive mix.  The incoming video is faded from white to
// normal value at the 50% point, at which stage the outgoing video starts to fade
// to white.  The two images are then mixed by giving the source with the lowest
// level the priority.  The result is a subtractive effect.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Swizzled two float variables to float4 to address the behavioural differences
// between D3D and Cg compilers.
//
// Update August 10 2017 by jwrl.
// Renamed from SubtractDx.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Subtractive dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;
texture Bgd;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Fgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bgd>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float outAmount = 1.0 - min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = 1.0 - min (1.0, Amount * 2.0);

   float4 Fgnd = max (tex2D (FgdSampler, uv), outAmount.xxxx);
   float4 Bgnd = max (tex2D (BgdSampler, uv), in_Amount.xxxx);

   return min (Fgnd, Bgnd);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique subtractiveDx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
