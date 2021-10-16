// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldPos_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldPos.mp4

/**
 This effect uses a delta (difference) key to separate the foreground from background then
 transitions by adding the foreground to the background.  The overflowed result is then
 folded back into the legal video range and matted into the background by the delta key.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FoldPos_Kx.fx
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
   string Description = "Folded pos dissolve (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then dissolves them through a positive mix";
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

#define WHITE (1.0).xxxx

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

   float4 retval = WHITE - abs (WHITE - Fgnd - Bgnd);

   float amount = (1.0 - Amount) * 2.0;
   float amt1 = min (amount, 1.0);
   float amt2 = max (amount - 1.0, 0.0);

   retval = lerp (Fgnd, retval, amt1);
   Fgnd.a = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, lerp (retval, Bgnd, amt2), Fgnd.a);
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

   float4 retval = WHITE - abs (WHITE - Fgnd - Bgnd);

   float amount = (1.0 - Amount) * 2.0;
   float amt1 = min (amount, 1.0);
   float amt2 = max (amount - 1.0, 0.0);

   retval = lerp (Fgnd, retval, amt1);
   Fgnd.a = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, lerp (retval, Bgnd, amt2), Fgnd.a);
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

   float4 retval = WHITE - abs (WHITE - Fgnd - Bgnd);

   float amount = Amount * 2.0;
   float amt1 = min (amount, 1.0);
   float amt2 = max (amount - 1.0, 0.0);

   retval = lerp (Fgnd, retval, amt1);
   Fgnd.a = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, lerp (retval, Bgnd, amt2), Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FoldPos_Kx_F
{
   pass P_1 ExecuteShader (ps_main_F)
}

technique FoldPos_Kx_I
{
   pass P_1 ExecuteShader (ps_main_I)
}

technique FoldPos_Kx_O
{
   pass P_1 ExecuteShader (ps_main_O)
}

