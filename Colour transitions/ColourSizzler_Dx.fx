// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2017-05-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Sizzler_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SizzlerDx.mp4

/**
This effect dissolves through a complex colour translation while performing what is
essentially a non-additive mix.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSizzler_Dx.fx
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Update August 10 2017 by jwrl.
// Renamed from SizzlerDx.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
// Changed "Fgd" input to "Fg" and "Bgd" input to "Bg".
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour sizzler";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Dissolves through a complex colour translation from one clip to another";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture =   <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SQRT_3  1.7320508
#define TWO_PI  6.2831853

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = tex2D (s_Foreground, uv);
   float4 Bgnd   = tex2D (s_Background, uv);
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

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_ColourSizzler
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
