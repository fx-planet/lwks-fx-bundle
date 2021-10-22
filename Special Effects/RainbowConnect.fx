// @Maintainer jwrl
// @Released 2021-10-22
// @Author jwrl
// @Created 2021-10-22
// @see https://www.lwks.com/media/kunena/attachments/6375/RainbowConnectionA_640.png

/**
 This effect changes tones through a complex colour translation while performing what is
 essentially a non-additive mix.  It can be adjusted to operate over a limited range of the
 input video levels or the full range.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rainbow_Connection.fx
//
// Version history:
//
// Rewrite 2021-10-22 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rainbow connection";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "Changes colours through rainbow patterns according to levels";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define SQRT_3 1.7320508076
#define TWO_PI 6.2831853072

#define H_MIN  0.3333333333
#define H_MAX  0.6666666667

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Saturation
<
   string Group = "Colour settings";
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float HueCycle
<
   string Group = "Colour settings";
   string Description = "Hue cycling";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float LowClip
<
   string Group = "Range settings";
   string Description = "Low clip";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float HighClip
<
   string Group = "Range settings";
   string Description = "High clip";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float Softness
<
   string Group = "Range settings";
   string Description = "Key softness";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd   = GetPixel (s_Input, uv);
   float4 premix = float4 (1.0.xxx - Fgnd.rgb, Fgnd.a);
   float4 nonAdd = max (Fgnd * min (1.0, 2.0 * (1.0 - Amount)), premix * min (1.0, 2.0 * Amount));

   premix.rgb = max (Fgnd.rgb, premix.rgb);

   float Alpha = Fgnd.a;
   float Luma  = 0.1 + (0.5 * premix.r);
   float Satn  = premix.g * Saturation;
   float Hue   = frac (premix.b + (Amount * HueCycle));
   float Hfctr = (floor (3.0 * Hue) + 0.5) / 3.0;

   Hue = SQRT_3 * tan ((Hue - Hfctr) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   float4 retval = (Hue < H_MIN) ? float4 (Green, Blue, Red, Alpha)
                 : (Hue < H_MAX) ? float4 (Red, Green, Blue, Alpha)
                                 : float4 (Blue, Red, Green, Alpha);

   retval = lerp (nonAdd, retval, Amount);
   Luma   = dot (Fgnd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   float edge = max (0.00001, Softness);
   float clip = (LowClip * 1.0002) - (edge * 0.5) - 0.0001;

   Alpha = saturate ((Luma - clip) / edge);
   clip  = (HighClip * 1.0002) - (edge * 0.5) - 0.0001;
   Alpha = min (Alpha, saturate ((clip - Luma) / edge));

   return lerp (Fgnd, retval, Alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Rainbow_Connection { pass P_1 ExecuteShader (ps_main) }

