// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Non_Add_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Non_Add.mp4

/**
 This effect emulates the classic analog vision mixer non-add mix.  It uses an
 algorithm that mimics reasonably closely what the electronics used to do.

 Alpha levels are boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAdd_Ax.fx
//
// Version history:
//
// Modified 23 July 2020 by user jwrl:
// Changed "Transition" to "Transition position".
// Changed Boost dialogue.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-additive mix (alpha)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Emulates the classic analog vision mixer non-add mix for titles";
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
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY 0.0.xxxx

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

   float amount = Ttype == 0 ? Amount : 1.0 - Amount;
   float Gain   = (1.0 - abs (amount - 0.5)) * 2.0;
   float alpha  = Fgnd.a;

   Fgnd = lerp (EMPTY, Fgnd, amount);
   Fgnd = max (lerp (Bgnd, EMPTY, amount), Fgnd);

   return lerp (Bgnd, Fgnd, alpha * Gain);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique NonAdd_Ax
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
