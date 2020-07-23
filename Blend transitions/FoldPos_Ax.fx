// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldPos_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldPos.mp4

/**
 This effect transitions by adding the title to the background.  The overflowed result is
 then folded back into the legal video range.

 Alpha levels are boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FoldPos_Ax.fx
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
   string Description = "Folded pos dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Dissolves through a positive mix of the title with the background";
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

#define WHITE (1.0).xxxx

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
   float amount = (Ttype == 0 ? 1.0 - Amount : Amount) * 2.0;

   float4 Ttle = fn_tex2D (s_Super, uv);
   float4 Bgnd = tex2D (s_Video, uv);
   float4 Fgnd = lerp (Bgnd, Ttle, Ttle.a);
   float4 retval = WHITE - abs (WHITE - Fgnd - Bgnd);

   float amt1 = min (amount, 1.0);
   float amt2 = max ((amount - 1.0), 0.0);

   retval = lerp (Fgnd, retval, amt1);
   Ttle.a = Ttle.a > 0.0 ? lerp (1.0, Ttle.a, amount) : 0.0;

   return lerp (Bgnd, lerp (retval, Bgnd, amt2), Ttle.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FoldPos_Ax
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
