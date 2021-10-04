// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/FadeUpDown_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FadeUpDown.mp4

/**
 This simple effect fades any video to which it's applied to or from from black.  It
 isn't a standard dissolve, since it requires one input only.  It must be applied in
 the same way as a title effect, i.e., by marking the region that the fade in or out
 is to occupy.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fades.fx
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
   string Description = "Fades";
   string Category    = "Mix";
   string SubCategory = "Fades and non mixes";
   string Notes       = "Fades video to or from black";
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
#define BLACK float2(0.0,1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

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
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Type
<
   string Description = "Fade type";
   string Enum = "Fade up,Fade down";
> = 0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float level = Type ? Amount : 1.0 - Amount;

   return lerp (GetPixel (s_Input, uv), BLACK, level);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Fades
{
   pass P_1 ExecuteShader (ps_main)
}

