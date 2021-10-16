// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Optical_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Optical.mp4

/**
 A transition that simulates the burn effect of the classic film optical.  Titles or any
 other keyed components are separated from the background with a delta key before executing
 the transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Optical_Kx.fx
//
// Version history:
//
// Built 2021-07-24 jwrl.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Optical dissolve (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then simulates the burn effect of the classic film optical title";
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

#define PI 3.1415926536

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

   float amount  = 1.0 - Amount;
   float alpha   = Fgnd.a;
   float cAmount = sin (amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (amount * PI)) / 2.0;

   float4 Key = lerp (min (Fgnd, Bgnd), Bgnd, amount);

   Fgnd = lerp (Fgnd, min (Fgnd, Bgnd), amount);
   Key  = lerp (Fgnd, Key, aAmount);

   cAmount += 1.0;

   return lerp (Bgnd, saturate ((Key * cAmount) - bAmount.xxxx), alpha);
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

   float amount  = 1.0 - Amount;
   float alpha   = Fgnd.a;
   float cAmount = sin (amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (amount * PI)) / 2.0;

   float4 Key = lerp (min (Fgnd, Bgnd), Bgnd, amount);

   Fgnd = lerp (Fgnd, min (Fgnd, Bgnd), amount);
   Key  = lerp (Fgnd, Key, aAmount);

   cAmount += 1.0;

   return lerp (Bgnd, saturate ((Key * cAmount) - bAmount.xxxx), alpha);
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

   float alpha   = Fgnd.a;
   float cAmount = sin (Amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (Amount * PI)) / 2.0;

   float4 Key = lerp (min (Fgnd, Bgnd), Bgnd, Amount);

   Fgnd = lerp (Fgnd, min (Fgnd, Bgnd), Amount);
   Key  = lerp (Fgnd, Key, aAmount);

   cAmount += 1.0;

   return lerp (Bgnd, saturate ((Key * cAmount) - bAmount.xxxx), alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Optical_Kx_F
{
   pass P_1 ExecuteShader (ps_main_F)
}

technique Optical_Kx_I
{
   pass P_1 ExecuteShader (ps_main_I)
}

technique Optical_Kx_O
{
   pass P_1 ExecuteShader (ps_main_O)
}

