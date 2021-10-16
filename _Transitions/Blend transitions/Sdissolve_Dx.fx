// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Scurve_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dissolve_S.mp4

/**
 This is essentially the same as Lightworks' dissolve, with a trigonometric curve applied
 to the "Amount" parameter.  If you need to you can vary the linearity of the curve.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sdissolve_Dx.fx
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
   string Description = "S dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Dissolve using either a trigonometric or a quadratic curve";
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

int SetTechnique
<
   string Description = "Curve type";
   string Enum = "Trigonometric,Quadratic";
> = 0;

float Curve
<
   string Description = "Curve amount";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_trig_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Curve < 0.0 ? Curve * 0.6666666667 : Curve;

   float4 Bgnd = GetPixel (s_Background, uv2);

   amount = lerp (Amount, 1.0 - amount, curve);

   return lerp (GetPixel (s_Foreground, uv1), Bgnd, amount);
}

float4 ps_power_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float amount = 1.0 - abs ((Amount * 2.0) - 1.0);
   float curve  = abs (Curve);

   float4 Bgnd = GetPixel (s_Background, uv2);

   amount = Curve < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
   amount = Amount < 0.5 ? amount : 2.0 - amount;
   amount = lerp (Amount, amount * 0.5, curve);

   return lerp (GetPixel (s_Foreground, uv1), Bgnd, amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sdissolve_Dx_trig
{
   pass P_1 ExecuteShader (ps_trig_main)
}

technique Sdissolve_Dx_power
{
   pass P_1 ExecuteShader (ps_power_main)
}

