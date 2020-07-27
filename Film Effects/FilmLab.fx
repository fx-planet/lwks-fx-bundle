// @Maintainer jwrl
// @Released 2020-07-27
// @Author jwrl
// @Created 2020-07-27
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmLab_640.png

/**
 This applies a range of tweaks to simulate the look of various colour film laboratory
 operations.  While similar to the older Film Fx, it differs in several important ways.
 The first and most important difference is that the previous effect suffered from
 range overflow.  This could result in highlights becoming grey, and colours suffering
 arbitrary shifts of both hue and saturation.  This effect corrects that.

 The next and most obvious difference is in the order of settings.  In some case the name
 of those settings and occasionally even the range differs.  The direction of action of
 Saturation has changed to be more logical.  The Strength setting has been replaced by
 Amount for consistency with standard Lightworks effects.  The Amount settings range from
 0% to 100%, where 0% gives the unmodified video input.  The older effect did not allow
 Strength reduction to do that.

 The full parameter changes from Film Fx are, New > Old:
   Amount > Master effect:Strength - no range difference.
   Video settings:Saturation > Master effect:Saturation runs from 50% - 150%, and not
                               -0.25 to +0.25.  Value increase lifts saturation.
   Video settings:Gamma > Master effect:Gamma - no range difference.
   Video settings:Contrast > Master effect:Contrast - 50% - 150% replaces 0.6 - 1.0.
   Lab operations:Linearity > Master effect:Linearization - no range difference.
   Lab operations:Bleach bypass > Master effect:Bleach - no range difference.
   Lab operations:Film aging > Master effect:Fade - no range difference.
   Preprocessing curves:RGB > Curves:Base 1.0 - 10.0 instead of 0% - 100%
   Preprocessing curves:Red > Curves:Red 1.0 - 10.0 instead of 0% - 100%
   Preprocessing curves:Green > Curves:Green 1.0 - 10.0 instead of 0% - 100%
   Preprocessing curves:Blue > Curves:Blue 1.0 - 10.0 instead of 0% - 100%
   Gamma presets:RGB > Gamma:Base - no range difference.
   Gamma presets:Red > Gamma:Red - no range difference.
   Gamma presets:Green > Gamma:Green - no range difference.
   Gamma presets:Blue > Gamma:Blue - no range difference.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmLab.fx
//
// This is based on ideas from Avery Lee's Virtualdub GPU shader, v1.6 - 2008(c) Jukka
// Korhonen.  However this effect is new code from the ground up.
//
// Version history:
//
// Created 2020-07-28 jwrl.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film lab";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "This is a colour film processing lab for video";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state
{
   Texture   = <Inp>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Saturation
<
   string Group = "Video settiings";
   string Description = "Saturation";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.5;
   float MaxVal = 1.5;
> = 1.0;

float Gamma
<
   string Group = "Video settiings";
   string Description = "Gamma";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 2.5;

float Contrast
<
   string Group = "Video settiings";
   string Description = "Contrast";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.5;
   float MaxVal = 1.5;
> = 1.0;

float Linearity
<
   string Group = "Lab operations";
   string Description = "Linearity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Bypass
<
   string Group = "Lab operations";
   string Description = "Bleach bypass";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Aging
<
   string Group = "Lab operations";
   string Description = "Film aging";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3;

float LumaCurve
<
   string Group = "Preprocessing curves";
   string Description = "RGB";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 1.0;

float RedCurve
<
   string Group = "Preprocessing curves";
   string Description = "Red";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 10.0;

float GreenCurve
<
   string Group = "Preprocessing curves";
   string Description = "Green";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 5.5;

float BlueCurve
<
   string Group = "Preprocessing curves";
   string Description = "Blue";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 1.0;

float LumaGamma
<
   string Group = "Gamma presets";
   string Description = "RGB";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 2.2;

float RedGamma
<
   string Group = "Gamma presets";
   string Description = "Red";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 1.0;

float GreenGamma
<
   string Group = "Gamma presets";
   string Description = "Green";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 1.0;

float BlueGamma
<
   string Group = "Gamma presets";
   string Description = "Blue";
   float MinVal = 0.1;
   float MaxVal = 2.5;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA    float3(0.2989,  0.5866, 0.1145)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   hsv.yz = min (1.0.xx, hsv.yz);

   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float lin = (Linearity * 1.5) + 1.0;

   float4 Inp = saturate (tex2D (s_Input, uv)); // Clamp RGB to limit superwhites in floating point
   float4 lab = lerp (0.01.xxxx, pow (Inp, lin), Contrast);

   float3 print = pow (lab.rgb, 1.0 / LumaGamma);
   float3 grade = dot ((1.0 / 3.0).xxx, lab.rgb).xxx;
   float3 curve = float3 (RedCurve, GreenCurve, BlueCurve);
   float3 bath  = 1.0.xxx / (1.0.xxx + exp (curve / 2.0));

   grade = 0.5.xxx - grade;
   grade = (1.0.xxx / (1.0.xxx + exp (curve * grade)) - bath) / (1.0.xxx - (2.0 * bath));
   grade = pow (grade, 1.0 / Gamma);
   grade = lerp (grade, 1.0.xxx - grade, Bypass);

   grade.x = pow (grade.x, 1.0 / RedGamma);
   grade.y = pow (grade.y, 1.0 / GreenGamma);
   grade.z = pow (grade.z, 1.0 / BlueGamma);

   grade = (2.0 * grade) - 1.0.xxx;

   lab.r = (grade.x < 0.0) ? print.r * (grade.x * (1.0 - print.r) + 1.0)
                           : grade.x * (sqrt (print.r) - print.r) + print.r;
   lab.g = (grade.y < 0.0) ? print.g * (grade.y * (1.0 - print.g) + 1.0)
                           : grade.y * (sqrt (print.g) - print.g) + print.g;
   lab.b = (grade.z < 0.0) ? print.b * (grade.z * (1.0 - print.b) + 1.0)
                           : grade.z * (sqrt (print.b) - print.b) + print.b;

   curve.x = LumaCurve;
   curve.y = 1.0 / (1.0 + exp (LumaCurve / 2.0));
   curve.z  = 1.0 - (2.0 * curve.y);

   grade   = 0.5.xxx - lab.rgb;
   lab.rgb = (1.0.xxx / (1.0.xxx + exp (curve.x * grade)) - curve.yyy) / curve.z;
   lab.gb  = lerp (lab.gb, lab.bg, Aging * 0.495);

   float adjust = dot (2.0.xxx / 3.0, lab.rgb) - 1.0;

   lab = (adjust < 0.0) ? lab * (adjust * (1.0.xxxx - lab) + 1.0.xxxx)
                        : adjust * (sqrt (lab) - lab) + lab;

   grade   = fn_rgb2hsv (lab).rgb;
   grade.y = grade.y * Saturation;
   lab     = fn_hsv2rgb (float4 (grade, Inp.a));

   lab.rgb = pow (lab.rgb, 1.0 / lin);

   return lerp (Inp, lab, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FilmLab
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
