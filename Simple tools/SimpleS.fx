// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/Simple_S_640.png

/**
 This effect allows the user to apply an S-curve correction to red, green and blue video
 components and to the luminance.  You can achieve some very dramatic visual results with
 it that are hard to get by other means.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleS.fx
//
// Version history:
//
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple S curve";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "This applies an S curve to the video levels to give an image that extra zing";
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
/**
 If V is less than 0.5 this macro will double it and raise it to the power P, then
 halve it.  If it is greater than 0.5 it will invert it then double and raise it to
 the power of P before inverting and halving it again.  This applies an S curve to V
 when the two components are combined.
*/
#define S_curve(V,P) (V > 0.5 ? 1.0 - (pow (2.0 - V - V, P) * 0.5) : pow (V + V, P) * 0.5)

//-----------------------------------------------------------------------------------------//
// Input
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Mix amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CurveY
<
   string Description = "Luma curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CurveR
<
   string Group = "RGB components";
   string Description = "Red curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CurveG
<
   string Group = "RGB components";
   string Description = "Green curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CurveB
<
   string Group = "RGB components";
   string Description = "Blue curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float4 inp = saturate (tex2D (s_Input, uv)); // Recover the video source
   float4 retval = inp;                         // Only really needs inp.a at the moment

   // Now load a float3 variable with double the Y curve and offset it
   // by 1 to give us a range from 1 to 3, limited to a minimum of 1.

   float3 curves = (max (CurveY + CurveY, 0.0) + 1.0).xxx;

   // Add to the luminance curves the doubled and limited RGB values.
   // This means that each curve value will now range between 1 and 6.

   curves += max (float3 (CurveR, CurveG, CurveB) * 2.0, 0.0.xxx);

   // Now place the individual S-curve modified RGB channels into retval

   retval.r = S_curve (inp.r, curves.r);
   retval.g = S_curve (inp.g, curves.g);
   retval.b = S_curve (inp.b, curves.b);

   // Return the processed video, mixing it back with the input video

   return lerp (inp, saturate (retval), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SimpleS { pass P_1 ExecuteShader (ps_main) }

