// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalFade_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/OpticalFade.mp4

/**
 This simulates the look of the classic film optical fade to or from black.  It applies
 an exposure shift and a degree of black crush to the transition the way that the early
 optical printers did.  It isn't a transition, and requires one input only.  It must be
 applied in the same way as a title effect, i.e., by marking the region that the fade is
 to occupy.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OpticalFades.fx
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
   string Description = "Optical fades";
   string Category    = "Mix";
   string SubCategory = "Fades and non mixes";
   string Notes       = "Simulates the black crush effect of a film optical fade to or from black";
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
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 video = GetPixel (s_Input, uv);

   float level = Type ? Amount : 1.0 - Amount;
   float alpha = max (video.a, level);

   float3 retval = pow (video.rgb, 1.0 + (level * 0.25));

   retval = lerp (retval, BLACK, level * 0.8);
   retval = saturate (retval - (level * 0.2).xxx);

   return float4 (retval, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique OpticalFades
{
   pass P_1 ExecuteShader (ps_main)
}

