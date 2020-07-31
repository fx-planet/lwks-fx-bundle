// @Maintainer jwrl
// @Released 2020-07-31
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Tiles_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Tiles.mp4

/**
 This is an alpha transition that splits title(s) into tiles then blows them apart.  Alpha
 levels can be boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TileSplit_Ax.fx
//
// This is a revision of an earlier effect, Adx_Tiles.fx, which provided the ability to
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
// Modified 14 December 2018 jwrl.
// Changed title from "Tiles" to "Tile split (alpha)".
// Changed subcategory.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tile split (alpha)";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Breaks a title into tiles";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Super : RenderColorTarget;
texture Tiles : RenderColorTarget;

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

sampler s_Tiles = sampler_state
{
   Texture   = <Tiles>;
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

float Width
<
   string Group = "Tile size";
   string Description = "Width";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Height
<
   string Group = "Tile size";
   string Description = "Height";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY  (0.0).xxxx

#define FACTOR 100
#define OFFSET 1.2

float _OutputAspectRatio;
float _Progress;

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

float4 ps_horiz_in (float2 uv : TEXCOORD1) : COLOR
{
   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (1.0 - offset) * (1.0 - Amount);

   return fn_tex2D (s_Super, uv + float2 (offset, 0.0));
}

float4 ps_horiz_out (float2 uv : TEXCOORD1) : COLOR
{
   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (offset - 1.0) * Amount;

   return fn_tex2D (s_Super, uv + float2 (offset, 0.0));
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv.x * dsplc);

   offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = fn_tex2D (s_Tiles, uv + float2 (0.0, offset / _OutputAspectRatio));

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv.x * dsplc);

   offset  = ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * Amount;

   float4 Fgnd = fn_tex2D (s_Tiles, uv + float2 (0.0, offset / _OutputAspectRatio));

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TileSplit_Ax_in
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = Tiles;"; >
   { PixelShader = compile PROFILE ps_horiz_in (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique TileSplit_Ax_out
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = Tiles;"; >
   { PixelShader = compile PROFILE ps_horiz_out (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}
