// @Maintainer jwrl
// @Released 2018-09-27
// @Author jwrl
// @OriginalAuthor "Avery Lee"
// @Created 2017-05-08
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmFX_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmFx.fx
//
// Source credit:
// http://www.loadusfx.net/virtualdub/filmfxguide.htm.  Translated to be compatible with
// lightworks effects by ramana with help from khaver.
//
// Film shader (Softlightx2 Version) for video to be used in Avery Lee's Virtualdub GPU
// Shader filter. v1.6 - 2008(c) Jukka Korhonen from the original code by Avery Lee.
//
// This version by Lightworks user jwrl May 8, 2017.
// It has been rewritten from the ground up for cross-platform compliance.  The effect
// now compiles and runs under ps_2_b constraints, rather than the original requirement
// to use ps_3_0.
//
// The major changes have been to simplify the mathematical expressions, thus reducing
// the number of variables that were required considerably.  This has as a bonus the
// effect of improving the efficiency of the code.  Because of that this has in turn
// permitted a revision to the user interface, allowing percentage ranges to be used
// for the RGBY curves and the Linearization and Fade parameters.
//
// Because this has been such a major rewrite it has been rigorously cross-checked for
// consistency with the original effect.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 27 September 2018 jwrl.
// Added notes to header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "FilmFX";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
   string Notes       = "Simulates a range of colour film processing lab operations";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InpSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float RedCurve
<
   string Group = "Curves";
   string Description = "Red";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float GreenCurve
<
   string Group = "Curves";
   string Description = "Green";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BlueCurve
<
   string Group = "Curves";
   string Description = "Blue";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float BaseCurve
<
   string Group = "Curves";
   string Description = "Base";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float EffectGammaR
<
   string Group = "Gamma";
   string Description = "Red";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 1.0;

float EffectGammaG
<
   string Group = "Gamma";
   string Description = "Green";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 1.0;

float EffectGammaB
<
   string Group = "Gamma";
   string Description = "Blue";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 1.0;

float BaseGamma
<
   string Group = "Gamma";
   string Description = "Base";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 2.2;

float EffectGamma
<
   string Group = "Master effect";
   string Description = "Gamma";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 2.5;

float Fade
<
   string Group = "Master effect";
   string Description = "Fade";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3;

float Linearization
<
   string Group = "Master effect";
   string Description = "Linearization";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Contrast
<
   string Group = "Master effect";
   string Description = "Contrast";
   float MinVal = 0.6;
   float MaxVal = 1.0;
> = 1.0;

float Saturation
<
   string Group = "Master effect";
   string Description = "Saturation";
   float MinVal = -0.25;
   float MaxVal = 0.25;
> = 0.0;

float Bleach
<
   string Group = "Master effect";
   string Description = "Bleach";
   float MinVal = 0;
   float MaxVal = 1.0;
> = 0.0;

float Strength
<
   string Group = "Master effect";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float linVal = (Linearization * 1.5) + 1.0;
   float curve, X, Y, Z;

   float4 Inp    = tex2D (InpSampler, uv);
   float4 retval = float4 (lerp (0.01.xxx, pow (Inp.rgb, linVal), Contrast), Inp.a);

   Inp.rgb = pow (retval.rgb, 1.0 / BaseGamma);

   float3 luma = dot ((1.0 / 3.0).xxx, retval.rgb).xxx;

   curve  = (RedCurve * 9.0) + 1.0;
   X      = 1.0 / (1.0 + exp (curve / 2.0));
   luma.r = (1.0 / (1.0 + exp (curve * (0.5 - luma.b))) - X) / (1.0 - 2.0 * X);

   curve  = (GreenCurve * 9.0) + 1.0;
   X      = 1.0 / (1.0 + exp (curve / 2.0));
   luma.g = (1.0 / (1.0 + exp (curve * (0.5 - luma.b))) - X) / (1.0 - 2.0 * X);

   curve  = (BlueCurve * 9.0) + 1.0;
   X      = 1.0 / (1.0 + exp (curve / 2.0));
   luma.b = (1.0 / (1.0 + exp (curve * (0.5 - luma.b))) - X) / (1.0 - 2.0 * X);

   luma = pow (luma, 1.0 / EffectGamma);
   luma = lerp (luma, 1.0.xxx - luma, Bleach);

   luma.r = (2.0 * pow (luma.r, 1.0 / EffectGammaR)) - 1.0;
   luma.g = (2.0 * pow (luma.g, 1.0 / EffectGammaG)) - 1.0;
   luma.b = (2.0 * pow (luma.b, 1.0 / EffectGammaB)) - 1.0;

   retval.r = (luma.r < 0.0) ? Inp.r * (luma.r * (1.0 - Inp.r) + 1.0) : luma.r * (sqrt (Inp.r) - Inp.r) + Inp.r;
   retval.g = (luma.g < 0.0) ? Inp.g * (luma.g * (1.0 - Inp.g) + 1.0) : luma.g * (sqrt (Inp.g) - Inp.g) + Inp.g;
   retval.b = (luma.b < 0.0) ? Inp.b * (luma.b * (1.0 - Inp.b) + 1.0) : luma.b * (sqrt (Inp.b) - Inp.b) + Inp.b;

   retval = lerp (Inp, retval, Strength);

   curve  = (BaseCurve * 9.0) + 1.0;
   X      = 1.0 / (1.0 + exp (curve / 2.0));
   retval = (1.0.xxxx / (1.0.xxxx + exp (curve.xxxx * (0.5.xxxx - retval))) - X.xxxx) / (1.0 - 2.0 * X).xxxx;

   X = Saturation * (retval.g + retval.b - retval.r);
   Y = Saturation * retval.r;
   Z = ((Fade / 2.0) + Saturation) * (retval.g - retval.b);

   retval.r += X;
   retval.g += Y - Z;
   retval.b += Y + Z;

   Y = (2.0 * dot ((1.0 / 3.0).xxx, retval.rgb)) - 1.0;

   float4 temp = (Y < 0.0) ? retval * (Y.xxxx * (1.0.xxxx - retval) + 1.0.xxxx)
                           : Y.xxxx * (sqrt (retval) - retval) + retval;

   retval   = pow (temp, 1.0 / linVal);
   retval.a = Inp.a;

   return lerp (Inp, retval, Strength);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
