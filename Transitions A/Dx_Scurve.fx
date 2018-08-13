// @Maintainer jwrl
// @Released 2018-08-13
// @Author jwrl
// @Created 2017-03-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Scurve_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dissolve_S.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_Scurve.fx
//
// This is essentially the same as Editshare's "Mix", with a trigonometric curve
// applied to the "Amount" parameter.  If you need to you can vary the linearity of
// the curve.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Update August 10 2017 by jwrl.
// Renamed from S_mix.fx for consistency across the dissolve range.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 13 August 2018 jwrl.
// Added quadratic (power) curve option to the trigonometric one.
// Changed the linearity adjustment to a curve amount adjustment.
// Added support for inverse curves by allowing negative values of curve amount.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "S dissolve";
   string Category    = "Mix";
   string SubCategory = "User Effects";
   string Notes       = "Dissolve using either a trigonometric or a quadratic curve";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;             // Outgoing
texture Bg;             // Incoming

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Curve type";
   string Enum = "Trigonometric,Quadratic";
> = 0;

float Curve
<
   string Description = "Curve amount";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_trig_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Curve < 0.0 ? Curve * 0.6666666667 : Curve;

   float4 Bgnd = tex2D (s_Background, xy2);

   amount = lerp (Amount, 1.0 - amount, curve);

   return lerp (tex2D (s_Foreground, xy1), Bgnd, amount);
}

float4 ps_power_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float amount = 1.0 - abs ((Amount * 2.0) - 1.0);
   float curve  = abs (Curve);

   float4 Bgnd = tex2D (s_Background, xy2);

   amount = Curve < 0.0 ? pow (amount, 0.5) : pow (amount, 3.0);
   amount = Amount < 0.5 ? amount : 2.0 - amount;
   amount = lerp (Amount, amount * 0.5, curve);

   return lerp (tex2D (s_Foreground, xy1), Bgnd, amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sdissolve_trig
{
   pass P_1
   { PixelShader = compile PROFILE ps_trig_main (); }
}

technique Sdissolve_power
{
   pass P_1
   { PixelShader = compile PROFILE ps_power_main (); }
}
