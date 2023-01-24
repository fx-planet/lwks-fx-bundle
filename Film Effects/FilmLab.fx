// @Maintainer jwrl
// @Released 2023-01-24
// @Author jwrl
// @Created 2023-01-24

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

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmLab.fx
//
// This is based on ideas from Avery Lee's Virtualdub GPU shader, v1.6 - 2008(c) Jukka
// Korhonen.  However this effect is new code from the ground up.
//
// Version history:
//
// Built 2023-01-24 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Film lab", "Colour", "Film Effects", "This is a colour film processing lab for video", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Saturation, "Saturation", "Video settings", "DisplayAsPercentage", 1.0, 0.5, 1.5);
DeclareFloatParam (Gamma, "Gamma", "Video settings", kNoFlags, 1.0, 0.1, 2.5);
DeclareFloatParam (Contrast, "Contrast", "Video settings", "DisplayAsPercentage", 1.0, 0.5, 1.5);

DeclareFloatParam (Linearity, "Linearity", "Lab operations", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bypass, "Bleach bypass", "Lab operations", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ageing, "Film ageing", "Lab operations", kNoFlags, 0.3, 0.0, 1.0);

DeclareFloatParam (LumaCurve, "RGB", "Preprocessing curves", kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (RedCurve, "Red", "Preprocessing curves", kNoFlags, 10.0, 1.0, 10.0);
DeclareFloatParam (GreenCurve, "Green", "Preprocessing curves", kNoFlags, 5.5, 1.0, 10.0);
DeclareFloatParam (BlueCurve, "Blue", "Preprocessing curves", kNoFlags, 1.0, 1.0, 10.0);

DeclareFloatParam (LumaGamma, "RGB", "Gamma presets", kNoFlags, 1.4, 0.1, 2.5);
DeclareFloatParam (RedGamma, "Red", "Gamma presets", kNoFlags, 1.0, 0.1, 2.5);
DeclareFloatParam (GreenGamma, "Green", "Gamma presets", kNoFlags, 1.0, 0.1, 2.5);
DeclareFloatParam (BlueGamma, "Blue", "Gamma presets", kNoFlags, 1.0, 0.1, 2.5);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FilmLab)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float lin = (Linearity * 1.5) + 1.0;

   float4 src = tex2D (Inp, uv1);
   float4 vid = pow (src, 1.0 / Gamma);

   vid.a = src.a;

   float4 lab = lerp (0.01.xxxx, pow (vid, lin), Contrast);

   float3 print = pow (lab.rgb, 1.0 / LumaGamma);
   float3 grade = dot ((1.0 / 3.0).xxx, lab.rgb).xxx;
   float3 flash = float3 (RedCurve, GreenCurve, BlueCurve);
   float3 light = 1.0.xxx / (1.0.xxx + exp (flash / 2.0));

   grade = 0.5.xxx - grade;
   grade = (1.0.xxx / (1.0.xxx + exp (flash * grade)) - light) / (1.0.xxx - (2.0 * light));
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
   flash.x = LumaCurve;
   flash.y = 1.0 / (1.0 + exp (LumaCurve / 2.0));
   flash.z  = 1.0 - (2.0 * flash.y);

   grade   = 0.5.xxx - lab.rgb;
   lab.rgb = (1.0.xxx / (1.0.xxx + exp (flash.x * grade)) - flash.yyy) / flash.z;
   lab.gb  = lerp (lab.gb, lab.bg, Ageing * 0.495);

   float adjust = dot (2.0.xxx / 3.0, lab.rgb) - 1.0;

   lab = (adjust < 0.0) ? lab * (adjust * (1.0.xxxx - lab) + 1.0.xxxx)
                        : adjust * (sqrt (lab) - lab) + lab;
   print = lerp ((lab.r + lab.g + lab.b).xxx / 3.0, lab.rgb, (Saturation - 0.5) * 2.0);
   lab = float4 (pow (print, 1.0 / lin), vid.a);

   vid = lerp (kTransparentBlack, lerp (vid, lab, Amount), src.a);

   return lerp (src, vid, tex2D (Mask, uv1).x);
}

