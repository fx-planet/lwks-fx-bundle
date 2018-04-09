// @Maintainer jwrl
// @Released 2018-04-09
// @Author jwrl
// @Created 2017-05-11
// @see https://www.lwks.com/media/kunena/attachments/6375/NonAddUltra_1.png
// @see https://www.lwks.com/media/kunena/attachments/6375/NonAddUltraDx.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_NonAddUltra.fx
//
// This is an extreme non-additive mix.  The incoming video is faded in to full value at
// the 50% point, at which stage the outgoing video starts to fade out.  The two images
// are mixed by giving the source with the maximum level priority.
//
// The result is extreme, but can be interesting.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Update August 10 2017 by jwrl.
// Renamed from NonAddUltraDx.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-add dissolve ultra";
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
// Params
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Linearity
<
   string Description = "Linearity";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float outAmount = min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = min (1.0, Amount * 2.0);
   float temp = outAmount * outAmount * outAmount;

   outAmount = lerp (outAmount, temp, Linearity);
   temp = in_Amount * in_Amount * in_Amount;
   in_Amount = lerp (in_Amount, temp, Linearity);

   float4 Fgnd = tex2D (FgdSampler, uv) * outAmount;
   float4 Bgnd = tex2D (BgdSampler, uv) * in_Amount;

   return max (Fgnd, Bgnd);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique ultraNonAdd
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
