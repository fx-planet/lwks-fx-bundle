// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-06-12
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Scurve-640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Scurve.mp4

/**
 This is essentially the same as the S dissolve but extended to support alpha channels.
 A trigonometric curve is applied to the "Amount" parameter and the linearity of the
 curve can be adjusted.  Alpha levels are boosted to support Lightworks titles, which
 is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sdissolve_Ax.fx
//
// This is a revision of an earlier effect, Adx_Scurve.fx, which also had the ability to
// dissolve between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified 23 July 2020 by user jwrl:
// Changed "Transition" to "Transition position".
// Changed Boost dialogue.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "S dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Dissolves the title with a non-linear profile";
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

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

float Linearity
<
   string Description = "Linearity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.1415926536

#define HALF_PI 1.5707963268

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

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   amount = saturate (amount + (curve * Linearity));

   float4 Fgnd = fn_tex2D (s_Super, uv);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   amount = 1.0 - saturate (amount + (curve * Linearity));

   float4 Fgnd = fn_tex2D (s_Super, uv);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sdissolve_Ax_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Sdissolve_Ax_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}
