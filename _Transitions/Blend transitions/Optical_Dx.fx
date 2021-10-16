// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Optical_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalDissolve.mp4

/**
 This is an attempt to simulate the look of the classic film optical dissolve.  To do this
 it applies a non-linear curve to the transition, and at the centre mixes in a stretched
 blend with a touch of black crush.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Optical_Dx.fx
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
   string Description = "Optical dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Simulates the burn effect of a film optical dissolve";
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

#define PI 3.1415926536

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

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float cAmount = sin (Amount * PI) / 4.0;
   float bAmount = cAmount / 2.0;
   float aAmount = (1.0 - cos (Amount * PI)) / 2.0;

   float4 fgPix = GetPixel (s_Foreground, uv1);
   float4 bgPix = GetPixel (s_Background, uv2);
   float4 retval = lerp (min (fgPix, bgPix), bgPix, Amount);

   fgPix = lerp (fgPix, min (fgPix, bgPix), Amount);
   retval = lerp (fgPix, retval, aAmount);

   cAmount += 1.0;

   return saturate ((retval * cAmount) - bAmount.xxxx);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Optical_Dx
{
   pass P_1 ExecuteShader (ps_main)
}

