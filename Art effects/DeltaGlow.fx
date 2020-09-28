// @Maintainer jwrl
// @Released 2020-09-28
// @Author jwrl
// @Created 2020-08-26
// @see https://www.lwks.com/media/kunena/attachments/6375/DeltaGlow_640.png

/**
 This effect uses a glow based on the Lightworks glow effect to apply a glow to just the
 foreground component of a blended image, image key or title.  It separates the blended
 foreground from the background by means of a delta or difference key.  That technique
 allows the glow to be applied outside the edges of the blended foreground while the
 background remains "un-glowed".

 The blend option used for the glow is a subset of the standard blend modes widely seen in
 most art software.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeltaGlow.fx
//
// This effect is based on BlendedGlow.fx, with additional delta key support.  That in
// turn was based on the Lightworks Glow effect, with a rewritten blur section.
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Delta glow";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "An effect that applies a Lightworks-style glow to the foreground of a keyed image";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Delta : RenderColorTarget;
texture GlowX : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Delta = sampler_state
{
   Texture   = <Delta>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_GlowX = sampler_state
{
   Texture   = <GlowX>;
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
   string Enum = "Set up delta key,Glow from luminance,Glow from reds,Glow from greens,Glow from blues";
> = 1;

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

float DeltaKey
<
   string Description = "Delta key";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

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

float4 ps_keygen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float alpha = distance (Bgd.g, Fgd.g);

   alpha = max (alpha, distance (Bgd.r, Fgd.r));
   alpha = max (alpha, distance (Bgd.b, Fgd.b));
   alpha = smoothstep (0.0, DeltaKey, alpha);

   return lerp (EMPTY, float4 (Fgd, 1.0), alpha);
}

float4 ps_luma (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Delta, uv);

   float feather = Feather * 0.5;
   float srcLum = ((retval.r * 0.3) + (retval.g * 0.59) + (retval.b * 0.11)) * retval.a;

   if (srcLum < Tolerance) return EMPTY;

   if (srcLum >= (Tolerance + feather)) return Colour;

   return lerp (EMPTY, Colour, (srcLum - Tolerance) / feather);
}

float4 ps_red (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Delta, uv);

   if ((retval.r * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 ps_green (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Delta, uv);

   if ((retval.g * retval.a) < Tolerance) return EMPTY;

   return retval;
}

float4 ps_blue (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Delta, uv);

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
   float4 retval = tex2D (s_Delta, uv);

   float2 xy1 = float2 (0.0, Size *_OutputAspectRatio * 0.5 / _OutputWidth);
   float2 xy  = uv + xy1;

   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy += xy1;
   retval += tex2D (s_Delta, xy); xy = uv - xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy); xy -= xy1;
   retval += tex2D (s_Delta, xy);
   retval /= 23.0;

   float4 Fgnd = tex2D (s_Foreground, uv);

   if (Blend == 0) { retval.rgb = max (retval.rgb, Fgnd.rgb); }
   else if (Blend == 1) { retval.rgb = retval.rgb + Fgnd.rgb - (retval.rgb * Fgnd.rgb); }
   else if (Blend == 2) { retval.rgb = min (retval.rgb + Fgnd.rgb, 1.0.xxx); }
   else {
      float lumaDiff = retval.r + retval.g + retval.b - Fgnd.r - Fgnd.g - Fgnd.b;

      if (lumaDiff < 0.0) retval.rgb = Fgnd.rgb;
   }

   Fgnd.rgb = lerp (Fgnd.rgb, saturate (retval.rgb), Strength);

   return lerp (tex2D (s_Background, uv), Fgnd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Setup
{
   pass P_1
   { PixelShader = compile PROFILE ps_keygen (); }
}

technique LuminanceGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_luma (); }

   pass P_3 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique RedGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_red (); }

   pass P_3 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique GreenGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_green (); }

   pass P_3 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique BlueGlow
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2 < string Script = "RenderColorTarget0 = GlowX;"; >
   { PixelShader = compile PROFILE ps_blue (); }

   pass P_3 < string Script = "RenderColorTarget0 = Delta;"; >
   { PixelShader = compile PROFILE ps_glowX (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
