// @Maintainer jwrl
// @Released 2020-07-24
// @Author jwrl
// @Created 2020-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/BlendedGlow_640.png

/**
 This effect uses the Lightworks glow effect to apply a blend to the foreground component of
 a blended image.  Unlike the Lightworks glow effect, it supports transparency by allowing
 the glow to fall outside the transparent boundaries of the foreground.  The background is
 handled independently of the glow, and remains sharp as a result.

 The blend option used for the glow is a subset of the standard blend modes widely seen in
 art software.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlendedGlow.fx
//
// This effect is based on the Editshare Glow effect.  I have rewritten it somewhat.
// It's still pretty much their original, just tweaked a little.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Blended glow";
   string Category    = "Stylize";
   string SubCategory = "Art effects";
   string Notes       = "A glow effect using the LW glow with added blending to handle transparent video";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Glow_X : RenderColorTarget;
texture Glow_Y : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Glow_X = sampler_state
{
   Texture   = <Glow_X>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Glow_Y = sampler_state
{
   Texture   = <Glow_Y>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Blend
<
   string Description = "Blend glow using";
   string Enum = "Lighten,Screen,Add,Lighter Colour";
> = 1;

float Amount
<
   string Description = "Fg Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Glow";
   string Description = "Source";
   string Enum = "Luminance,Red,Green,Blue";
> = 0;

float Tolerance
<
   string Group = "Glow";
   string Description = "Tolerance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Feather
<
   string Group = "Glow";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Size
<
   string Group = "Glow";
   string Description = "Size";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 4.0;

float Strength
<
   string Group = "Glow";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 Colour
<
   string Group = "Glow";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define EMPTY   0.0.xxxx

float _OutputWidth;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 lum_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   float feather = Feather * 0.5;
   float srcLum = ((retval.r * 0.3) + (retval.g * 0.59) + (retval.b * 0.11)) * retval.a;

   if (srcLum < Tolerance) return EMPTY;

   if (srcLum >= (Tolerance + feather)) return Colour;

   return lerp (EMPTY, Colour, (srcLum - Tolerance) / feather);
}

float4 red_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if ((retval.r * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 green_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if ((retval.g * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 blue_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if ((retval.b * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 glowX_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Glow_X, uv);

   float2 xy1 = float2 (Size * 0.5 / _OutputWidth, 0.0);
   float2 xy  = uv + xy1;

   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy += xy1;
   retval += tex2D (s_Glow_X, xy); xy = uv - xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy); xy -= xy1;
   retval += tex2D (s_Glow_X, xy);

   return retval / 25.0;
}

float4 glowY_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Glow_Y, uv);

   float2 xy1 = float2 (0.0, Size *_OutputAspectRatio * 0.5 / _OutputWidth);
   float2 xy  = uv + xy1;

   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy += xy1;
   retval += tex2D (s_Glow_Y, xy); xy = uv - xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy); xy -= xy1;
   retval += tex2D (s_Glow_Y, xy);

   float4 Fgnd = tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);
   float4 Glow = float4 (Fgnd.rgb, 1.0) * Fgnd.a;

   Glow = lerp (Glow, Glow + (retval / 25.0), Strength);
   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a);

   if (Blend == 0) { Glow.rgb = max (Glow.rgb, Fgnd.rgb); }
   else if (Blend == 1) { Glow.rgb = saturate (Glow.rgb + Fgnd.rgb - (Glow.rgb * Fgnd.rgb)); }
   else if (Blend == 2) { Glow.rgb = min (Glow.rgb + Fgnd.rgb, 1.0.xxx); }
   else {
      float lumaG = ((Glow.r * 0.3) + (Glow.g * 0.59) + (Glow.b * 0.11));
      float lumaF = ((Fgnd.r * 0.3) + (Fgnd.g * 0.59) + (Fgnd.b * 0.11));

      Glow.rgb = (lumaG < lumaF) ? Fgnd.rgb : Glow.rgb;
   }

   Glow.a = Bgnd.a;

   return lerp (Bgnd, Glow, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LuminanceGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Glow_X;"; >
   { PixelShader = compile PROFILE lum_main (); }

   pass P_2 < string Script = "RenderColorTarget0 = Glow_Y;"; >
   { PixelShader = compile PROFILE glowX_main (); }

   pass P_3
   { PixelShader = compile PROFILE glowY_main (); }
}

technique RedGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Glow_X;"; >
   { PixelShader = compile PROFILE red_main (); }

   pass P_2 < string Script = "RenderColorTarget0 = Glow_Y;"; >
   { PixelShader = compile PROFILE glowX_main (); }

   pass P_3
   { PixelShader = compile PROFILE glowY_main (); }
}

technique GreenGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Glow_X;"; >
   { PixelShader = compile PROFILE green_main (); }

   pass P_2 < string Script = "RenderColorTarget0 = Glow_Y;"; >
   { PixelShader = compile PROFILE glowX_main (); }

   pass P_3
   { PixelShader = compile PROFILE glowY_main (); }
}

technique BlueGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Glow_X;"; >
   { PixelShader = compile PROFILE blue_main (); }

   pass P_2 < string Script = "RenderColorTarget0 = Glow_Y;"; >
   { PixelShader = compile PROFILE glowX_main (); }

   pass P_3
   { PixelShader = compile PROFILE glowY_main (); }
}

