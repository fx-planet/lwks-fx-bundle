// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Blur_Dx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Blur_Dx.mp4

/**
 This effect performs a blurred transition between two sources.  It has been designed from
 the ground up to handle mixtures of varying frame sizes and aspect ratios.  To this end,
 it has been tested with a range of rotated camera phone videos, as well as professional
 standard camera formats.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Blur_Dx.fx
//
// Version history:
//
// Rebuild 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Blur dissolve";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a blur to transition between two video sources";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI        3.1415926536

#define STRENGTH  0.005

#define SAMPLES   30
#define SAMPSCALE 61

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Mixed, s_Mixed);
DefineTarget (BlurX, s_BlurX);

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

float Blurriness
<
   string Description = "Blurriness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_mixer (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);
   float4 Bgnd = GetPixel (s_Background, uv2);

   return lerp (Fgnd, Bgnd, saturate (Amount + Amount - 0.5));
}

float4 ps_blurX (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Mixed, uv3);

   if (Blurriness > 0.0) {

      float amount = sin (saturate (Amount) * PI) * Blurriness * STRENGTH / _OutputAspectRatio;

      float2 blur = float2 (amount, 0.0);
      float2 xy1 = uv3, xy2 = uv3;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (s_Mixed, xy1);
         retval += tex2D (s_Mixed, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_BlurX, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, sin (saturate (Amount) * PI) * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (s_BlurX, xy1);
         retval += tex2D (s_BlurX, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Blur_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Mixed;"; > ExecuteShader (ps_mixer)
   pass P_2 < string Script = "RenderColorTarget0 = BlurX;"; > ExecuteShader (ps_blurX)
   pass P_3 ExecuteShader (ps_main)
}
