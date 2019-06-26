// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blocks_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Blocks.mp4

/**
This effect is used to transition into or out of a title.  It also composites the result
over a background layer.

The title fading out builds into larger and larger blocks as it fades.  The incoming
title does the reverse of that.  The alpha level can be boosted to support Lightworks
titles, which is the default setting.  The boost is designed to give the same result as
Lightworks' internal title handling.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Blocks_Ax.fx
//
// This is a revision of an earlier effect, Adx_Blocks.fx, which provided the ability to
// transition between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Block dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Builds a title into larger and larger blocks as it fades";
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
   string Enum = "Fade in,Fade out";
> = 0;

float blockSize
<
   string Group = "Blocks";
   string Description = "Size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float AR
<
   string Group = "Blocks";
   string Description = "Aspect ratio";
   float MinVal = 0.25;
   float MaxVal = 4.00;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLOCKS  0.1

#define HALF_PI 1.570796

float _OutputAspectRatio;

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

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   if (blockSize > 0.0) {
      float AspectRatio = clamp (AR, 0.01, 10.0);
      float Bsize = cos (Amount * HALF_PI);

      Bsize *= blockSize * BLOCKS;

      xy.x = (round ((xy.x - 0.5) / Bsize) * Bsize) + 0.5;
      Bsize *= AspectRatio * _OutputAspectRatio;
      xy.y = (round ((xy.y - 0.5) / Bsize) * Bsize) + 0.5;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   if (blockSize > 0.0) {
      float AspectRatio = clamp (AR, 0.01, 10.0);
      float Bsize = sin (Amount * HALF_PI);

      Bsize *= blockSize * BLOCKS;

      xy.x = (round ((xy.x - 0.5) / Bsize) * Bsize) + 0.5;
      Bsize *= AspectRatio * _OutputAspectRatio;
      xy.y = (round ((xy.y - 0.5) / Bsize) * Bsize) + 0.5;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Blocks_in
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Blocks_out
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_out (); }
}

