// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Sizzler_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SizzlerDx.mp4

/**
 This effect dissolves through a complex colour translation while performing what is
 essentially a non-additive mix.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSizzler_Dx.fx
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
   string Description = "Colour sizzler";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Dissolves through a complex colour translation from one clip to another";
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

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd   = GetPixel (s_Foreground, uv1);
   float4 Bgnd   = GetPixel (s_Background, uv2);
   float4 nonAdd = max (Fgnd * min (1.0, 2.0 * (1.0 - Amount)), Bgnd * min (1.0, 2.0 * Amount));
   float4 premix = max (Fgnd, Bgnd);

   float Alpha = premix.w;
   float Luma  = 0.1 + (0.5 * premix.x);
   float Satn  = premix.y * Saturation;
   float Hue   = frac (premix.z + (Amount * HueCycle));
   float LumX3 = 3.0 * Luma;

   float HueX3 = 3.0 * Hue;
   float Hfac  = (floor (HueX3) + 0.5) / 3.0;

   Hue = SQRT_3 * tan ((Hue - Hfac) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   float4 retval = (HueX3 < 1.0) ? float4 (Green, Blue, Red, Alpha)
                 : (HueX3 < 2.0) ? float4 (Red, Green, Blue, Alpha)
                                 : float4 (Blue, Red, Green, Alpha);

   float mixval = abs (2.0 * (0.5 - Amount));

   mixval *= mixval;

   return lerp (retval, nonAdd, mixval);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_ColourSizzler { pass P_1 ExecuteShader (ps_main) }

