// @Maintainer jwrl
// @Released 2020-04-29
// @Author jwrl
// @Created 2020-04-29
// @see https://www.lwks.com/media/kunena/attachments/6375/SimpleS_640.png

/**
 This effect allows the user to apply an S-curve correction to red, green and blue video
 components and to the luminance.  You can achieve some very dramatic visual results with
 it that are hard to get by other means.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleS.fx
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
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

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

float fn_s_curve (float video, float curve)
{
   float Scurve = (2.0 * max (0.0, curve)) + 1.0;

   return (video < 0.5) ?  pow (video * 2.0, Scurve) * 0.5
                        : 1.0 - (pow ((1.0 - video) * 2.0, Scurve) * 0.5);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);
   float4 compnt = retval;

   compnt.r = fn_s_curve (retval.r, CurveR + CurveY);
   compnt.g = fn_s_curve (retval.g, CurveG + CurveY);
   compnt.b = fn_s_curve (retval.b, CurveB + CurveY);

   return lerp (retval, compnt, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique SimpleS
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

