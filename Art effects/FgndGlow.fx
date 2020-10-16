// @Maintainer jwrl
// @Released 2020-10-16
// @Author jwrl
// @Created 2020-10-16
// @see https://www.lwks.com/media/kunena/attachments/6375/FgndGlow_640.png

/**
 This effect uses a glow based on the Lightworks glow effect to apply a glow to just the
 foreground component of a blended image, image key or title.  The background remains
 "un-glowed".  The effect can be applied to a title or video with transparency by first
 disconnecting any input or blend effect, or the foreground video can be extracted.  In
 that case it is separated from the background by means of a delta or difference key.

 The blend option used for the glow is a subset of the standard blend modes widely seen in
 most art software.
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
// Built 2020-10-16 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Foreground glow";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "An effect that applies a Lightworks-style glow to the foreground of a keyed or blended image";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture FgKey : RenderColorTarget;
texture GlowX : RenderColorTarget;
texture GlowY : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_FgKey = sampler_state { Texture = <FgKey>; };

sampler s_GlowX = sampler_state
{
   Texture   = <GlowX>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Glow = sampler_state
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
   string Enum = "Crawl/Roll/Title/Image key,Video/External image,Delta key";
> = 2;

float DeltaKey
<
   string Group = "Blend mode";
   string Description = "Delta key";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Bad_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define EMPTY   0.0.xxxx

float _OutputWidth;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, uv);

   if (Fgd.a == 0.0) Fgd.rgb = Fgd.aaa;
   else if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = tex2D (s_Background, uv);

      float kDiff = distance (Fgd.rgb, Bgd.rgb);

      Fgd.a = smoothstep (0.0, DeltaKey, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

float4 ps_luma (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_FgKey, uv);

   float feather = Feather * 0.5;
   float srcLum = ((retval.r * 0.3) + (retval.g * 0.59) + (retval.b * 0.11)) * retval.a;

   if (srcLum < Tolerance) return EMPTY;

   if (srcLum >= (Tolerance + feather)) return Colour;

   return lerp (EMPTY, Colour, (srcLum - Tolerance) / feather);
}

float4 ps_red (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_FgKey, uv);

   if ((retval.r * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 ps_green (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_FgKey, uv);

   if ((retval.g * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 ps_blue (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_FgKey, uv);

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
   float4 retval = tex2D (s_FgKey, uv);

   float2 xy1 = float2 (0.0, Size *_OutputAspectRatio * 0.5 / _OutputWidth);
   float2 xy  = uv + xy1;

   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy += xy1;
   retval += tex2D (s_Glow, xy); xy = uv - xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy); xy -= xy1;
   retval += tex2D (s_Glow, xy);
   retval /= 23.0;

   float4 Fgnd, Bgnd = tex2D (s_Background, uv);

   if (Source == 2) { Fgnd = tex2D (s_Foreground, uv); }
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
   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_luma (); }

   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique RedGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_red (); }

   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique GreenGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_green (); }

   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique BlueGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = FgKey;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_blue (); }

   pass P_3 < string Script = "RenderColorTarget0 = GlowY;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique Setup
{
   pass P_1
   { PixelShader = compile PROFILE ps_keygen (); }
}

