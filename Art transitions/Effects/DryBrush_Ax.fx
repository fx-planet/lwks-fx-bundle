// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DryBrush_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_DryBrush.mp4

/**
This mimics the Photoshop angled brush stroke effect to reveal or remove a title.  The
stroke length and angle can be independently adjusted, and can be keyframed while the
transition happens to make the effect more dynamic.

Alpha levels are boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrush_Ax.fx
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
   string Description = "Dry brush mix (alpha)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Mimics the Photoshop angled brush stroke effect to reveal or remove a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

float Length
<
   string Description = "Stroke length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Angle
<
   string Description = "Stroke angle";
   float MinVal = -180.0;
   float MaxVal = 180.0;
> = 45.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

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
   float amount = Ttype == 0 ? 1.0 - Amount : Amount;
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = frac (sin (dot ((uv - 0.5.xx), float2 (12.9898, 78.233))) * 43758.5453);
   float2 xy, xy2;

   xy1 *= stroke * amount;
   sincos (angle, xy2.x, xy2.y);

   xy.x = xy1.x * xy2.x + xy1.y * xy2.y;
   xy.y = xy1.y * xy2.x - xy1.x * xy2.y;

   float4 Fgnd = fn_tex2D (s_Super, uv + xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * (1.0 - amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_DryBrush
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

