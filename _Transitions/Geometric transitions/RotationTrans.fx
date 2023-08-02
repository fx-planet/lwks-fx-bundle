// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2018-06-12

/**
 Transitions between two sources by rotating them horizontally or vertically.  The maths
 used is quite different to that used in the original keyed version that triggered this.
 Non-linearities that at the time were considered quite acceptable were really not.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RotationTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-10 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rotation transition", "Mix", "Geometric transitions", "Rotates a title, image key or other blended foreground in or out", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Rotation axis", "Rotation", 0, "Vertical|Horizontal");
DeclareBoolParam (Reverse, "Swap rotation direction", "Rotation", false);
DeclareFloatParam (Offset, "Z offset", "Rotation", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268
#define PI      3.1415926536
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (!Blended) return float4 ((ReadPixel (F, xy1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (B, xy2);
      Bgnd = ReadPixel (F, xy1);
   }
   else {
      Fgnd = ReadPixel (F, xy1);
      Bgnd = ReadPixel (B, xy2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (F, xy1) : ReadPixel (B, xy2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

bool fn_3Drotate (float2 tl, float2 tr, float2 bl, float2 br, inout float2 uv)
{
   float2 c1 = tr - bl;
   float2 c2 = br - bl;
   float2 c3 = tl - br - c1;

   float d = (c1.x * c2.y) - (c2.x * c1.y);

   float a = ((c3.x * c2.y) - (c2.x * c3.y)) / d;
   float b = ((c1.x * c3.y) - (c3.x * c1.y)) / d;

   c1 += bl - tl + (a * tr);
   c2 += bl - tl + (b * br);
   d   = (c1.x * (c2.y - (b * tl.y))) - (c1.y * (c2.x + (b * tl.x)))
       + (a * ((c2.x * tl.y) - (c2.y * tl.x)));

   float3x3 m = float3x3 (c2.y - (b * tl.y), (a * tl.y) - c1.y, (c1.y * b) - (a * c2.y),
                          (b * tl.x) - c2.x, c1.x - (a * tl.x), (a * c2.x) - (c1.x * b),
                          (c2.x * tl.y) - (c2.y * tl.x), (c1.y * tl.x) - (c1.x * tl.y),
                          (c1.x * c2.y)  - (c1.y * c2.x)) / d;

   float3 xyz = mul (float3 (uv, 1.0), mul (m, float3x3 (1.0, 0.0.xx, -1.0.xx, -2.0, 0.0.xx, 1.0)));

   uv = xyz.xy / xyz.z;

   return (uv.x >= 0.0) && (uv.y >= 0.0) && (uv.x <= 1.0) && (uv.y <= 1.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique RotationTrans_V

DeclarePass (Fg_V)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_V)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Premix_V)
{ return (Amount < 0.5) ? tex2D (Fg_V, uv3) : tex2D (Bg_V, uv3); }

DeclareEntryPoint (RotationTrans_V)
{
   float4 Fgnd = tex2D (Fg_V, uv3);
   float4 Bgnd = tex2D (Bg_V, uv3);
   float4 maskBg, retval;

   float2 xy = uv3;

   float amount = Amount;
   float masked = tex2D (Mask, uv3).x;

   if (Blended) {
      if (ShowKey) return lerp (kTransparentBlack, Fgnd, Fgnd.a * masked);

      maskBg = Bgnd;
      amount /= 2.0;
      if (SwapDir) amount += 0.5;
   }
   else maskBg = Fgnd;

   float scale = lerp (0.1, 0.025, Offset);
   float L = (1.0 - cos (amount * PI)) * 0.5;
   float R = 1.0 - L;
   float X = sin (amount * TWO_PI) * scale;
   float Y = sin (amount * PI) * (scale + scale);
   float Z = 1.0 - (tan ((0.5 - abs (amount - 0.5)) * HALF_PI) * lerp (0.2, 0.0125, Offset));

   if (amount >= 0.5) {
      L = 1.0 - L;
      R = 1.0 - R;
      Y = -Y;
   }

   if (Reverse) {
      Y = -Y;
      xy -= float2 (X * 0.5, 0.5);
   }
   else xy -= float2 (-X, 0.5);

   float2 topLeft  = float2 (L, -Y);
   float2 topRight = float2 (R, Y);
   float2 botLeft  = float2 (L, 1.0 + Y);
   float2 botRight = float2 (R, 1.0 - Y);

   xy.y = (xy.y * Z) + 0.5;

   bool InRange = fn_3Drotate (topLeft, topRight, botLeft, botRight, xy);

   if (Blended) {
      Fgnd = InRange ? tex2D (Fg_V, xy) : kTransparentBlack;
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }
   else retval = InRange ? tex2D (Premix_V, xy) : kTransparentBlack;

   return lerp (maskBg, retval, masked);
}

//-----------------------------------------------------------------------------------------//

// technique RotationTrans_H

DeclarePass (Fg_H)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_H)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Premix_H)
{ return (Amount < 0.5) ? tex2D (Fg_H, uv3) : tex2D (Bg_H, uv3); }

DeclareEntryPoint (RotationTrans_H)
{
   float4 Fgnd = tex2D (Fg_H, uv3);
   float4 Bgnd = tex2D (Bg_H, uv3);
   float4 maskBg, retval;

   float2 xy = uv3;

   float amount = Amount;
   float masked = tex2D (Mask, uv3).x;

   if (Blended) {
      if (ShowKey) return lerp (kTransparentBlack, Fgnd, Fgnd.a * masked);

      maskBg = Bgnd;
      amount /= 2.0;
      if (SwapDir) amount += 0.5;
   }
   else maskBg = Fgnd;

   float scale = lerp (0.1, 0.025, Offset);
   float B = (cos (amount * PI) + 1.0) * 0.5;
   float T = 1.0 - B;
   float X = sin (amount * PI) * (scale + scale);
   float Y = sin (amount * TWO_PI) * scale;
   float Z = 1.0 - (tan ((0.5 - abs (amount - 0.5)) * HALF_PI) * lerp (0.2, 0.0125, Offset));

   if (amount >= 0.5) {
      B = 1.0 - B;
      T = 1.0 - T;
      X = -X;
   }

   if (Reverse) {
      X = -X;
      xy -= float2 (0.5, Y * 0.5);
   }
   else xy -= float2 (0.5, -Y);

   float2 topLeft  = float2 (-X, T);
   float2 topRight = float2 (1.0 + X, T);
   float2 botLeft  = float2 (X, B);
   float2 botRight = float2 (1.0 - X, B);

   xy.x = (xy.x * Z) + 0.5;

   bool InRange = fn_3Drotate (topLeft, topRight, botLeft, botRight, xy);

   if (Blended) {
      Fgnd = InRange ? tex2D (Fg_H, xy) : kTransparentBlack;
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }
   else retval = InRange ? tex2D (Premix_H, xy) : kTransparentBlack;

   return lerp (maskBg, retval, masked);
}

