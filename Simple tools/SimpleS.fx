// @Maintainer jwrl
// @Released 2020-09-29
// @Author jwrl
// @Created 2020-04-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Simple_S_640.png

/**
 This effect allows the user to apply an S-curve correction to red, green and blue video
 components and to the luminance.  You can achieve some very dramatic visual results with
 it that are hard to get by other means.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleS.fx
//
// Version history:
//
// Modified jwrl 2020-09-29
// Clamped video levels on entry to and exit from the effect.  Floating point processing
// can result in video level overrun which can impact exports poorly.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple S curve";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "This applies an S curve to the video levels to give an image that extra zing";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Mix amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float CurveY
<
   string Description = "Luma curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CurveR
<
   string Group = "RGB components";
   string Description = "Red curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CurveG
<
   string Group = "RGB components";
   string Description = "Green curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float CurveB
<
   string Group = "RGB components";
   string Description = "Blue curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// If the input video is less than 0.5 this function will double it and raise it to
// the power of the value in curve, then halve it.  If it is greater than 0.5 it will
// invert it then double and raise it to the power of the curve before inverting and
// halving it again.  This will give an S curve when the two components are combined.

float fn_s_curve (float video, float curve)
{
   return (video > 0.5) ? 1.0 - (pow (2.0 - video - video, curve) * 0.5)
                        : pow (video + video, curve) * 0.5;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 inp = saturate (tex2D (s_Input, uv)); // Recover the video source
   float4 retval = inp;                         // Only really needs inp.a

   // Now load a float3 variable with double the Y curve and offset it
   // by 1 to give us a range from 1 to 3, limited to a minimum of 1.

   float3 curves = (max (CurveY + CurveY, 0.0) + 1.0).xxx;

   // Add to the luminance curves the doubled and limited RGB values.
   // This means that each curve value will now range between 1 and 6.

   curves += max (float3 (CurveR, CurveG, CurveB) * 2.0, 0.0.xxx);

   // Now place the individual S-curve modified RGB channels into retval

   retval.r = fn_s_curve (inp.r, curves.r);
   retval.g = fn_s_curve (inp.g, curves.g);
   retval.b = fn_s_curve (inp.b, curves.b);

   // Return the processed video, mixing it back with the input video

   return lerp (inp, saturate (retval), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SimpleS
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
