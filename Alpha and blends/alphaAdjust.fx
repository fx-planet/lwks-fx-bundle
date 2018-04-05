// @Maintainer jwrl
// @Released 2018-04-05
// @Author jwrl
// @Created 2013-03-01
// @see https://www.lwks.com/media/kunena/attachments/6375/alphaAdjust.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect alphaAdjust.fx
//
// This Lightworks effect is designed principally for alpha channel gamma correction.
// It will adjust other settings as well, but it's optimised for gamma adjustment.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha adjust";
   string Category    = "Key";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture = <Inp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   retval.a = saturate (((((pow (retval.a, 1 / alphaGamma) * alphaGain) + alphaBrightness) - 0.5) * alphaContrast) + 0.5);

   if (showAlpha) return retval.aaaa;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Adjustment
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
