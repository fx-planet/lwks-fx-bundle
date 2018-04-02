//--------------------------------------------------------------//
// Lightworks user effect Wx_rPinch.fx
// Created by LW user jwrl 9 September 2017.
// @Author: jwrl
// @CreationDate: "9 September 2017"
//
// This effect pinches the outgoing video to a user-defined
// point to reveal the incoming shot.  It can also reverse the
// process to bring in the incoming video.
//
// Unlike "Pinch", this version compresses to the diagonal
// radii of the images.
//
// Version 14.5 update 24 March 2018 by jwrl.
//
// Legality checking has been added to correct for a bug
// in XY sampler addressing on Linux and OS-X platforms.
// This effect should now function correctly when used with
// all current and previous Lightworks versions.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Radial pinch";
   string Category    = "Mix";
   string SubCategory = "Custom wipes";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgdSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgdSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define MID_PT  (0.5).xx

#define HALF_PI 1.5707963

#define EMPTY   (0.0).xxxx

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Functions
//--------------------------------------------------------------//

bool fn_illegal (float2 uv)
{
   return (uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0);
}

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = Amount / 2.14;

   float rfrnc = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 outgoing = fn_illegal (xy) ? EMPTY : tex2D (FgdSampler, xy);

   return lerp (tex2D (BgdSampler, uv), outgoing, outgoing.a);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float progress = (1.0 - Amount) / 2.14;

   float rfrnc = (distance (uv, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 incoming = fn_illegal (xy) ? EMPTY : tex2D (BgdSampler, xy);

   return lerp (tex2D (FgdSampler, uv), incoming, incoming.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique Pinch_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Pinch_2
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2 (); }
}

