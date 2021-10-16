// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Non_Add_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/NonAddMix.mp4

/**
 This effect emulates the classic analog vision mixer non-add mix.  It uses an algorithm
 that mimics reasonably closely what the electronics used to do.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAdd_Dx.fx
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
   string Description = "Non-additive mix";
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

#define EMPTY 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = lerp (GetPixel (s_Foreground, uv1), EMPTY, Amount);
   float4 Bgnd = lerp (EMPTY, GetPixel (s_Background, uv2), Amount);
   float4 Mix  = max (Bgnd, Fgnd);

   float Gain = (1.0 - abs (Amount - 0.5)) * 2.0;

   return saturate (Mix * Gain);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Dx_NonAdd
{
   pass P_1 ExecuteShader (ps_main)
}

