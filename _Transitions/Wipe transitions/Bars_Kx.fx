// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Bars_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Bars.mp4

/**
 This is a transition that moves the strips of a blended foreground together from off-screen
 either horizontally or vertically or splits it into strips then blows them apart either
 horizontally or vertically.  Useful for applying transitions to titles.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bars_Kx.fx
//
// This effect is a combination of two previous effects, Bars_Ax and Bars_Adx.
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
   string Description = "Bar wipe (keyed)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Splits a foreground image into strips which separate horizontally or vertically";
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
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define WIDTH  50
#define OFFSET 1.2

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

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

int Ttype
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

int SetTechnique
<
   string Description = "Transition direction";
   string Enum = "Horizontal,Vertical";
> = 0;

float Width
<
   string Description = "Bar width";
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

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Bgnd, Fgnd = tex2D (s_Foreground, uv1);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (s_Background, uv2);
      }
      else Bgnd = tex2D (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_horiz (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 bgd, offset = float2 (0.0, floor (uv1.y * dsplc));
   float2 xy = (Ttype == 2) ? uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = GetPixel (s_Foreground, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = GetPixel (s_Background, uv2);
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_vert (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd;

   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 bgd, offset = float2 (floor (uv3.x * dsplc), 0.0);
   float2 xy = (Ttype == 2) ? uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = GetPixel (s_Foreground, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = GetPixel (s_Background, uv2);
   }

   float4 Fgnd = (CropEdges && Overflow (bgd)) ? EMPTY : GetPixel (s_Super, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Bars_Kx_H
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_horiz)
}

technique Bars_Kx_V
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_vert)
}

