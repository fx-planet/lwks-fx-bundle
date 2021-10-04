// @Maintainer jwrl
// @Released 2021-08-07
// @Author jwrl
// @Created 2021-08-07
// @see https://www.lwks.com/media/kunena/attachments/6375/FgndGlow_640.png

/**
 This effect uses a glow based on the Lightworks glow effect to apply a glow to just the
 foreground component of a blended image, image key or title.  The background remains
 "un-glowed".  The effect can be applied to a title or video with transparency by first
 disconnecting any input or blend effect, or the foreground video can be extracted.  In
 that case it is separated from the background by means of a delta or difference key.

 The blend options used for the glow is a subset of the standard blend modes widely seen
 in most art software.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FgndGlow.fx
//
// This effect replaces both BlendedGlow.fx and DeltaGlow, which have now been retired.
// Like those earlier effects it's based on the Lightworks Glow effect, with the blur
// section completely rewritten.
//
// Version history:
//
// Rewrite 2021-08-07 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Foreground glow";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "An effect that applies a Lightworks-style glow to the foreground of a keyed or blended image";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput( TEXTURE, SAMPLER ) \
                                         \
   texture TEXTURE;                      \
                                         \
   sampler SAMPLER = sampler_state       \
   {                                     \
      Texture   = <TEXTURE>;             \
      AddressU  = ClampToEdge;           \
      AddressV  = ClampToEdge;           \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define DefineTarget( TARGET, TSAMPLE ) \
                                         \
   texture TARGET : RenderColorTarget;   \
                                         \
   sampler TSAMPLE = sampler_state       \
   {                                     \
      Texture   = <TARGET>;              \
      AddressU  = ClampToEdge;           \
      AddressV  = ClampToEdge;           \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY   0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskPixel(SHDR,XY,MM) (Overflow(MM) ? EMPTY : GetPixel(SHDR, XY))

float _OutputHeight;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (FgKey, s_FgKey);

DefineTarget (GlowX, s_GlowX);
DefineTarget (GlowY, s_Glow);

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
   string Description = "Mode";
   string Enum = "Glow from luminance,Glow from reds,Glow from greens,Glow from blues,Set up delta key";
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

int Source
<
   string Group = "Blend mode";
   string Description = "Source selection (disconnect title and image key inputs)";
   string Enum = "Delta key,Crawl/Roll/Title/Image key,Video/External image";
> = 0;

float KeyGain
<
   string Group = "Blend mode";
   string Description = "Trim key";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_glow (sampler s_Source, float2 xy1, float2 xy2)
{
   float4 retval = tex2D (s_Source, xy1);

   float2 xy = xy1 + xy2;

   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy += xy2;
   retval += tex2D (s_Source, xy); xy = xy1 - xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy); xy -= xy2;
   retval += tex2D (s_Source, xy);

   return retval / 23.0;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_keygen (float2 uv : TEXCOORD3) : COLOR
{
   float4 Bgnd, Fgnd = GetPixel (s_Foreground, uv);

   if (Source == 0) {
      Bgnd = GetPixel (s_Background, uv);
      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_luma (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = MaskPixel (s_FgKey, uv, uv);

   float feather = Feather * 0.5;
   float srcLum = ((retval.r * 0.3) + (retval.g * 0.59) + (retval.b * 0.11)) * retval.a;

   if (srcLum < Tolerance) return EMPTY;

   if (srcLum >= (Tolerance + feather)) return Colour;

   return lerp (EMPTY, Colour, (srcLum - Tolerance) / feather);
}

float4 ps_red (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = MaskPixel (s_FgKey, uv, uv);

   return ((retval.r * retval.a) < Tolerance) ? EMPTY : retval;
}

float4 ps_green (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = MaskPixel (s_FgKey, uv, uv);

   return ((retval.g * retval.a) < Tolerance) ? EMPTY : retval;
}

float4 ps_blue (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = MaskPixel (s_FgKey, uv, uv);

   return ((retval.b * retval.a) < Tolerance) ? EMPTY : retval;
}

float4 ps_glowX (float2 uv : TEXCOORD3) : COLOR
{
   return fn_glow (s_GlowX, uv, float2 (Size * 0.5 / _OutputWidth, 0.0));
}

float4 ps_main (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = fn_glow (s_FgKey, uv, float2 (0.0, Size * 0.5 / _OutputHeight));
   float4 Fgnd, Bgnd = GetPixel (s_Background, uv);

   if (Source == 0) { Fgnd = GetPixel (s_Foreground, uv); }
   else {
      Fgnd = tex2D (s_FgKey, uv);
      Fgnd = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), Bgnd.a);
   }

   if (Blend == 0) { retval.rgb = max (retval.rgb, Fgnd.rgb); }
   else if (Blend == 1) { retval.rgb = retval.rgb + Fgnd.rgb - (retval.rgb * Fgnd.rgb); }
   else if (Blend == 2) { retval.rgb = min (retval.rgb + Fgnd.rgb, 1.0.xxx); }
   else {
      float lumaDiff = retval.r + retval.g + retval.b - Fgnd.r - Fgnd.g - Fgnd.b;

      if (lumaDiff < 0.0) retval.rgb = Fgnd.rgb;
   }

   Fgnd.rgb = lerp (Fgnd.rgb, saturate (retval.rgb), Strength);

   return lerp (Bgnd, Fgnd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LuminanceGlow
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; > ExecuteShader (ps_luma)
   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; > ExecuteShader (ps_glowX)
   pass P_4 ExecuteShader (ps_main)
}

technique RedGlow
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; > ExecuteShader (ps_red)
   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; > ExecuteShader (ps_glowX)
   pass P_4 ExecuteShader (ps_main)
}

technique GreenGlow
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; > ExecuteShader (ps_green)
   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; > ExecuteShader (ps_glowX)
   pass P_4 ExecuteShader (ps_main)
}

technique BlueGlow
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; > ExecuteShader (ps_blue)
   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; > ExecuteShader (ps_glowX)
   pass P_4 ExecuteShader (ps_main)
}

technique Setup
{
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)

   pass P_1 ExecuteShader (ps_keygen)
}

