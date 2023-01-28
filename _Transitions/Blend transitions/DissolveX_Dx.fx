// @Maintainer jwrl
// @Released 2023-01-28
// @Author khaver
// @Created 2014-08-28

/**
 This expanded dissolve allows optional blend modes to be applied during the transition
 by adding a drop down menu to select different dissolve methods.  A timing slider has
 also been added that adjusts where the 50% mix point happens in the dissolve (slider
 to the left and the 50% mix point happens before the mid-point of the dissolve, slider
 to the right and it happens after the mid-point), a layer swap option (some dissolve
 methods are affected by which layer is on top or bottom), and a bypass option.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DissolveX_Dx.fx
//
// Version history:
//
// Updated 2023-01-28 jwrl.
// Updated to provide LW 2022 revised cross platform support.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("DissolveX", "Mix", "Blend transitions", "Allows optional blend modes to be applied during the transition", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Method", kNoGroup, 0, "Default|Add|Subtract|Multiply|Screen|Overlay|Soft Light|Hard Light|Vivid Light|Linear Light|Pin Light|Exclusion|Lighten|Darken|Average|Difference|Negation|Colour|Luminosity|Dodge|Color Burn|Linear Burn|Light Meld|Dark Meld|Reflect");

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Ease, "Timing", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareBoolParam (Swap, "Swap layers", kNoGroup, false);
DeclareBoolParam (Bypass, "Bypass", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float BlendLinearLightf (float base, float blend)
{
   float blendmix = base + (2.0 * blend) - 1.0;

   return blend < 0.5 ? max (blendmix, 0.0) : min (blendmix, 1.0);
}

float BlendOverlayf (float base, float blend)
{ return base < 0.5 ? 2.0 * base * blend : 1.0 - (2.0 * (1.0 - base) * (1.0 - blend)); }

float BlendSoftLightf (float base, float blend)
{ return blend < 0.5 ? (2.0 * base * blend) + (base * base * (1.0 - 2.0 * blend))
                     : (sqrt(base) * (2.0 * blend - 1.0)) + (2.0 * base * (1.0 - blend)); }

float BlendColorDodgef (float base, float blend)
{ return blend == 1.0 ? blend : min (base / (1.0 - blend), 1.0); }

float  BlendColorBurnf (float base, float blend)
{ return blend == 0.0 ? blend : max (1.0 - ((1.0 - base) / blend), 0.0); }

float BlendVividLightf (float base, float blend)
{ return blend < 0.5 ? BlendColorBurnf (base, 2.0 * blend) : BlendColorDodgef (base, 2.0 * (blend - 0.5)); }

float BlendPinLightf (float base, float blend)
{ return blend < 0.5 ? min (base, 2.0 * blend) : max (base, 2.0 * (blend - 0.5)); }

float BlendHardMixf (float base, float blend)
{ return BlendVividLightf (base, blend) < 0.5 ? 0.0 : 1.0; }

float BlendReflectf (float base, float blend)
{ return blend == 1.0 ? blend : min (base * base / (1.0 - blend), 1.0); }

float EaseAmountf (float ease)
{
   float easy;

   if (ease >= 0.0) {
      easy = (ease + 0.5) * 2.0;
      return pow (Amount, easy);
   }

   easy = abs (ease - 0.5) * 2.0;

   return (1.0 - pow (1.0 - Amount, easy)) * 2.0;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Default)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float amo, easy;

   if (Ease >= 0.0) {
      easy = (Ease + 0.5) * 2.0;
      amo = pow (Amount, easy);
   }
   else {
      easy = abs (Ease - 0.5) * 2.0;
      amo = 1.0 - pow (1.0 - Amount, easy);
   }

   return lerp (Fgd, Bgd, amo);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Add)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = min (Fgd + Bgd, 1.0.xxxx);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Subtract)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = max (Fgd + Bgd - 1.0.xxxx, 0.0.xxxx);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Multiply)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = Bgd * Fgd;

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Screen)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = Fgd + Bgd - (Fgd * Bgd);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Overlay)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendOverlayf (Bgd.r, Fgd.r);
      ret.g = BlendOverlayf (Bgd.g, Fgd.g);
      ret.b = BlendOverlayf (Bgd.b, Fgd.b);
      ret.a = BlendOverlayf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendOverlayf (Fgd.r, Bgd.r);
      ret.g = BlendOverlayf (Fgd.g, Bgd.g);
      ret.b = BlendOverlayf (Fgd.b, Bgd.b);
      ret.a = BlendOverlayf (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (SoftLight)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendSoftLightf (Bgd.r, Fgd.r);
      ret.g = BlendSoftLightf (Bgd.g, Fgd.g);
      ret.b = BlendSoftLightf (Bgd.b, Fgd.b);
      ret.a = BlendSoftLightf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendSoftLightf (Fgd.r, Bgd.r);
      ret.g = BlendSoftLightf (Fgd.g, Bgd.g);
      ret.b = BlendSoftLightf (Fgd.b, Bgd.b);
      ret.a = BlendSoftLightf (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Hardlight)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendOverlayf (Bgd.r, Fgd.r);
      ret.g = BlendOverlayf (Bgd.g, Fgd.g);
      ret.b = BlendOverlayf (Bgd.b, Fgd.b);
      ret.a = BlendOverlayf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendOverlayf (Fgd.r, Bgd.r);
      ret.g = BlendOverlayf (Fgd.g, Bgd.g);
      ret.b = BlendOverlayf (Fgd.b, Bgd.b);
      ret.a = BlendOverlayf (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Vividlight)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendVividLightf (Bgd.r, Fgd.r);
      ret.g = BlendVividLightf (Bgd.g, Fgd.g);
      ret.b = BlendVividLightf (Bgd.b, Fgd.b);
      ret.a = BlendVividLightf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendVividLightf (Fgd.r, Bgd.r);
      ret.g = BlendVividLightf (Fgd.g, Bgd.g);
      ret.b = BlendVividLightf (Fgd.b, Bgd.b);
      ret.a = BlendVividLightf (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Linearlight)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendLinearLightf (Bgd.r, Fgd.r);
      ret.g = BlendLinearLightf (Bgd.g, Fgd.g);
      ret.b = BlendLinearLightf (Bgd.b, Fgd.b);
      ret.a = BlendLinearLightf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendLinearLightf (Fgd.r, Bgd.r);
      ret.g = BlendLinearLightf (Fgd.g, Bgd.g);
      ret.b = BlendLinearLightf (Fgd.b, Bgd.b);
      ret.a = BlendLinearLightf (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Pinlight)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendPinLightf (Bgd.r, Fgd.r);
      ret.g = BlendPinLightf (Bgd.g, Fgd.g);
      ret.b = BlendPinLightf (Bgd.b, Fgd.b);
      ret.a = BlendPinLightf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendPinLightf (Fgd.r, Bgd.r);
      ret.g = BlendPinLightf (Fgd.g, Bgd.g);
      ret.b = BlendPinLightf (Fgd.b, Bgd.b);
      ret.a = BlendPinLightf (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Exclusion)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = Fgd + Bgd - (2.0 * Fgd * Bgd);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Lighten)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = max (Fgd, Bgd);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Darken)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = min (Fgd, Bgd);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Average)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = (Fgd + Bgd) / 2.0;

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Difference)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = abs (Fgd - Bgd);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Negation)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = 1.0.xxxx - abs (1.0.xxxx - Fgd - Bgd);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Color)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   float dstY, srcCr, srcCb, YBit;
   float amo = EaseAmountf (Ease);

   // Calc source luminance but use dest colour..

   if (Swap) {
      dstY  = (0.257 * Fgd.r) + (0.504 * Fgd.g) + (0.098 * Fgd.b) + 0.0625;
      srcCr = (0.439 * Bgd.r) - (0.368 * Bgd.g) - (0.071 * Bgd.b) + 0.5;
      srcCb = (-0.148 * Bgd.r) - (0.291 * Bgd.g) + (0.439 * Bgd.b) + 0.5;
   }
   else {
      dstY  = (0.257 * Bgd.r) + (0.504 * Bgd.g) + (0.098 * Bgd.b) + 0.0625;
      srcCr = (0.439 * Fgd.r) - (0.368 * Fgd.g) - (0.071 * Fgd.b) + 0.5;
      srcCb = (-0.148 * Fgd.r) - (0.291 * Fgd.g) + (0.439 * Fgd.b) + 0.5;
   }

   // Convert to RGB..

   YBit = 1.164 * (dstY - 0.0625);
   ret.r = YBit + (1.596 * (srcCr - 0.5));
   ret.g = YBit - (0.813 * (srcCr - 0.5)) - (0.391 * (srcCb - 0.5));
   ret.b = YBit + (2.018 * (srcCb - 0.5));
   ret.a = 1.0;

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Luminosity)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   float amo = EaseAmountf (Ease);
   float srcY, dstCr, dstCb, YBit;

   // Calc source luminance but use dest colour..

   if (Swap) {
      srcY  = (0.257 * Bgd.r) + (0.504 * Bgd.g) + (0.098 * Bgd.b) + 0.0625;
      dstCr = (0.439 * Fgd.r) - (0.368 * Fgd.g) - (0.071 * Fgd.b) + 0.5;
      dstCb = (-0.148 * Fgd.r) - (0.291 * Fgd.g) + (0.439 * Fgd.b) + 0.5;
   }
   else {
      srcY  = (0.257 * Fgd.r) + (0.504 * Fgd.g) + (0.098 * Fgd.b) + 0.0625;
      dstCr = (0.439 * Bgd.r) - (0.368 * Bgd.g) - (0.071 * Bgd.b) + 0.5;
      dstCb = (-0.148 * Bgd.r) - (0.291 * Bgd.g) + (0.439 * Bgd.b) + 0.5;
   }

   // Convert to RGB..

   YBit = 1.164 * (srcY - 0.0625);
   ret.r = YBit + (1.596 * (dstCr - 0.5));
   ret.g = YBit - (0.813 * (dstCr - 0.5)) - (0.391 * (dstCb - 0.5));
   ret.b = YBit + (2.018 * (dstCb - 0.5));
   ret.a = 1.0;

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Dodge)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendColorDodgef (Bgd.r, Fgd.r);
      ret.g = BlendColorDodgef (Bgd.g, Fgd.g);
      ret.b = BlendColorDodgef (Bgd.b, Fgd.b);
      ret.a = BlendColorDodgef (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendColorDodgef (Fgd.r, Bgd.r);
      ret.g = BlendColorDodgef (Fgd.g, Bgd.g);
      ret.b = BlendColorDodgef (Fgd.b, Bgd.b);
      ret.a = BlendColorDodgef (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ColorBurn)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   if (Swap) {
      ret.r = BlendColorBurnf (Bgd.r, Fgd.r);
      ret.g = BlendColorBurnf (Bgd.g, Fgd.g);
      ret.b = BlendColorBurnf (Bgd.b, Fgd.b);
      ret.a = BlendColorBurnf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendColorBurnf (Fgd.r, Bgd.r);
      ret.g = BlendColorBurnf (Fgd.g, Bgd.g);
      ret.b = BlendColorBurnf (Fgd.b, Bgd.b);
      ret.a = BlendColorBurnf (Fgd.a, Bgd.a);
   }

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (LinearBurn)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret = max (Fgd + Bgd - 1.0.xxxx, 0.0.xxxx);

   float amo = EaseAmountf (Ease);

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (LightMeld)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   float amo = EaseAmountf (Ease);

   if (Swap) ret = (((Bgd.r + Bgd.g + Bgd.b) / 3.0) + (amo / 2.0)) > 1.0 ? Bgd : Fgd;
   else ret = (((Fgd.r + Fgd.g + Fgd.b) / 3.0) + (amo / 2.0)) > 1.0 ? Bgd : Fgd;

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (DarkMeld)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   float amo = EaseAmountf (Ease);

   if (Swap) ret = (1.0 - ((Bgd.r + Bgd.g + Bgd.b) / 3.0) + (amo / 2.0)) > 1.0 ? Bgd : Fgd;
   else ret = (1.0 - ((Fgd.r + Fgd.g + Fgd.b) / 3.0) + (amo / 2.0)) > 1.0 ? Bgd : Fgd;

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Reflect)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   if (Bypass) {
      if (Amount < 0.5) return Fgd;
      else return Bgd;
   }

   if (Amount == 0.0) return Fgd;
   if (Amount == 1.0) return Bgd;

   float4 ret;

   float amo = EaseAmountf (Ease);

   if (Swap) {
      ret.r = BlendReflectf (Bgd.r, Fgd.r);
      ret.g = BlendReflectf (Bgd.g, Fgd.g);
      ret.b = BlendReflectf (Bgd.b, Fgd.b);
      ret.a = BlendReflectf (Bgd.a, Fgd.a);
   }
   else {
      ret.r = BlendReflectf (Fgd.r, Bgd.r);
      ret.g = BlendReflectf (Fgd.g, Bgd.g);
      ret.b = BlendReflectf (Fgd.b, Bgd.b);
      ret.a = BlendReflectf (Fgd.a, Bgd.a);
   }

   return amo <= 1.0 ? lerp (Fgd, ret, amo) : lerp (ret, Bgd, amo - 1.0);
}

