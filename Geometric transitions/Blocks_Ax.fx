// @Maintainer jwrl
// @Released 2020-07-31
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
// Version history:
//
// Modified 2020-07-31 jwrl.
// Reworded Boost text to match requirements for 2020.1 and up.
// Reworded Transition text to match requirements for 2020.1 and up.
// Move Boost code into separate shader so that the foreground is always correct.
// Corrected divide by zero bug in mosaic development.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
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

texture Super : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Super>;
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

   return tex2D (Vsample, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   if (blockSize > 0.0) {
      float AspectRatio = clamp (AR, 0.01, 10.0);
      float Bsize = max (1e-10, cos (Amount * HALF_PI));

      Bsize *= blockSize * BLOCKS;

      xy.x = (round ((xy.x - 0.5) / Bsize) * Bsize) + 0.5;
      Bsize *= AspectRatio * _OutputAspectRatio;
      xy.y = (round ((xy.y - 0.5) / Bsize) * Bsize) + 0.5;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   if (blockSize > 0.0) {
      float AspectRatio = clamp (AR, 0.01, 10.0);
      float Bsize = max (1e-10, sin (Amount * HALF_PI));

      Bsize *= blockSize * BLOCKS;

      xy.x = (round ((xy.x - 0.5) / Bsize) * Bsize) + 0.5;
      Bsize *= AspectRatio * _OutputAspectRatio;
      xy.y = (round ((xy.y - 0.5) / Bsize) * Bsize) + 0.5;
   }

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Blocks_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Blocks_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_out (); }
}
