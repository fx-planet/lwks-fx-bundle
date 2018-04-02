// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Dx_Sizzler.fx
//
// Created by LW jwrl 12 May 2017.
// @Author: jwrl
// @CreationDate: "12 May 2017"
//
// This effect dissolves through a complex colour translation
// while performing what is essentially a non-additive mix.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Update August 10 2017 by jwrl - renamed from SizzlerDx.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour sizzler";
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
   Texture =   <Fgd>;
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

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float HueCycle
<
   string Description = "Cycle rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define SQRT_3  1.7320508
#define TWO_PI  6.2831853

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (FgdSampler, uv);
   float4 Bgnd   = tex2D (BgdSampler, uv);
   float4 nonAdd = max (Fgnd * min (1.0, 2.0 * (1.0 - Amount)), Bgnd * min (1.0, 2.0 * Amount));
   float4 premix = max (Fgnd, Bgnd);

   float Alpha = premix.w;
   float Luma  = 0.1 + (0.5 * premix.x);
   float Satn  = premix.y * Saturation;
   float Hue   = frac (premix.z + (Amount * HueCycle));
   float LumX3 = 3.0 * Luma;

   float HueX3 = 3.0 * Hue;
   float Hfac  = (floor (HueX3) + 0.5) / 3.0;

   Hue = SQRT_3 * tan ((Hue - Hfac) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   float4 retval = (HueX3 < 1.0) ? float4 (Green, Blue, Red, Alpha)
                 : (HueX3 < 2.0) ? float4 (Red, Green, Blue, Alpha)
                                 : float4 (Blue, Red, Green, Alpha);

   float mixval = abs (2.0 * (0.5 - Amount));

   mixval *= mixval;

   return lerp (retval, nonAdd, mixval);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique SizzlerDx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

