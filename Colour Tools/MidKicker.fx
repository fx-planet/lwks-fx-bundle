// @Maintainer jwrl
// @Released 2021-08-18
// @Author jwrl
// @Created 2021-08-18
// @see https://www.lwks.com/media/kunena/attachments/6375/MidtoneKicker_640.png

/**
 This adjusts mid-range red, green and blue levels to enhance or reduce them.  It does
 this by adjusting both mid level contrast and saturation.  To do this it compresses
 or expands the black and white RGB levels to compensate.  Since that means that the
 final look that you achieve will be affected by the black and white levels provision
 has been made to adjust them.  This should be done before doing anything else.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MidtoneKicker.fx
//
// Version history:
//
// Rewrite 2021-08-18 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Midtone kicker";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Adjusts mid-range RGB levels to enhance or reduce them";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Reference
<
   string Description = "Set black & white references and levels first";
> = true;

float4 WhitePoint
<
   string Group = "Reference points";
   string Description = "White";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, -1.0 };

float4 BlackPoint
<
   string Group = "Reference points";
   string Description = "Black";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, -1.0 };

float S_curve
<
   string Group = "Midtone adjustments";
   string Description = "Contrast";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Vibrance
<
   string Group = "Midtone adjustments";
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float WhiteLevel
<
   string Group = "Fine tuning";
   string Description = "White level";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.5;
   float MaxVal = 1.5;
> = 1.0;

float Trim_R
<
   string Group = "Fine tuning";
   string Description = "Red midtones";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Trim_G
<
   string Group = "Fine tuning";
   string Description = "Green midtones";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Trim_B
<
   string Group = "Fine tuning";
   string Description = "Blue midtones";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float BlackLevel
<
   string Group = "Fine tuning";
   string Description = "Black level";
   string Flags = "DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 0.5;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_s_curve (float video, float curve, float level)
{
   float vid = abs (video - 0.5) * 2.0;

   vid = (video > 0.5) ? (1.0 + pow (vid, curve)) * 0.5
                       : (1.0 - pow (vid, curve)) * 0.5;

   return lerp (video, vid, level);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 inp = GetPixel (s_Input, uv);

   if (!Reference) {
      inp.rgb = ((inp.rgb - BlackPoint.rgb) / WhitePoint.rgb);
      inp.rgb = ((inp.rgb * WhiteLevel) + BlackLevel.xxx);
   }

   float3 retval = inp.rgb;

   float vibval = pow (1.0 + Vibrance, 2.0) - 1.0;
   float maxval = max (retval.r, max (retval.g, retval.b));
   float amount, curves;

   if (S_curve < 0.0) {
      amount = abs (S_curve) * 0.6666666666;
      curves = 1.0 / (1.0 + (S_curve * 0.5));
   }
   else {
      amount = S_curve * 1.3333333333;
      curves = 1.0 - (S_curve * 0.5);
   }

   vibval *= ((retval.r + retval.g + retval.b) / 3.0) - maxval;
   retval  = lerp (retval, maxval.xxx, vibval);

   inp.r = lerp (inp.r, fn_s_curve (retval.r, curves, amount), Trim_R + 1.0);
   inp.g = lerp (inp.g, fn_s_curve (retval.g, curves, amount), Trim_G + 1.0);
   inp.b = lerp (inp.b, fn_s_curve (retval.b, curves, amount), Trim_B + 1.0);

   return inp;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique MidtoneKicker
{
   pass P_1 ExecuteShader (ps_main)
}
