// @Maintainer jwrl
// @Released 2021-08-29
// @Author jwrl
// @Author Robert Schütze
// @Created 2021-08-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Fractal_Dx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FractalDissolve.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Fractal.mp4

/**
 This effect uses a fractal-like pattern to transition between two sources.  It supports
 titles and other blended effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fractal_Kx.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Schütze (trirop) 07.12.2015.  This effect is a combination of two earlier effects,
// Fractals_Ax.fx and Fractals_Adx.fx.
//
// Version history:
//
// Rewrite 2021-08-29 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal dissolve (keyed)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Uses a fractal-like pattern to transition between sources and effects";
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

#define DefineTarget(TEXTURE, SAMPLER) \
                                       \
 texture TEXTURE : RenderColorTarget;  \
                                       \
 sampler SAMPLER = sampler_state       \
 {                                     \
   Texture   = <TEXTURE>;              \
   AddressU  = ClampToEdge;            \
   AddressV  = ClampToEdge;            \
   MinFilter = Linear;                 \
   MagFilter = Linear;                 \
   MipFilter = Linear;                 \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);
DefineTarget (Fractal, s_Fractal);

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
   string Enum = "At start if delta key folded,At start of effect,At end of effect";
> = 1;

float fractalOffset
<
   string Group = "Fractal settings";
   string Description = "Offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Rate
<
   string Group = "Fractal settings";
   string Description = "Rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Border
<
   string Group = "Fractal settings";
   string Description = "Edge size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float Feather
<
   string Group = "Fractal settings";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

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

float4 ps_fractal (float2 uv : TEXCOORD0) : COLOR
{
   float3 offset  = float3 (1.0.xx, Amount * Rate * 0.5);
   float3 fractal = float3 (uv.x / _OutputAspectRatio, uv.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - offset)));
   }

   return float4 (saturate (fractal), 1.0);
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Ovly = tex2D (s_Fractal, uv3);
   float4 Fgnd = tex2D (s_Super, uv3);
   float4 Bgnd = GetPixel (s_Foreground, uv1);

   float amount  = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + Feather)) return Bgnd;

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / Feather;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Fgnd : lerp (Fgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Bgnd, fracAmt); }

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Ovly = tex2D (s_Fractal, uv3);
   float4 Fgnd = tex2D (s_Super, uv3);
   float4 Bgnd = GetPixel (s_Background, uv2);

   float amount  = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + Feather)) return Bgnd;

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / Feather;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Fgnd : lerp (Fgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Bgnd, fracAmt); }

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Ovly = tex2D (s_Fractal, uv3);
   float4 Fgnd = tex2D (s_Super, uv3);
   float4 Bgnd = GetPixel (s_Background, uv2);

   float amount = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + Feather)) return GetPixel (s_Foreground, uv1);

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / Feather;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Bgnd : lerp (Bgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Fgnd, fracAmt); }

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Fractal_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Fractal;"; > ExecuteShader (ps_fractal)
   pass P_3 ExecuteShader (ps_main_F)
}

technique Fractal_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Fractal;"; > ExecuteShader (ps_fractal)
   pass P_3 ExecuteShader (ps_main_I)
}

technique Fractal_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Fractal;"; > ExecuteShader (ps_fractal)
   pass P_3 ExecuteShader (ps_main_O)
}

