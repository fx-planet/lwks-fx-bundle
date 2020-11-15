// @Maintainer jwrl
// @Released 2020-11-15
// @Author jwrl
// @Created 2018-08-24
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
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 6 December 2018 jwrl.
// Changed category and subcategory.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2018-08-24
// Corrected the fact that opacity did nothing.  Thanks schrauber for picking that up.
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

#ifdef _LENGTHFRAMES

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

technique RandomFlicker
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
