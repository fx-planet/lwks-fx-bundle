// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Bars_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Bars.mp4

/**
 This an alpha transition that splits a title into strips then blows them apart either
 horizontally or vertically.  The alpha level can be boosted to support Lightworks titles,
 which is the default.  The boost is designed to give the same result as Lightworks'
 internal title handling.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bars_Ax.fx
//
// This is a revision of an earlier effect, Adx_Bars.fx, which provided the ability to
// wipe between two titles.  That added needless complexity, when the same functionality
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified 2020-07-31 jwrl.
// Reworded Boost text to match requirements for 2020.1 and up.
// Reworded Transition text to match requirements for 2020.1 and up.
// Move Boost code into separate shader so that the foreground is always correct.
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
   string Description = "Bar wipe (alpha)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits a title into strips and separates them horizontally or vertically";
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

int Ttype
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip";
> = 0;

int SetTechnique
<
   string Description = "Transition direction";
   string Enum = "Horizontal,Vertical";
> = 0;

float Width
<
   string Description = "Bar width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define WIDTH  50
#define OFFSET 1.2

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

float4 ps_horiz (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 offset = float2 (0.0, floor (xy1.y * dsplc));
   float2 xy = (Ttype == 1) ? xy1 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : xy1 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (fn_tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

float4 ps_vert (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 offset = float2 (floor (xy1.x * dsplc), 0.0);
   float2 xy = (Ttype == 1) ? xy1 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : xy1 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (fn_tex2D (s_Background, xy2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Bars_Ax_H
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_horiz (); }
}

technique Bars_Ax_V
{
   pass P_1
   < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_vert (); }
}
