// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_RGBdrift.mp4

/**
 This transitions a blended foreground image in or out using different curves for each of
 red, green and blue.  One colour and alpha is always linear, and the other two can be set
 using the colour profile selection.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdrifter_Kx.fx
//
// This effect is a combination of two previous effects, RGBdrifter_Ax and
// RGBdrifter_Adx.
//
// Version history:
//
// Rewrite 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB drifter (keyed)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Mixes a blended foreground image in or out using different curves for each of red, green and blue";
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

#define CURVE 4.0

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

int Ttype
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

int SetTechnique
<
   string Description = "Select colour profile";
   string Enum = "Red to blue,Blue to red,Red to green,Green to red,Green to blue,Blue to green"; 
> = 0;

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

float4 ps_main_R_B (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Bgnd   = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   float4 Fgnd   = tex2D (s_Super, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_R (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Bgnd   = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   float4 Fgnd   = tex2D (s_Super, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_R_G (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_G  = pow (amount, CURVE);

   float4 Bgnd   = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   float4 Fgnd   = tex2D (s_Super, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_R (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_G  = pow (1.0 - amount, CURVE);

   float4 Bgnd   = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   float4 Fgnd   = tex2D (s_Super, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_G_B (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_G  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Bgnd   = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   float4 Fgnd   = tex2D (s_Super, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_B_G (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_G  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Bgnd   = (Ttype == 0) ? GetPixel (s_Foreground, uv1) : GetPixel (s_Background, uv2);
   float4 Fgnd   = tex2D (s_Super, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique RGBdrifter_Kx_R_B
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_R_B)
}

technique RGBdrifter_Kx_B_R
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_B_R)
}

technique RGBdrifter_Kx_R_G
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_R_G)
}

technique RGBdrifter_Kx_G_R
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_G_R)
}

technique RGBdrifter_Kx_G_B
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_G_B)
}

technique RGBdrifter_Kx_B_G
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_B_G)
}

