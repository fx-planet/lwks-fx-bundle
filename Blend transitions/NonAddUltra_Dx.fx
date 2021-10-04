// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_NonAddUltra_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/NonAddUltraDx.mp4

/**
 This is an extreme non-additive mix.  The incoming video is faded in to full value at
 the 50% point, at which stage the outgoing video starts to fade out.  The two images
 are mixed by giving the source with the maximum level priority.

 The result is extreme, but can be interesting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAddUltra_Dx.fx
//
// Version history:
//
// Built 2021-07-24 jwrl.
// Rewritten to support resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-add mix ultra";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Emulates the classic analog vision mixer non-add mix";
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
// Params
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Linearity
<
   string Description = "Linearity";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float outAmount = min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = min (1.0, Amount * 2.0);
   float temp = outAmount * outAmount * outAmount;

   outAmount = lerp (outAmount, temp, Linearity);
   temp = in_Amount * in_Amount * in_Amount;
   in_Amount = lerp (in_Amount, temp, Linearity);

   float4 Fgnd = GetPixel (s_Foreground, uv1) * outAmount;
   float4 Bgnd = GetPixel (s_Background, uv2) * in_Amount;

   return max (Fgnd, Bgnd);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Dx_NonAddUltra
{
   pass P_1 ExecuteShader (ps_main)
}

