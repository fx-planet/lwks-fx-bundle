// @Maintainer jwrl
// @Released 2018-12-28
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
   string Enum = "Horizontal in,Horizontal out,Vertical in,Vertical out";
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

float4 ps_horiz_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float amount = 1.0 - Amount;
   float dsplc  = (OFFSET - Width) * WIDTH;
   float offset = floor (uv.y * dsplc);

   xy.x += (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * amount;

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_horiz_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float dsplc  = (OFFSET - Width) * WIDTH;
   float offset = floor (uv.y * dsplc);

   xy.x += ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * Amount;

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_vert_in (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float amount = 1.0 - Amount;
   float dsplc  = (OFFSET - Width) * WIDTH;
   float offset = floor (uv.x * dsplc);

   xy.y += (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * amount;

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

float4 ps_vert_out (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv;

   float dsplc  = (OFFSET - Width) * WIDTH;
   float offset = floor (uv.x * dsplc);

   xy.y += ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * Amount;

   float4 Fgnd = fn_tex2D (s_Super, xy);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Bars_Ax_Hin
{
   pass P_1
   { PixelShader = compile PROFILE ps_horiz_in (); }
}

technique Bars_Ax_Hout
{
   pass P_1
   { PixelShader = compile PROFILE ps_horiz_out (); }
}

technique Bars_Ax_Vin
{
   pass P_1
   { PixelShader = compile PROFILE ps_vert_in (); }
}

technique Bars_Ax_Vout
{
   pass P_1
   { PixelShader = compile PROFILE ps_vert_out (); }
}

