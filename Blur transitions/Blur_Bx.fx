// @Maintainer jwrl
// @Released 2021-06-20
// @Author jwrl
// @Created 2021-06-19
// @see https://www.lwks.com/media/kunena/attachments/6375/Blur_Bx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Blur_Bx.mp4

/**
 This effect performs a blurred transition into or out of a blended foreground source.
 It has been designed from the ground up to handle varying frame sizes and aspect
 ratios.  It can be used with title effects, image keys or other blended video layer(s).
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Blur_Bx.fx
//
// Modified 2021-06-20 jwrl.
// Slight rewording of SetTechnique parameter.
//
// Version history:
//
// Built 2021-06-19 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Blur dissolve (blend)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a blur to transition into or out of blended layers";
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
#define HALF_PI   1.5707963268

#define STRENGTH  0.005

#define SAMPLES   30
#define SAMPSCALE 61

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Title, s_Title);
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

float4 ps_blurX_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Title, uv3);

   if (Blurriness > 0.0) {

      float2 blur = float2 ((1.0 - Amount) * Blurriness * STRENGTH / _OutputAspectRatio, 0.0);
      float2 xy1 = uv3, xy2 = uv3;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (s_Title, xy1);
         retval += tex2D (s_Title, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

float4 ps_blurX_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Title, uv3);

   if (Blurriness > 0.0) {

      float2 blur = float2 (Amount * Blurriness * STRENGTH / _OutputAspectRatio, 0.0);
      float2 xy1 = uv3, xy2 = uv3;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (s_Title, xy1);
         retval += tex2D (s_Title, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_BlurX, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, (1.0 - Amount) * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (s_BlurX, xy1);
         retval += tex2D (s_BlurX, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   retval.a *= sin (saturate (Amount * 2.0) * HALF_PI);

   return lerp (GetPixel (s_Background, uv2), retval, retval.a);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_BlurX, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, Amount * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (s_BlurX, xy1);
         retval += tex2D (s_BlurX, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   retval.a *= cos (saturate (Amount - 0.5) * PI);

   return lerp (GetPixel (s_Background, uv2), retval, retval.a);
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_BlurX, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, (1.0 - Amount) * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (s_BlurX, xy1);
         retval += tex2D (s_BlurX, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   retval.a *= sin (saturate (Amount * 2.0) * HALF_PI);

   return lerp (GetPixel (s_Foreground, uv1), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Blur_Bx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = BlurX;"; > ExecuteShader (ps_blurX_I)
   pass P_3 ExecuteShader (ps_main_I)
}

technique Blur_Bx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = BlurX;"; > ExecuteShader (ps_blurX_O)
   pass P_3 ExecuteShader (ps_main_O)
}

technique Blur_Bx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = BlurX;"; > ExecuteShader (ps_blurX_I)
   pass P_3 ExecuteShader (ps_main_F)
}
