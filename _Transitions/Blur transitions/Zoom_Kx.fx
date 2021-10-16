// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Zoom_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Zoom.mp4

/**
 This effect is a user-selectable zoom in or zoom out that transitions into or out of
 the foreground layer.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Kx.fx
//
// This effect is a combination of two previous effects, Zoom_Ax and Zoom_Adx.
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom dissolve (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Zooms in or out of the foreground to establish or remove it";
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

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
}

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define ExecuteParam(SHADER,P) { PixelShader = compile PROFILE SHADER (P); }

#define EMPTY 0.0.xxxx

#define Overflow(XY)  (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow (XY) ? EMPTY : tex2D (SHADER, XY))

#define SAMPLE  61
#define DIVISOR 61.0    // Sorts out float issues with Linux

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Title, s_Title);
DefineTarget (Super, s_Super);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "Start/out (delta folded),Start/in (delta folded),At start (zoom out),At end (zoom out),At start (zoom in),At end (zoom in)";
> = 2;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

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

float KeyGain
<
   string Description = "Key trim";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_zoom_A (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                  float2 uv3 : TEXCOORD3, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv3);

   float zoomStrength = zoomAmount * (1.0 - Amount);
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv3 - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_B (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                  float2 uv3 : TEXCOORD3, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv3);

   float zoomStrength = zoomAmount * Amount / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv3 - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_C (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                  float2 uv3 : TEXCOORD3, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv3);

   float zoomStrength = zoomAmount * (1.0 - Amount) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv3 - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_zoom_D (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                  float2 uv3 : TEXCOORD3, uniform sampler imgSampler) : COLOR
{
   if (zoomAmount == 0.0) return tex2D (imgSampler, uv3);

   float zoomStrength = zoomAmount * Amount;
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy = uv3 - zoomCentre;

   float4 retval = EMPTY;

   for (int i = 0; i < SAMPLE; i++) {
      retval += tex2D (imgSampler, xy * scale + zoomCentre);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Title, uv3);

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Title, uv3);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * Amount);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Title, uv3);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Zoom_Kx_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Super;"; > ExecuteParam (ps_zoom_A, s_Title)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_zoom_A, s_Super)
   pass P_4 ExecuteShader (ps_main_F)
}

technique Zoom_Kx_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Super;"; > ExecuteParam (ps_zoom_C, s_Title)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_zoom_C, s_Super)
   pass P_4 ExecuteShader (ps_main_F)
}

technique Zoom_Kx_2
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Super;"; > ExecuteParam (ps_zoom_A, s_Title)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_zoom_A, s_Super)
   pass P_4 ExecuteShader (ps_main_I)
}

technique Zoom_Kx_3
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Super;"; > ExecuteParam (ps_zoom_B, s_Title)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_zoom_B, s_Super)
   pass P_4 ExecuteShader (ps_main_O)
}

technique Zoom_Kx_4
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Super;"; > ExecuteParam (ps_zoom_C, s_Title)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_zoom_C, s_Super)
   pass P_4 ExecuteShader (ps_main_I)
}

technique Zoom_Kx_5
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Super;"; > ExecuteParam (ps_zoom_D, s_Title)
   pass P_3 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_zoom_D, s_Super)
   pass P_4 ExecuteShader (ps_main_O)
}

