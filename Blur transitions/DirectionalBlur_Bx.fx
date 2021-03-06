// @Maintainer jwrl
// @Released 2021-06-20
// @Author jwrl
// @Created 2021-06-20
// @see https://www.lwks.com/media/kunena/attachments/6375/DirectionalBlur_Bx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DirectionalBlur_Bx.mp4

/**
 This effect applies a directional (motion) blur to a blended foreground, the angle
 and strength of which can be adjusted.  It then progressively reduces the blur to
 reveal the blended foreground or increases it as it fades the blend out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalBlur_Bx.fx
//
// Version history:
//
// Built 2021-06-20 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Directional blur fade (blend)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Directionally blurs the foreground as it fades in or out";
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

DefineTarget (Title, s_Title);

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

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start of folded delta key";
> = 2;

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
   float4 retval = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float kDiff = distance (retval.rgb, GetPixel (s_Background, uv2).rgb);

      retval.a = smoothstep (0.0, KeyGain, kDiff);
   }
   else if (Source == 1) {
      float key = max (1.0e-6, 2.0 * KeyGain);

      retval.a = pow (retval.a, key);
      retval.rgb /= retval.a;
   }

   return (retval.a == 0.0) ? retval.aaaa : retval;
}

float4 ps_keygen_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 retval = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 refrnc = GetPixel (s_Background, uv2);

      float kDiff = distance (refrnc.rgb, retval.rgb);

      retval.rgb = refrnc.rgb;
      retval.a   = smoothstep (0.0, KeyGain, kDiff);
   }
   else if (Source == 1) {
      float key = max (1.0e-6, 2.0 * KeyGain);

      retval.a = pow (retval.a, key);
      retval.rgb /= retval.a;
   }

   return (retval.a == 0.0) ? retval.aaaa : retval;
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Title, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle), blur.y, blur.x);
      blur   *= (1.0 - saturate (Amount)) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (s_Title, xy1);
         retval += tex2D (s_Title, xy2);
      }

   retval /= SAMPSCALE;
   }

   retval.a *= saturate (((Amount - 0.5) * ((Strength * 3.0) + 1.5)) + 0.5);

   return lerp (GetPixel (s_Background, uv2), retval, retval.a);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Title, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle + 180.0), blur.y, blur.x);
      blur   *= saturate (Amount) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (s_Title, xy1);
         retval += tex2D (s_Title, xy2);
      }

   retval /= SAMPSCALE;
   }

   retval.a *= 1.0 - saturate (((Amount - 0.5) * ((Strength * 3.0) + 1.5)) + 0.5);

   return lerp (GetPixel (s_Background, uv2), retval, retval.a);
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Title, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle), blur.y, blur.x);
      blur   *= (1.0 - saturate (Amount)) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (s_Title, xy1);
         retval += tex2D (s_Title, xy2);
      }

   retval /= SAMPSCALE;
   }

   retval.a *= saturate (((Amount - 0.5) * ((Strength * 3.0) + 1.5)) + 0.5);

   return lerp (GetPixel (s_Foreground, uv1), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DirectionalBlur_Bx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_I)
}

technique DirectionalBlur_Bx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_O)
}

technique DirectionalBlur_Bx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_main_F)
}

