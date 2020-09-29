// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2018-09-01
// @see https://www.lwks.com/media/kunena/attachments/6375/Plasma_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Plasma.mp4

/**
 This effect generates soft plasma-like cloud patterns.  Hue, level, saturation, and rate
 of change of the pattern are all adjustable, and the pattern is also adjustable.

 NOTE: This will not run or compile under Windows version of Lightworks v. 14.0 or earlier
 and will instead produce an error message if that is attempted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PlasmaMatte.fx
//
// Version history:
//
// Modified jwrl 2020-09-29:
// Reformatted the effect header.
//
// Modified 3 August 2019 jwrl.
// Corrected matte generation so that it remains stable without an input.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Plasma matte";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "Generates soft plasma clouds";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Matte : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture = <Inp>; };
sampler s_Matte = sampler_state { Texture = <Matte>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Rate
<
   string Description = "Rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Style
<
   string Description = "Pattern style";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Scale
<
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Gain
<
   string Description = "Pattern gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Level
<
   string Description = "Level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6666666667;

float Hue
<
   string Description = "Hue";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define R_LUMA  0.2989
#define G_LUMA  0.5866
#define B_LUMA  0.1145

#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

float _Progress;

#ifdef _LENGTHFRAMES

float _LengthFrames;

#endif

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_matte (float2 uv : TEXCOORD) : COLOR
{
   float rate = _LengthFrames * _Progress / (1.0 + (Rate * 38.0));

   float2 xy1, xy2, xy3, xy4 = (uv - 0.5.xx) * HALF_PI;

   sincos (xy4, xy3, xy2.yx);

   xy1  = lerp (xy3, xy2, (1.0 + Style) * 0.5) * (5.5 - (Scale * 5.0));
   xy1 += sin (xy1 * HALF_PI + rate.xx).yx;
   xy4  = xy1 * HALF_PI;

   sincos (xy1.x, xy3.x, xy3.y);
   sincos (xy4.x, xy2.x, xy2.y);
   sincos (xy1.y, xy1.x, xy1.y);
   sincos (xy4.y, xy4.x, xy4.y);

   float3 ptrn = (dot (xy2, xy4.xx) + dot (xy1, xy3.yy)).xxx;

   ptrn.y = dot (xy1, xy2.xx) + dot (xy3, xy4.xx);
   ptrn.z = dot (xy2, xy3.yy) + dot (xy1, xy4.yy);
   ptrn  += float3 (Hue, 0.5, 1.0 - Hue) * TWO_PI;

   float3 retval = sin (ptrn) * ((Gain * 0.5) + 0.05);

   retval = saturate (retval + Level.xxx);

   float luma = dot (retval, float3 (R_LUMA, G_LUMA, B_LUMA));

   retval = lerp (luma.xxx, retval, Saturation * 2.0);

   return float4 (retval, 1.0);
}

float4 ps_main (float2 uv : TEXCOORD, float2 xy : TEXCOORD1) : COLOR
{
   return lerp (tex2D (s_Input, xy), tex2D (s_Matte, uv), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique PlasmaMatte
{
   pass P_1
   < string Script = "RenderColorTarget0 = Matte;"; >
   { PixelShader = compile PROFILE ps_matte (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
