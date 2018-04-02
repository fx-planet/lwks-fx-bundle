//--------------------------------------------------------------//
// Lightworks user effect alphaAdjust.fx
//
// Created by LW user jwrl 1 March 2016.
// @Author: jwrl
// @CreationDate: "1 March 2016"
//
// This Lightworks effect is designed principally for alpha
// channel gamma correction.  It will adjust other settings as
// well, but it's optimised for gamma adjustment.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha adjust";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Inp;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture = <Inp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

bool showAlpha
<
   string Description = "Show alpha channel";
> = false;

float alphaGamma
<
   string Description = "Alpha gamma";
   float MinVal = 0.10;
   float MaxVal = 4.00;
> = 1.00;

float alphaContrast
<
   string Description = "Alpha contrast";
   float MinVal = 0.00;
   float MaxVal = 5.00;
> = 1.0;

float alphaBrightness
<
   string Description = "Alpha brightness";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.0;

float alphaGain
<
   string Description = "Alpha gain";
   float MinVal = 0.00;
   float MaxVal = 4.00;
> = 1.0;

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   retval.a = saturate (((((pow (retval.a, 1 / alphaGamma) * alphaGain) + alphaBrightness) - 0.5) * alphaContrast) + 0.5);

   if (!showAlpha) return retval;

   return retval.aaaa;
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique Adjustment
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
