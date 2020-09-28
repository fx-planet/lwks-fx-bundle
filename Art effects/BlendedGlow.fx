// @Maintainer jwrl
// @Released 2020-09-28
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
// This effect is based on the Lightworks Glow effect.  I have rewritten the blur section
// somewhat.  It's still pretty much their original, just tweaked a little.
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified jwrl 2020-08-26.
// Rewrote the glow application section of ps_main().
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Blended glow";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "A glow effect using a Lightworks-style glow with added blending to handle transparent video";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture GlowX : RenderColorTarget;
texture GlowY : RenderColorTarget;

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

sampler s_GlowX = sampler_state
{
   Texture   = <GlowX>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_GlowY = sampler_state
{
   Texture   = <GlowY>;
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

float4 ps_luma (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   float feather = Feather * 0.5;
   float srcLum = ((retval.r * 0.3) + (retval.g * 0.59) + (retval.b * 0.11)) * retval.a;

   if (srcLum < Tolerance) return EMPTY;

   if (srcLum >= (Tolerance + feather)) return Colour;

   return lerp (EMPTY, Colour, (srcLum - Tolerance) / feather);
}

float4 ps_red (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if ((retval.r * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 ps_green (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if ((retval.g * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 ps_blue (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if ((retval.b * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 ps_glowX (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_GlowX, uv);

   float2 xy1 = float2 (Size * 0.5 / _OutputWidth, 0.0);
   float2 xy  = uv + xy1;

   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy += xy1;
   retval += tex2D (s_GlowX, xy); xy = uv - xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy); xy -= xy1;
   retval += tex2D (s_GlowX, xy);

   return retval / 23.0;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_GlowY, uv);

   float2 xy1 = float2 (0.0, Size *_OutputAspectRatio * 0.5 / _OutputWidth);
   float2 xy  = uv + xy1;

   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy += xy1;
   retval += tex2D (s_GlowY, xy); xy = uv - xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy); xy -= xy1;
   retval += tex2D (s_GlowY, xy);
   retval /= 23.0;

   float4 Fgnd = tex2D (s_Foreground, uv);
   float4 Bgnd = tex2D (s_Background, uv);

   Fgnd = lerp (Bgnd, Fgnd, Fgnd.a);

   if (Blend == 0) { retval.rgb = max (retval.rgb, Fgnd.rgb); }
   else if (Blend == 1) { retval.rgb = retval.rgb + Fgnd.rgb - (retval.rgb * Fgnd.rgb); }
   else if (Blend == 2) { retval.rgb = min (retval.rgb + Fgnd.rgb, 1.0.xxx); }
   else if ((retval.r + retval.g + retval.b - Fgnd.r - Fgnd.g - Fgnd.b) < 0.0)
      retval.rgb = Fgnd.rgb;

   Fgnd.rgb = lerp (Fgnd.rgb, saturate (retval.rgb), Strength);

   return lerp (Bgnd, Fgnd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LuminanceGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_luma (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique RedGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_red (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique GreenGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_green (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}

technique BlueGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_blue (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main (); }
}
