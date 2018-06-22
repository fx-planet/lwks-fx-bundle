// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Non_Add_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Non_Add.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ax_Non_Add.fx
//
// This effect emulates the classic analog vision mixer non-add mix.  It uses an
// algorithm that mimics reasonably closely what the electronics used to do.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha non-additive mix";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
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

technique Ax_Non_Add
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
