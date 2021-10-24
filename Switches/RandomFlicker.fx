// @Maintainer jwrl
// @Released 2021-10-24
// @Author jwrl
// @Created 2021-10-24
// @see https://www.lwks.com/media/kunena/attachments/6375/RandomSwitch_640.png

/**
 This effect is a pseudo random switch between two inputs.  It can compile and run under
 Lightworks version 14.0 and earlier, and with slightly different and more stable control
 under version 14.5 and up.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RandomFlicker.fx
//
// Version history:
//
// Rewrite 2021-10-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Random flicker";
   string Category    = "User";
   string SubCategory = "Switches";
   string Notes       = "Does a pseudo random switch between two inputs.";
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

float _Progress;
float _LengthFrames = 750.0;

#define OFFS_1  1.8571428571
#define OFFS_2  1.3076923077

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (In1, s_Input_1);
DefineInput (In2, s_Input_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Speed
<
   string Group = "Switch settings";
   string Description = "Speed";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Random
<
   string Group = "Switch settings";
   string Description = "Randomness";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-------------------------------------------------------------------------------------//
// Shaders
//-------------------------------------------------------------------------------------//

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float freq = floor ((_LengthFrames * _Progress) + 0.5) * max (Speed, 0.01) * 19.0;
   float frq1 = max (0.5, Random + 0.5);
   float frq2 = pow (frq1, 3.0) * freq * OFFS_2;

   frq1 *= freq * OFFS_1;

   float strobe = max (sin (freq) + sin (frq1) + sin (frq2), 0.0);

   float4 Bgnd = GetPixel (s_Input_2, uv2);

   return strobe == 0.0 ? lerp (Bgnd, GetPixel (s_Input_1, uv1), Opacity) : Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique RandomFlicker { pass P_1 ExecuteShader (ps_main) }

