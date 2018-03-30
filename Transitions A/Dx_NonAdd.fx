//--------------------------------------------------------------//
// Lightworks user effect Dx_NonAdd.fx
//
// Created by LW user jwrl 3 January 2017
//
// This effect emulates the classic analog vision mixer
// non-additive mix.
//
// Update August 10 2017 by jwrl - renamed from NonAddMix.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-additive mix";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
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
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 fgPix  = tex2D (FgSampler, xy1);
   float4 bgPix  = tex2D (BgSampler, xy2);
   float4 retval = (max (fgPix, bgPix) + (fgPix + bgPix) / 2.0) / 2.0;

   return (Amount <= 0.5) ? lerp (fgPix, retval, Amount * 2.0) : lerp (retval, bgPix, (Amount * 2.0) - 1.0);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique NonAdd
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

