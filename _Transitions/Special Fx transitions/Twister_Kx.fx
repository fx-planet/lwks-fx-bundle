// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Twister_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Twister.mp4

/**
 This is a dissolve/wipe that uses sine & cosine distortions to perform a rippling twist to
 establish or remove the blended foreground.  The range of effect variations possible with
 different combinations of settings is almost inifinite.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Twister_Kx.fx
//
// This effect is a combination of two previous effects, Twister_Ax and Twister_Adx.
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
   string Description = "The twister (keyed)";
   string Category    = "Mix";
   string SubCategory = "Special Fx transitions";
   string Notes       = "Performs a rippling twist to establish or remove the blended foreground image";
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

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

float _OutputHeight;

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

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

int TransProfile
<
   string Description = "Transition profile";
   string Enum = "Left > right profile A,Left > right profile B,Right > left profile A,Right > left profile B"; 
> = 1;

float Width
<
   string Group = "Ripples";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ripples
<
   string Group = "Ripples";
   string Description = "Ripple amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.6;

float Spread
<
   string Group = "Ripples";
   string Description = "Ripple width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

float Twists
<
   string Group = "Twists";
   string Description = "Twist amount";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

bool Show_Axis
<
   string Group = "Twists";
   string Description = "Show twist axis";
> = false;

float Axis
<
   string Group = "Twists";
   string Description = "Set axis";
   float MinVal = 0.00;
   float MaxVal = 1.00;
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

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? uv3.x : 1.0 - uv3.x;

   maxVis = Amount * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv3.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv3.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Super, xy);
   float4 Bgd = lerp (GetPixel (s_Foreground, uv1), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? uv3.x : 1.0 - uv3.x;

   maxVis = Amount * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv3.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv3.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   float4 Bgd = lerp (GetPixel (s_Background, uv2), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   int Mode = (int) fmod ((float)TransProfile, 2.0);

   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (Mode == TransProfile) ? 1.0 - uv3.x : uv3.x;

   maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;

   float amount = saturate (maxVis / range);
   float T_Axis = uv3.y - Axis;

   float ripples = max (0.0, RIPPLES * (range - maxVis));
   float spread  = ripples * Spread * SCALE;
   float modultn = pow (max (0.0, Ripples), 5.0) * ripples;
   float offset  = sin (modultn) * spread;
   float twists  = cos (modultn * Twists * 4.0);

   float2 xy = float2 (uv3.x, Axis + (T_Axis / twists) - offset);

   xy.y += offset * float (Mode * 2);

   float4 Fgd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Super, xy);
   float4 Bgd = lerp (GetPixel (s_Background, uv2), Fgd, Fgd.a * amount);

   if (Show_Axis) {
      float AxisLine = max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0);

      Fgd.rgb = Bgd.rgb + AxisLine.xxx;
      Bgd.rgb = min (1.0.xxx, Fgd.rgb) - max (0.0.xxx, Fgd.rgb - 1.0.xxx);
   }

   return Bgd;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Twister_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_main_F)
}

technique Twister_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_I)
}

technique Twister_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_O)
}

