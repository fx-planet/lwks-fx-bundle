// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Subtract_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SubtractiveDx.mp4

/**
 This is an inverted non-additive mix.  The incoming video is faded from white to normal
 value at the 50% point, at which stage the outgoing video starts to fade to white.  The
 two images are then mixed by giving the source with the lowest level the priority.  The
 result is a subtractive effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Subtract_Dx.fx
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
   string Description = "Subtractive dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "An inverted non-additive mix";
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float outAmount = 1.0 - min (1.0, (1.0 - Amount) * 2.0);
   float in_Amount = 1.0 - min (1.0, Amount * 2.0);

   float4 Fgnd = max (GetPixel (s_Foreground, uv1), outAmount.xxxx);
   float4 Bgnd = max (GetPixel (s_Background, uv2), in_Amount.xxxx);

   return min (Fgnd, Bgnd);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Subtract_Dx
{
   pass P_1 ExecuteShader (ps_main)
}

