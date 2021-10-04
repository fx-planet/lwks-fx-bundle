// @Maintainer jwrl
// @Released 2021-07-24
// @Author rakusan
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Spin_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Spin.mp4

/**
 The effect applies a rotary blur to transition into or out of the foreground and is
 based on original shader code by rakusan (http://kuramo.ch/webgl/videoeffects/).  The
 direction, aspect ratio, centring and strength of the blur can all be adjusted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spin_Kx.fx
//
// This effect is a combination of two previous effects, Spin_Ax and Spin_Adx.
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
   string Description = "Spin dissolve (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Dissolves the foreground through a blurred spin";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Bad_Lightworks_version
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

#define HALF_PI   1.5707963268

#define REDUCE    0.009375

#define CCW       0
#define CW        1

float _OutputAspectRatio;

float blur_idx []  = { 0, 20, 40, 60, 80 , 80 };
float redux_idx [] = { 1.0, 0.8125, 0.625, 0.4375, 0.25 , 0.25 };

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Title, s_Title);
DefineTarget (Delta, s_Delta);
DefineTarget (Spin, s_Spin);

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

int CW_CCW
<
   string Description = "Rotation direction";
   string Enum = "Anticlockwise,Clockwise";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float blurAmount
<
   string Group = "Spin";
   string Description = "Arc (degrees)";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 90.0;

float aspectRatio
<
   string Group = "Spin";
   string Description = "Aspect ratio 1:x";
   float MinVal = 0.01;
   float MaxVal = 10.00;
> = 1.0;

float centreX
<
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.50;
   float MaxVal = 1.50;
> = 0.5;

float centreY
<
   string Group = "Spin";
   string Description = "Centre";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.50;
   float MaxVal = 1.50;
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

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                  float2 uv3 : TEXCOORD3, uniform int passNum) : COLOR
{
   float blurLen = (1.0 - sin (Amount * HALF_PI)) * blurAmount;

   float4 retval;

   if (blurLen == 0.0) { retval = tex2D (s_Delta, uv3); }
   else {
      retval = (0.0).xxxx;

      float2 outputAspect = float2 (1.0, _OutputAspectRatio);
      float2 blurAspect = float2 (1.0, aspectRatio);
      float2 centre = float2 (centreX, 1.0 - centreY );
      float2 xy1, xy2 = (uv3 - centre) / outputAspect / blurAspect;

      float reduction = redux_idx [passNum];
      float amount = radians (blurLen) / 100.0;

      if (CW_CCW == CCW) amount = -amount;

      float Tcos, Tsin, ang = amount * blur_idx [passNum];

      for (int i = 0; i < 20; i++) {
         sincos (ang, Tsin, Tcos);
         xy1 = centre + float2 ((xy2.x * Tcos - xy2.y * Tsin),
                                (xy2.x * Tsin + xy2.y * Tcos) * outputAspect.y) * blurAspect;
         retval = max (retval, (tex2D (s_Delta, xy1) * reduction));
         reduction -= REDUCE;
         ang += amount;
      }

      if ((passNum == 1) || (passNum == 3)) { retval = max (retval, tex2D (s_Title, uv3)); }
      else if (passNum != 0) retval = max (retval, tex2D (s_Spin, uv3));
   }

   if (passNum > 3) {
      float4 Bgnd;

      if (passNum == 4) {
         Bgnd = GetPixel (s_Foreground, uv1);
         if (CropEdges && Overflow (uv1)) retval = EMPTY;
      }
      else {
         Bgnd = GetPixel (s_Background, uv2);
         if (CropEdges && Overflow (uv2)) retval = EMPTY;
      }

      retval = lerp (Bgnd, retval, retval.a * Amount);
   }

   return retval;
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2,
                  float2 uv3 : TEXCOORD3, uniform int passNum) : COLOR
{
   float blurLen = (1.0 - cos (Amount * HALF_PI)) * blurAmount;

   float4 retval;

   if (blurLen == 0.0) { retval = tex2D (s_Delta, uv3); }
   else {
      retval = (0.0).xxxx;

      float2 outputAspect = float2 (1.0, _OutputAspectRatio);
      float2 blurAspect = float2 (1.0, aspectRatio);
      float2 centre = float2 (centreX, 1.0 - centreY );
      float2 xy1, xy2 = (uv1 - centre) / outputAspect / blurAspect;

      float reduction = redux_idx [passNum];
      float amount = radians (blurLen) / 100.0;

      if (CW_CCW == CW) amount = -amount;

      float Tcos, Tsin, ang = amount * blur_idx [passNum];

      for (int i = 0; i < 20; i++) {
         sincos (ang, Tsin, Tcos);
         xy1 = centre + float2 ((xy2.x * Tcos - xy2.y * Tsin),
                                (xy2.x * Tsin + xy2.y * Tcos) * outputAspect.y) * blurAspect;
         retval = max (retval, (tex2D (s_Delta, xy1) * reduction));
         reduction -= REDUCE;
         ang += amount;
      }

      if ((passNum == 1) || (passNum == 3)) { retval = max (retval, tex2D (s_Title, uv1)); }
      else if (passNum != 0) retval = max (retval, tex2D (s_Spin, uv3));
   }

   if (passNum == 4) {

      if (CropEdges && Overflow (uv2)) retval = EMPTY;

      retval = lerp (GetPixel (s_Background, uv2), retval, retval.a * (1.0 - Amount));
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Spin_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_main_I, 0)
   pass P_3 < string Script = "RenderColorTarget0 = Spin;"; > ExecuteParam (ps_main_I, 1)
   pass P_4 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_main_I, 2)
   pass P_5 < string Script = "RenderColorTarget0 = Spin;"; > ExecuteParam (ps_main_I, 3)
   pass P_6 ExecuteParam (ps_main_I, 4)
}

technique Spin_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_main_I, 0)
   pass P_3 < string Script = "RenderColorTarget0 = Spin;"; > ExecuteParam (ps_main_I, 1)
   pass P_4 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_main_I, 2)
   pass P_5 < string Script = "RenderColorTarget0 = Spin;"; > ExecuteParam (ps_main_I, 3)
   pass P_6 ExecuteParam (ps_main_I, 5)
}

technique Spin_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Delta;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_main_O, 0)
   pass P_3 < string Script = "RenderColorTarget0 = Spin;"; > ExecuteParam (ps_main_O, 1)
   pass P_4 < string Script = "RenderColorTarget0 = Title;"; > ExecuteParam (ps_main_O, 2)
   pass P_5 < string Script = "RenderColorTarget0 = Spin;"; > ExecuteParam (ps_main_O, 3)
   pass P_6 ExecuteParam (ps_main_O, 4)
}

