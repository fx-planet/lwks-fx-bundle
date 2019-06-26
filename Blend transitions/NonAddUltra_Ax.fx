// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_NonAddUltra_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_NonAddUltra.mp4

/**
This is an extreme non-additive mix for titles.  The incoming title is faded in to full
value at the 50% point, at which stage the background video starts to fade out.  The two
images are mixed by giving the source with the maximum level priority.

The result is extreme, but can be interesting.

Alpha levels are boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAddUltra_Ax.fx
//
// Modified 13 December 2018 jwrl.
// Changed name.
// Changed subcategory.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-add mix ultra (alpha)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "This is an extreme non-additive mix for titles";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Super = sampler_state { Texture = <Sup>; };
sampler s_Video = sampler_state { Texture = <Vid>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Ttype
<
   string Description = "Transition";
   string Enum = "Fade in,Fade out";
> = 0;

float Linearity
<
   string Description = "Linearity";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);

   float alpha     = Fgnd.a;
   float amount    = Ttype == 0 ? Amount : 1.0 - Amount;
   float outAmount = min (1.0, (1.0 - amount) * 2.0);
   float in_Amount = min (1.0, amount * 2.0);

   amount    = outAmount * outAmount * outAmount;
   outAmount = lerp (outAmount, amount, Linearity);
   amount    = in_Amount * in_Amount * in_Amount;
   in_Amount = lerp (in_Amount, amount, Linearity);

   Fgnd = max (Bgnd * outAmount, Fgnd * in_Amount);

   return lerp (Bgnd, Fgnd, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Ax_ultraNonAdd
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
