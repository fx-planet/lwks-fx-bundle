// @Maintainer jwrl
// @Released 2018-08-24
// @Author jwrl
// @Created 2018-08-24
// @see https://www.lwks.com/media/kunena/attachments/6375/RandomSwitch_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect RandomSwitch.fx
//
// This effect is a pseudo random switch of two inputs.  It can compile and run under LW
// version 14.0, and with slightly different and more stable control under version 14.5.
//
// Modified jwrl 2018-08-24
// Corrected the fact that opacity did nothing.  Thanks schrauber for picking that up.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Random switch";
   string Category    = "Stylize";
   string SubCategory = "Motion";
   string Notes       = "Does a pseudo random switch between two inputs.";
> = 0;

//-------------------------------------------------------------------------------------//
// Preamble - sets version flag
//-------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define LW_14_5_PLUS
#endif

#ifdef LINUX
#define LW_14_5_PLUS
#endif

#ifdef OSX
#define LW_14_5_PLUS
#endif

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture In1;
texture In2;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input_1 = sampler_state { Texture = <In1>; };
sampler s_Input_2 = sampler_state { Texture = <In2>; };

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

#ifdef LW_14_5_PLUS

float _LengthFrames;

#else

float _LengthFrames = 750.0;

#endif

#define OFFS_1  1.8571428571
#define OFFS_2  1.3076923077

//-------------------------------------------------------------------------------------//
// Shaders
//-------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float freq = floor ((_LengthFrames * _Progress) + 0.5) * max (Speed, 0.01) * 19.0;
   float frq1 = max (0.5, Random + 0.5);
   float frq2 = pow (frq1, 3.0) * freq * OFFS_2;

   frq1 *= freq * OFFS_1;

   bool strobe = max (sin (freq) + sin (frq1) + sin (frq2), 0.0) == 0.0;

   float4 Bgnd = tex2D (s_Input_2, xy2);

   return strobe ? lerp (Bgnd, tex2D (s_Input_1, xy1), Opacity) : Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique RandomSwitch
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
