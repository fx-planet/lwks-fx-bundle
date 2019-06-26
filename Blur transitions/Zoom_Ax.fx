// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Zoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Zoom.mp4

/**
This effect is a user-selectable zoom in or zoom out that transitions into or out of a
title.  It also composites the result over a background layer.  Alpha levels can be
boosted to support Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Ax.fx
//
// This is a revision of an earlier effect, Adx_Zoom.fx, which also provided the ability
// to wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
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
   string Description = "Zoom dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Performs a rippling twist to establish or remove a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture _Buffer : RenderColorTarget;
texture Overlay : RenderColorTarget;

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

sampler s_Buffer = sampler_state
{
   Texture   = <_Buffer>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Overlay = sampler_state
{
   Texture   = <Overlay>;
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
   string Description = "Direction";
   string Enum = "Zoom out/fade in,Zoom in/fade in,Zoom out/fade out,Zoom in/fade out";
> = 0;

float zoomAmount
<
   string Group = "Zoom";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Xcentre
<
   string Group = "Zoom";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Group = "Zoom";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SAMPLE  61
#define DIVISOR 61.0    // Sorts out float issues with Linux

#define EMPTY   (0.0).xxxx

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

float4 ps_zoom_A (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount);
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_B (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * Amount / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_C (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_D (float2 uv : TEXCOORD1, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv);

   float zoomStrength = zoomAmount * Amount;
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main_in (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Overlay, uv);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_out (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Overlay, uv);

   return lerp (tex2D (s_Video, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Ax_Zoom_out_in
{
   pass P_1 < string Script = "RenderColorTarget0 = _Buffer;"; >
   { PixelShader = compile PROFILE ps_zoom_A (s_Super); }

   pass P_2 < string Script = "RenderColorTarget0 = Overlay;"; >
   { PixelShader = compile PROFILE ps_zoom_A (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Zoom_in_in
{
   pass P_1 < string Script = "RenderColorTarget0 = _Buffer;"; >
   { PixelShader = compile PROFILE ps_zoom_C (s_Super); }

   pass P_2 < string Script = "RenderColorTarget0 = Overlay;"; >
   { PixelShader = compile PROFILE ps_zoom_C (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_in (); }
}

technique Ax_Zoom_out_out
{
   pass P_1 < string Script = "RenderColorTarget0 = _Buffer;"; >
   { PixelShader = compile PROFILE ps_zoom_B (s_Super); }

   pass P_2 < string Script = "RenderColorTarget0 = Overlay;"; >
   { PixelShader = compile PROFILE ps_zoom_B (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

technique Ax_Zoom_in_out
{
   pass P_1 < string Script = "RenderColorTarget0 = _Buffer;"; >
   { PixelShader = compile PROFILE ps_zoom_D (s_Super); }

   pass P_2 < string Script = "RenderColorTarget0 = Overlay;"; >
   { PixelShader = compile PROFILE ps_zoom_D (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_out (); }
}

