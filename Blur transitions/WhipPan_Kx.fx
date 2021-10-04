// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPanAx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/WhipPan_AxAdx.mp4

/**
 This effect performs a whip pan style transition to bring a foreground image onto or off
 the screen.  Unlike the blur dissolve effect, this effect also pans the foreground.  It
 is limited to producing vertical and horizontal whips only.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPan_Kx.fx
//
// This effect is a combination of two previous effects, WhipPan_Ax and WhipPan_Adx.
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
   string Description = "Whip pan (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a difference key and a directional blur to simulate a whip pan into or out of a title";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY)  (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow (XY) ? EMPTY : tex2D (SHADER, XY))

#define L_R       0
#define R_L       1
#define T_B       2
#define B_T       3

#define HALF_PI   1.5707963268

#define SAMPLES   120
#define SAMPSCALE 121.0

#define STRENGTH  0.00125

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Title, s_Title);
DefineTarget (Blur, s_Blur);

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
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

int Mode
<
   string Description = "Whip direction";
   string Enum = "Left to right,Right to left,Top to bottom,Bottom to top";
> = 0;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float Strength
<
   string Description = "Strength";
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

float4 ps_blur_I (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Title, uv);

   float amount = 1.0 - cos (saturate ((1.0 - Amount) * 2.0) * HALF_PI);

   if ((amount == 0.0) || (Strength <= 0.0)) return retval;

   float2 xy1 = uv;
   float2 xy2 = (Mode < T_B) ? float2 (amount, 0.0)
                             : float2 (0.0, amount * _OutputAspectRatio);

   xy2 *= Strength * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (s_Title, xy1);
      xy1 -= xy2;
   }

   return retval / SAMPSCALE;
}

float4 ps_blur_O (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = tex2D (s_Title, uv);

   float amount = 1.0 - cos (saturate (Amount * 2.0) * HALF_PI);

   if ((amount == 0.0) || (Strength <= 0.0)) return retval;

   float2 xy1 = uv;
   float2 xy2 = (Mode < T_B) ? float2 (amount, 0.0)
                             : float2 (0.0, amount * _OutputAspectRatio);

   xy2 *= Strength * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (s_Title, xy1);
      xy1 -= xy2;
   }

   return retval / SAMPSCALE;
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (1.0 - sin (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv3 + float2 (amount, 0.0)
             : (Mode == R_L) ? uv3 - float2 (amount, 0.0)
             : (Mode == T_B) ? uv3 + float2 (0.0, amount) : uv3 - float2 (0.0, amount);

   float4 Overlay = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Blur, xy);

   return lerp (GetPixel (s_Foreground, uv1), Overlay, Overlay.a);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (1.0 - sin (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv3 + float2 (amount, 0.0)
             : (Mode == R_L) ? uv3 - float2 (amount, 0.0)
             : (Mode == T_B) ? uv3 + float2 (0.0, amount) : uv3 - float2 (0.0, amount);

   float4 Overlay = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Blur, xy);

   return lerp (GetPixel (s_Background, uv2), Overlay, Overlay.a);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (1.0 - cos (Amount * HALF_PI)) * 1.5 * Strength;

   float2 xy = (Mode == L_R) ? uv3 - float2 (amount, 0.0)
             : (Mode == R_L) ? uv3 + float2 (amount, 0.0)
             : (Mode == T_B) ? uv3 - float2 (0.0, amount) : uv3 + float2 (0.0, amount);

   float4 Overlay = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Blur, xy);

   return lerp (GetPixel (s_Background, uv2), Overlay, Overlay.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique WhipPan_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Blur;"; > ExecuteShader (ps_blur_I)
   pass P_3 ExecuteShader (ps_main_F)
}

technique WhipPan_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Blur;"; > ExecuteShader (ps_blur_I)
   pass P_3 ExecuteShader (ps_main_I)
}

technique WhipPan_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Title;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Blur;"; > ExecuteShader (ps_blur_O)
   pass P_3 ExecuteShader (ps_main_O)
}

