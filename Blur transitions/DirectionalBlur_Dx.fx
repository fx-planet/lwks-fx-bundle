// @Maintainer jwrl
// @Released 2021-06-20
// @Author jwrl
// @Created 2021-06-20
// @see https://www.lwks.com/media/kunena/attachments/6375/DirectionalBlur_Dx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DirectionalBlur_Dx.mp4

/**
 This effect performs a transition between two sources.  During the process it also applies
 a directional blur, the angle and strength of which can be fully adjusted.  It has been
 designed from the ground up to handle mixtures of varying frame sizes and aspect ratios.
 To this end, it has been tested with a range of rotated camera phone videos, as well as
 professional standard camera formats.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalBlur_Dx.fx
//
// Version history:
//
// Built 2021-06-20 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Directional blur dissolve";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a directional blur to transition between two sources";
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

#define EMPTY 0.0.xxxx

#define IsOutOfBounds(XY) any(saturate(XY) - XY)
#define GetPixel(SHD, XY) (IsOutOfBounds(XY) ? EMPTY : tex2D (SHD, XY))

#define DefineInput(TEXTURE, SAMPLER)  \
                                       \
texture TEXTURE;                       \
                                       \
sampler SAMPLER = sampler_state        \
{                                      \
   Texture   = <TEXTURE>;              \
   AddressU  = ClampToEdge;            \
   AddressV  = ClampToEdge;            \
   MinFilter = Linear;                 \
   MagFilter = Linear;                 \
   MipFilter = Linear;                 \
}

#define DefineTarget(TEXTURE, SAMPLER) \
                                       \
texture TEXTURE : RenderColorTarget;   \
                                       \
sampler SAMPLER = sampler_state        \
{                                      \
   Texture   = <TEXTURE>;              \
   AddressU  = Mirror;                 \
   AddressV  = Mirror;                 \
   MinFilter = Linear;                 \
   MagFilter = Linear;                 \
   MipFilter = Linear;                 \
}

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define PI        3.1415926536

#define SAMPLES   30
#define SAMPSCALE 61

#define STRENGTH  0.005

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Mixed, s_Mixed);

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

float Spread
<
   string Group = "Blur settings";
   string Description = "Spread";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Angle
<
   string Group = "Blur settings";
   string Description = "Angle";
   float MinVal = -180.00;
   float MaxVal = 180.0;
> = 0.0;

float Strength
<
   string Group = "Blur settings";
   string Description = "Strength";
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

   float amount = pow (1.0 - (abs (Amount - 0.5) * 2.0), 1.0 + (Strength * 8.0)) / 2.0;

   if (Amount > 0.5) amount = 1.0 - amount;

   return lerp (Fgnd, Bgnd, amount);
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Mixed, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle), blur.y, blur.x);
      blur   *= sin (saturate (Amount) * PI) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (s_Mixed, xy1);
         retval += tex2D (s_Mixed, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DirectionalBlur_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Mixed;"; > ExecuteShader (ps_mixer)
   pass P_2 ExecuteShader (ps_main)
}

