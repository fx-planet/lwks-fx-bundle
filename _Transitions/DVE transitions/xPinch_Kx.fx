// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchX_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_PinchX.mp4

/**
 This effect pinches the blended foreground to a point to clear the background shot,
 while zooming out of the pinch.  It reverses the process to bring in the incoming
 foreground.  Trig functions have been used during the progress of the effect to make
 the acceleration smoother.

 While based on xPinch_Dx.fx, the direction swap has been made symmetrical, unlike that
 in xPinch_Dx.fx.  When used with titles and similar effects which by their nature don't
 occupy the full screen, subjectively this approach looked better.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect xPinch_Fx.fx
//
// This effect is a combination of two previous effects, xPinch_Ax and xPinch_Adx.
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
   string Description = "X-pinch (keyed)";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Pinches the foreground to a point while zooming to either hide or reveal it";
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

#define Overflow(XY)  (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow (XY) ? EMPTY : tex2D (SHADER, XY))

#define MID_PT     (0.5).xx
#define QUARTER_PI 0.7853981634

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);
DefineTarget (Pinch, s_Pinch);

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

float4 ps_pinch_I (float2 uv : TEXCOORD3) : COLOR
{
   float progress = sin ((1.0 - Amount) * QUARTER_PI);
   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return tex2D (s_Super, xy);
}

float4 ps_pinch_O (float2 uv : TEXCOORD3) : COLOR
{
   float progress = sin (Amount * QUARTER_PI);
   float dist  = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv - MID_PT) * scale) + MID_PT;

   return tex2D (s_Super, xy);
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float progress = 1.0 - cos (sin ((1.0 - Amount) * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv3 - MID_PT) * scale) + MID_PT;

   float4 Fgnd = (CropEdges && Overflow (uv1)) ? EMPTY : GetPixel (s_Pinch, xy);

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float progress = 1.0 - cos (sin ((1.0 - Amount) * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv3 - MID_PT) * scale) + MID_PT;

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Pinch, xy);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float progress = 1.0 - cos (sin (Amount * QUARTER_PI));
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv3 - MID_PT) * scale) + MID_PT;

   float4 Fgnd = (CropEdges && Overflow (uv2)) ? EMPTY : GetPixel (s_Pinch, xy);

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique xPinch_Fx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Pinch;"; > ExecuteShader (ps_pinch_I)
   pass P_3 ExecuteShader (ps_main_F)
}

technique xPinch_Fx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Pinch;"; > ExecuteShader (ps_pinch_I)
   pass P_3 ExecuteShader (ps_main_I)
}

technique xPinch_Fx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Pinch;"; > ExecuteShader (ps_pinch_O)
   pass P_3 ExecuteShader (ps_main_O)
}

