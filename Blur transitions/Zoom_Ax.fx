// @Maintainer jwrl
// @Released 2020-07-23
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
// Version history:
//
// Modified 2020-07-23 jwrl
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost code as a shader rather than a function.
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

texture Key : RenderColorTarget;
texture Buf : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Key = sampler_state
{
   Texture   = <Key>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Buffer = sampler_state
{
   Texture   = <Buf>;
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
   string Enum = "Crawl/Roll/Key/Image key,Video/External image";
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
   string Enum = "At start (zoom out),At end (zoom out),At start (zoom in),At end (zoom in)";
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

#define EMPTY   0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

float4 ps_zoom_A (float2 uv : TEXCOORD1, uniform sampler s) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (s, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount);
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (s, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_B (float2 uv : TEXCOORD1, uniform sampler s) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (s, uv);

   float zoomStrength = zoomAmount * Amount / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (s, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_C (float2 uv : TEXCOORD1, uniform sampler s) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (s, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (s, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_D (float2 uv : TEXCOORD1, uniform sampler s) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (s, uv);

   float zoomStrength = zoomAmount * Amount;
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (s, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main_I (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Key, uv);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Key, uv);

   return lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Zoom_Ax_A
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = Buf;"; >
   { PixelShader = compile PROFILE ps_zoom_A (s_Key); }

   pass P_2 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_zoom_A (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Zoom_Ax_B
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = Buf;"; >
   { PixelShader = compile PROFILE ps_zoom_B (s_Key); }

   pass P_2 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_zoom_B (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique Zoom_Ax_C
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = Buf;"; >
   { PixelShader = compile PROFILE ps_zoom_C (s_Key); }

   pass P_2 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_zoom_C (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Zoom_Ax_D
{
   pass P_0 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_1 < string Script = "RenderColorTarget0 = Buf;"; >
   { PixelShader = compile PROFILE ps_zoom_D (s_Key); }

   pass P_2 < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_zoom_D (s_Buffer); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}
