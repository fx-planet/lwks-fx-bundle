// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Dx_Optical.fx
//
// Written by LW user jwrl 30 July 2016
// @Author jwrl
// @CreationDate "30 July 2016"
//
// This is an attempt to simulate the look of the classic film
// optical dissolve.  To do this it applies a non-linear curve
// to the transition, and at the centre mixes in a stretched
// blend with a touch of black crush.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Explicitly defined float4 variable to address the differing
// behaviours of the D3D and Cg compilers.
//
// Update August 10 2017 by jwrl - renamed from OpticalDx.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Optical dissolve";
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
// Definitions and declarations
//--------------------------------------------------------------//

#define PI 3.141593

//--------------------------------------------------------------//
// Pixel Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float cAmount = sin (Amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (Amount * PI)) / 2.0;

   float4 fgPix = tex2D (FgSampler, xy1);
   float4 bgPix = tex2D (BgSampler, xy2);
   float4 retval = lerp (min (fgPix, bgPix), bgPix, Amount);

   fgPix = lerp (fgPix, min (fgPix, bgPix), Amount);
   retval = lerp (fgPix, retval, aAmount);

   cAmount += 1.0;

   return saturate ((retval * cAmount) - bAmount.xxxx);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique Optical
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

