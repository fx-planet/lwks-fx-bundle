// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2020-01-04
// @see https://www.lwks.com/media/kunena/attachments/6375/Vibrance_640.png

/**
 This simple effect just adjusts the colour vibrance.  It does this by selectively  altering
 the saturation levels of the mid tones in the video.  You can probably think of it as a sort
 of gamma adjustment that only works on saturation.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Vibrance.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified jwrl 2020-09-27
// Clamped video levels on exit from the effect.  Floating point processing can result
// in video level overrun which can impact exports poorly.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Vibrance";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "Adjusts the video vibrance.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Vibrance
<
   string Description = "Vibrance";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);

   float amount = pow (1.0 + Vibrance, 2.0) - 1.0;
   float maxval = max (retval.r, max (retval.g, retval.b));
   float vibval = amount * (((retval.r + retval.g + retval.b) / 3.0) - maxval);

   return float4 (saturate (lerp (retval.rgb, maxval.xxx, vibval)), retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Vibrance_fx
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
