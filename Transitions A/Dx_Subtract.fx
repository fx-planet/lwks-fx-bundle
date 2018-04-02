// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Dx_Subtract.fx
//
// Written by LW user jwrl 11 May 2017.
// @Author: jwrl
// @CreationDate: "11 May 2017"
//
// This is an inverted non-additive mix.  The incoming video is
// faded from white to normal value at the 50% point, at which
// stage the outgoing video starts to fade to white.  The two
// images are then mixed by giving the source with the lowest
// level the priority.  The result is a subtractive effect.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Swizzled two float variables to float4.  This addresses the
// the behavioural differences between D3D and Cg compilers.
//
// Update August 10 2017 by jwrl - renamed from SubtractDx.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Subtractive dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fgd;
texture Bgd;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Pixel Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float outAmount = 1.0 - min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = 1.0 - min (1.0, Amount * 2.0);

   float4 Fgnd = max (tex2D (FgdSampler, uv), outAmount.xxxx);
   float4 Bgnd = max (tex2D (BgdSampler, uv), in_Amount.xxxx);

   return min (Fgnd, Bgnd);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique subtractiveDx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

