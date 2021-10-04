// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Scurve-640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Scurve.mp4

/**
 This is essentially the same as the S dissolve but extended to dissolve alpha and delta
 keys.  A trigonometric curve is applied to the "Amount" parameter and the linearity of
 the curve can be adjusted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sdissolve_Kx.fx
//
// Version history:
//
// Built 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "S dissolve (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then dissolves it with a non-linear profile";
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

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define TRIG    0
#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

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

int CurveType
<
   string Description = "Curve type";
   string Enum = "Trigonometric,Quadratic";
> = 0;

float CurveAmount
<
   string Description = "Curve amount";
   float MinVal = -1.0;
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

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);
   float4 Bgnd = GetPixel (s_Background, uv2);

   if (Source == 0) {
      float4 Key = Bgnd; Bgnd = Fgnd;

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Key.rgb, Bgnd.rgb));
      Fgnd.rgb = Key.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   float amount, curve;

   if (CurveType == TRIG) {
      amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
      curve  = CurveAmount < 0.0 ? CurveAmount * 0.6666666667 : CurveAmount;

      amount = lerp (Amount, 1.0 - amount, curve);
   }
   else {
      amount = 1.0 - abs ((Amount * 2.0) - 1.0);
      curve  = abs (CurveAmount);

      amount = CurveAmount < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
      amount = Amount < 0.5 ? amount : 2.0 - amount;
      amount = lerp (Amount, amount * 0.5, curve);
   }

   return lerp (Bgnd, lerp (Bgnd, Fgnd, amount), Fgnd.a);
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);
   float4 Bgnd = GetPixel (s_Background, uv2);

   if (Source == 0) {
      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   float amount, curve;

   if (CurveType == TRIG) {
      amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
      curve  = CurveAmount < 0.0 ? CurveAmount * 0.6666666667 : CurveAmount;

      amount = lerp (Amount, 1.0 - amount, curve);
   }
   else {
      amount = 1.0 - abs ((Amount * 2.0) - 1.0);
      curve  = abs (CurveAmount);

      amount = CurveAmount < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
      amount = Amount < 0.5 ? amount : 2.0 - amount;
      amount = lerp (Amount, amount * 0.5, curve);
   }

   return lerp (Bgnd, lerp (Bgnd, Fgnd, amount), Fgnd.a);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);
   float4 Bgnd = GetPixel (s_Background, uv2);

   if (Source == 0) {
      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   float amount, curve;

   if (CurveType == TRIG) {
      amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
      curve  = CurveAmount < 0.0 ? CurveAmount * 0.6666666667 : CurveAmount;

      amount = lerp (Amount, 1.0 - amount, curve);
   }
   else {
      amount = 1.0 - abs ((Amount * 2.0) - 1.0);
      curve  = abs (CurveAmount);

      amount = CurveAmount < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
      amount = Amount < 0.5 ? amount : 2.0 - amount;
      amount = lerp (Amount, amount * 0.5, curve);
   }

   return lerp (Bgnd, lerp (Fgnd, Bgnd, amount), Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sdissolve_Kx_F
{
   pass P_1 ExecuteShader (ps_main_F)
}

technique Sdissolve_Kx_I
{
   pass P_1 ExecuteShader (ps_main_I)
}

technique Sdissolve_Kx_O
{
   pass P_1 ExecuteShader (ps_main_O)
}

