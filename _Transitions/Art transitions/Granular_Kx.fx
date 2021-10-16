// @Maintainer jwrl
// @Released 2021-08-29
// @Author jwrl
// @Created 2021-08-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Granular_DX_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/GranularDissolve.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Granular.mp4

/**
 This effect uses a granular noise driven pattern to transition into or out of an alpha
 or delta key.  The noise component is based on work by users khaver and windsturm.  The
 radial gradient part is from an effect provided by LWKS Software Ltd.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Granulate_Kx.fx
//
// This effect is a rebuild of two previous effects, Granular_Ax and Granular_Adx.
//
// Version history:
//
// Rewrite 2021-08-29 jwrl.
// Rewrite of the original to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Granular dissolve (keyed)";
   string Category    = "Mix";
   string SubCategory = "Art transitions";
   string Notes       = "Uses a granular noise driven pattern to transition into or out of the foreground";
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

#define B_SCALE 0.000545
#define SQRT_2  1.4142135624

// Pascal's triangle magic numbers for blur

float _pascal [] = { 0.3125, 0.2344, 0.09375, 0.01563 };

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);
DefineTarget (Buffer_1, s_Buffer_1);
DefineTarget (Buffer_2, s_Buffer_2);

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
   string Enum = "At start if delta key folded,At start of effect,At end of effect";
> = 1;

int SetTechnique
<
   string Description = "Transition type";
   string Enum = "Top to bottom,Left to right,Radial,No gradient";
> = 1;

bool TransDir
<
   string Description = "Invert transition direction";
> = false;

float gWidth
<
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool TransVar
<
   string Group = "Particles";
   string Description = "Static pattern";
> = false;

bool Sparkles
<
   string Group = "Particles";
   string Description = "Sparkles";
> = true;

float pSize
<
   string Group = "Particles";
   string Description = "Size";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 5.5;

float pSoftness
<
   string Group = "Particles";
   string Description = "Softness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 starColour
<
   string Group = "Particles";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 0.0, 1.0 };

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
   float4 Bgnd, Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = GetPixel (s_Background, uv2);
      }
      else Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_noise (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = saturate (uv + float2 (0.00013, 0.00123));

   float seed = (TransVar) ? 0.0 : Amount;
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + rndval * 1000;

   return saturate (frac (fmod (rndval, 17) * fmod (rndval, 94)) * 3).xxxx;
}

float4 ps_blur_1 (float2 uv : TEXCOORD3) : COLOR
{
   float2 offset_X1 = float2 (pSoftness * B_SCALE, 0.0);
   float2 offset_X2 = offset_X1 * 2.0;
   float2 offset_X3 = offset_X1 * 3.0;

   float4 retval = tex2D (s_Buffer_1, uv) * _pascal [0];

   retval += tex2D (s_Buffer_1, uv + offset_X1) * _pascal [1];
   retval += tex2D (s_Buffer_1, uv - offset_X1) * _pascal [1];
   retval += tex2D (s_Buffer_1, uv + offset_X2) * _pascal [2];
   retval += tex2D (s_Buffer_1, uv - offset_X2) * _pascal [2];
   retval += tex2D (s_Buffer_1, uv + offset_X3) * _pascal [3];
   retval += tex2D (s_Buffer_1, uv - offset_X3) * _pascal [3];

   return retval;
}

float4 ps_blur_2 (float2 uv : TEXCOORD3) : COLOR
{
   float2 offset_Y1 = float2 (0.0, pSoftness * _OutputAspectRatio * B_SCALE);
   float2 offset_Y2 = offset_Y1 * 2.0;
   float2 offset_Y3 = offset_Y1 * 3.0;

   float4 retval = tex2D (s_Buffer_2, uv) * _pascal [0];

   retval += tex2D (s_Buffer_2, uv + offset_Y1) * _pascal [1];
   retval += tex2D (s_Buffer_2, uv - offset_Y1) * _pascal [1];
   retval += tex2D (s_Buffer_2, uv + offset_Y2) * _pascal [2];
   retval += tex2D (s_Buffer_2, uv - offset_Y2) * _pascal [2];
   retval += tex2D (s_Buffer_2, uv + offset_Y3) * _pascal [3];
   retval += tex2D (s_Buffer_2, uv - offset_Y3) * _pascal [3];

   return retval;
}

float4 ps_vertical (float2 uv : TEXCOORD3) : COLOR
{
   float retval = TransDir ? smoothstep (0.0, 1.0, 1.0 - uv.y) : smoothstep (0.0, 1.0, uv.y);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 ps_horizontal (float2 uv : TEXCOORD3) : COLOR
{
   float retval = TransDir ? smoothstep (0.0, 1.0, 1.0 - uv.x) : smoothstep (0.0, 1.0, uv.x);

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 ps_radial (float2 uv : TEXCOORD3) : COLOR
{
   float retval = abs (distance (uv, 0.5.xx)) * SQRT_2;

   if (TransDir) retval = 1.0 - retval;

   retval = saturate ((5.0 * (((1.2 - gWidth) * retval) - ((1.0 - gWidth) * Amount))) + ((0.5 - Amount) * 2.0));

   return retval.xxxx;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float noise  = tex2D (s_Buffer_1, ((uv3 - 0.5) / pSize) + 0.5).x;
   float grad   = tex2D (s_Buffer_2, uv3).x;
   float amount = saturate (((0.5 - grad) * 2.0) + noise);

   float4 Fgnd = tex2D (s_Super, uv3);
   float4 retval = (Ttype == 0) ? lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a * amount)
                 : (Ttype == 1) ? lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * amount)
                                : lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * (1.0 - amount));
   if (Sparkles) {
      amount = 0.5 - abs (amount - 0.5);

      float stars = saturate ((pow (amount, 3.0) * 4.0) + amount);

      retval = lerp (retval, starColour, stars * Fgnd.a);
   }

   return retval;
}

float4 ps_flat (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float noise  = tex2D (s_Buffer_1, ((uv3 - 0.5) / pSize) + 0.5).x;
   float amount = saturate (((Amount - 0.5) * 2.0) + noise);

   float4 Fgnd = tex2D (s_Super, uv3);
   float4 retval = (Ttype == 0) ? lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a * amount)
                 : (Ttype == 1) ? lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * amount)
                                : lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a * (1.0 - amount));
   if (Sparkles) {
      amount = 0.5 - abs (amount - 0.5);

      float stars = saturate ((pow (amount, 3.0) * 4.0) + amount);

      retval = lerp (retval, starColour, stars * Fgnd.a);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Granulate_Kx_Vert
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_blur_1)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_blur_2)
   pass P_5 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_vertical)
   pass P_6 ExecuteShader (ps_main)
}

technique Granulate_Kx_Horiz
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_blur_1)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_blur_2)
   pass P_5 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_horizontal)
   pass P_6 ExecuteShader (ps_main)
}

technique Granulate_Kx_Radial
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_blur_1)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_blur_2)
   pass P_5 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_radial)
   pass P_6 ExecuteShader (ps_main)
}

technique Granulate_Kx_Flat
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_noise)
   pass P_3 < string Script = "RenderColorTarget0 = Buffer_2;"; > ExecuteShader (ps_blur_1)
   pass P_4 < string Script = "RenderColorTarget0 = Buffer_1;"; > ExecuteShader (ps_blur_2)
   pass P_5 ExecuteShader (ps_flat)
}

