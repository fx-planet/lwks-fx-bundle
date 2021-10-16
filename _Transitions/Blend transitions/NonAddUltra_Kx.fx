// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_NonAddUltra_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_NonAddUltra.mp4

/**
 This is an extreme non-additive mix for delta (difference) keys.  The incoming key is
 faded in to full value at the 50% point, at which stage the background video starts
 to fade out.  The two images are mixed by giving the source with the maximum level
 priority.  The dissolve out is the reverse of that.

 The result is extreme, but can be interesting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAddUltra_Kx.fx
//
// Version history:
//
// Built 2021-07-24 jwrl.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-add mix ultra (keyed)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "This is an extreme non-additive mix for titles, which are delta keyed from the background";
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

float Linearity
<
   string Description = "Linearity";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

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

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);

   outAmount = lerp (outAmount, pow (outAmount, 3.0), Linearity);
   in_Amount = lerp (in_Amount, pow (in_Amount, 3.0), Linearity);

   Fgnd.rgb = max (Fgnd.rgb * outAmount, Bgnd.rgb * in_Amount);

   return lerp (Bgnd, Fgnd, Fgnd.a);
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

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);

   outAmount = lerp (outAmount, pow (outAmount, 3.0), Linearity);
   in_Amount = lerp (in_Amount, pow (in_Amount, 3.0), Linearity);

   Fgnd.rgb = max (Fgnd.rgb * outAmount, Bgnd.rgb * in_Amount);

   return lerp (Bgnd, Fgnd, Fgnd.a);
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

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);

   outAmount = lerp (outAmount, pow (outAmount, 3.0), Linearity);
   in_Amount = lerp (in_Amount, pow (in_Amount, 3.0), Linearity);

   Fgnd.rgb = max (Bgnd.rgb * outAmount, Fgnd.rgb * in_Amount);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique NonAddUltra_Kx_F
{
   pass P_1 ExecuteShader (ps_main_F)
}

technique NonAddUltra_Kx_I
{
   pass P_1 ExecuteShader (ps_main_I)
}

technique NonAddUltra_Kx_O
{
   pass P_1 ExecuteShader (ps_main_O)
}

