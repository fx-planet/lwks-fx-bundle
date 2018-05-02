// @Maintainer jwrl
// @Released 2018-05-03
// @Author jwrl
// @Created 2017-05-18
// @see https://www.lwks.com/media/kunena/attachments/6375/QuickLevel_1.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuickLevels.fx
//
// This is a quick video level adjustment tool, similar in many respects to the colour
// correction effects supplied with Lightworks.  It differs in that hue and vibrance
// adjustments have been added.  There is also a master amount adjustment to give more
// control of the effect.  Individual colorimetry controls aren't available because
// that isn't the purpose of this tool.
//
// The parameters are:
//
// Amount           : Allows the grade to be faded in or out.
// Gamma / Exposure : Adjusts the image gamma.
// Brightness       : As used in LW colour correction.
// Contrast         : As used in LW colour correction.
// Gain             : As used in LW colour correction.
// Hue              : Trims the hue by plus or minus 90 degrees.
// Saturation       : Increases or reduces master saturation.
// Vibrance         : Allows mid range saturation to be enhanced.
//
// The gamma parameter differs from Lightworks practice because I wanted it to feel
// more like an exposure adjustment, hence the name.  Reducing the gamma darkens the
// image, the reverse lightens it.  The Brightness, Contrast and Gain parameters on
// the other hand behave in exactly the same way that they do in Lightworks' colour
// correction effects.  The code to implement them is pretty standard, so that isn't
// too surprising.
//
// Hue adjusts the hue through plus or minus 90 degrees, and saturation over the hue
// range remains constant.  The range covered by Saturation is from zero (black and
// white) to 200% saturation.  Adjustment is based on video luminance and not on an RGB
// average, which differs from the Lightworks algorithm.
//
// Vibrance matches the Photoshop effect of the same name quite closely, and has been
// implemented from a widely published algorithm.  At the extreme ends of its adjustment
// range it differs a little from the Photoshop version.  Whether that's due to the
// algorithm or this implementation of it is unclear, but it has been assessed to be
// near enough for the purpose.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Quick video levels";
   string Category    = "Colour";
   string SubCategory = "Technical";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Gamma
<
   string Description = "Gamma / Exposure";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Brightness
<
   string Description = "Brightness";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Contrast
<
   string Description = "Contrast";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Gain
<
   string Description = "Gain";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Hue
<
   string Description = "Hue (degrees)";
   float MinVal = -90.0;
   float MaxVal = 90.0;
> = 0.0;

float Saturation
<
   string Description = "Saturation";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Vibrance
<
   string Description = "Vibrance";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PS 0.0174533
#define SF 0.6213204

float3 _luma_conv = { 0.2989, 0.5866, 0.1145 };

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Input, uv);

   float gamma = 1.0 - (max (0.0, Gamma) * 0.5) - (min (0.0, Gamma) * 0.75);

   Fgnd.rgb = pow (Fgnd.rgb, gamma);

   float3 neg_hue = Fgnd.gbr;
   float3 pos_hue = Fgnd.brg;

   float hue  = clamp (Hue / 160.0, -0.5625, 0.5625);
   float sat  = ((abs (sin (Hue * PS)) * SF) + 1.0) * (Saturation + 1.0) / 2.0;
   float cont = max (0.0, Contrast + 1.0);
   float brt  = max (-1.0, Brightness) + 0.5;
   float gain = max (0.0, Gain + 1.0);

   float3 retval = lerp (lerp (Fgnd.rgb, pos_hue, max (0.0, hue)), neg_hue, abs (min (0.0, hue)));

   float luma = dot (retval, _luma_conv);

   float3 chroma = retval - luma.xxx;

   retval = saturate (lerp (luma.xxx, retval + chroma, sat));

   float vibval = (retval.r + retval.g + retval.b) / 3.0;
   float maxval = max (retval.r, max (retval.g, retval.b));

   vibval   = 6.0 * Vibrance * (vibval - maxval);
   Fgnd.rgb = (((lerp (retval, maxval.xxx, vibval) * gain) - 0.5.xxx) * cont) + brt.xxx;

   return lerp (tex2D (s_Input, uv), saturate (Fgnd), Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuickLevels
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

