// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FoldPos_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DX_FoldPos.mp4

/**
 This transitions between the two inputs by adding one to the other.  The overflowed result
 is then folded back into the legal video range.  Anything above white or below black becomes
 inverted in the process.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FoldPos_Dx.fx
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
   string Description = "Folded pos dissolve";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Dissolves through a positive mix of one image to another";
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

#define WHITE 1.0.xxxx

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
   float4 Fgd = GetPixel (s_Foreground, uv1);
   float4 Bgd = GetPixel (s_Background, uv2);

   float4 retval = 1.0.xxxx - abs (1.0.xxxx - Fgd - Bgd);

   float amt1 = min (Amount * 2.0, 1.0);
   float amt2 = max ((Amount * 2.0 - 1.0), 0.0);

   retval = lerp (Fgd, retval, amt1);

   return lerp (retval, Bgd, amt2);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FoldPos_Dx
{
   pass P_1 ExecuteShader (ps_main)
}

