// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2017-09-09
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_rPinch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_xPinch.mp4

/**
This effect pinches the outgoing video to a user-defined point to reveal the incoming
shot.  It can also reverse the process to bring in the incoming video.  Unlike "Pinch",
this version compresses to the diagonal radii of the images.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect rPinch_Dx.fx
//
// Version 14.5 update 24 March 2018 by jwrl.
// Legality checking has been added to correct for a bug in XY sampler addressing on
// Linux and OS-X platforms.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Radial pinch";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Radially pinches the outgoing video to a user-defined point to reveal the incoming shot";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Pinch to reveal,Expand to reveal";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MID_PT  (0.5).xx

#define HALF_PI 1.5707963

#define EMPTY   (0.0).xxxx

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = Amount / 2.14;

   float rfrnc = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 outgoing = fn_illegal (xy) ? EMPTY : tex2D (s_Foreground, xy);

   return lerp (tex2D (s_Background, uv), outgoing, outgoing.a);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = (1.0 - Amount) / 2.14;

   float rfrnc = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 incoming = fn_illegal (xy) ? EMPTY : tex2D (s_Background, xy);

   return lerp (tex2D (s_Foreground, uv), incoming, incoming.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Dx_rPinch_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Dx_rPinch_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2 (); }
}
