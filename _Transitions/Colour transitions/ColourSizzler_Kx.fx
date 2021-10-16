// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sizzler_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sizzler.mp4

/**
 This effect dissolves a blended foreground image in or out through a complex colour
 translation while performing what is essentially a non-additive mix.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSizzler_Kx.fx
//
// This effect is a combination of two previous effects, ColourSizzler_Ax and
// ColourSizzler_Adx.
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
   string Description = "Colour sizzler (keyed)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Transitions the blended foreground in or out using a complex colour translation";
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

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

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

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float HueCycle
<
   string Description = "Cycle rate";
   float MinVal = 0.0;
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

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = 1.0 - Amount;

   float4 Bgnd = GetPixel (s_Foreground, uv1);
   float4 Fgnd = GetPixel (s_Super, uv3);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - amount)), Bgnd * min (1.0, 2.0 * amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

float4 ps_main_I (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float amount = 1.0 - Amount;

   float4 Bgnd = GetPixel (s_Background, uv2);
   float4 Fgnd = GetPixel (s_Super, uv3);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - amount)), Bgnd * min (1.0, 2.0 * amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

float4 ps_main_O (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Bgnd = GetPixel (s_Background, uv2);
   float4 Fgnd = GetPixel (s_Super, uv3);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - Amount)), Bgnd * min (1.0, 2.0 * Amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (Amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - Amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, Amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourSizzler_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 ExecuteShader (ps_main_F)
}

technique ColourSizzler_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_I)
}

technique ColourSizzler_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 ExecuteShader (ps_main_O)
}

