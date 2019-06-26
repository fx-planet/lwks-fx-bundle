// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Wave_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Wave.mp4

/**
This an alpha transition that splits title(s) into sinusoidal strips or waves and
compresses them to zero height.  The vertical centring can be adjusted so that the
title collapses symmetrically.  Alpha levels can be boosted to better support
Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WaveCollapse_Ax.fx
//
// This is a revision of an earlier effect, Ax_Wave.fx, which also had the ability to
// wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Wave collapse (alpha)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Splits the title into sinusoidal strips or waves and compresses it to zero height";
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

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Distort in,Distort out";
> = 0;

float Spacing
<
   string Group = "Waves";
   string Description = "Spacing";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Group = "Waves";
   string Description = "Vertical centre";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

#define EMPTY    (0.0).xxxx

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

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (HALF_PI - (Amount * HALF_PI))) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (uv.x + (sin (Width * uv.y * PI) * (1.0 - Amount)));
   xy.y = saturate (((uv.y - centreY) * Height) + centreY);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * saturate (Amount * 5.0));
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float Width = 10.0 + (Spacing * 40.0);
   float Height = ((1.0 - cos (Amount * HALF_PI)) * HEIGHT) + 1.0;

   float2 xy;

   xy.x = saturate (uv.x + (sin (Width * uv.y * PI) * Amount));
   xy.y = saturate (((uv.y - centreY) * Height) + centreY);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * saturate ((1.0 - Amount) * 5.0));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WaveCollapse_Ax_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique WaveCollapse_Ax_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

