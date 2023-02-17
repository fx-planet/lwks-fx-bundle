// @Maintainer jwrl
// @Released 2023-02-17
// @Author jMovie
// @Created 2011-05-27

/**
 The effect adjusts RGB or HSV levels to give a smooth S-curve by means of fader controls.
 Care must be exercised not to push it too far, though, or discontinuities in the curves
 can appear.  The result can be quite ugly when that happens.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Scurve.fx
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//
// Updated 2023-01-23 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("S-Curve", "Colour", "Colour Tools", "Adjusts RGB or HSV levels to give a smooth S-curve by means of fader controls", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (InY, "Black (InY)", "Curves", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (LowY, "Low mid (LowY)", "Curves", kNoFlags, 0.3333, 0.0, 1.0);
DeclareFloatParam (HighY, "High mid (HighY)", "Curves", kNoFlags, 0.6667, 0.0, 1.0);
DeclareFloatParam (OutY, "White (OutY)", "Curves", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (InX, "Black (InX)", "Break points", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (LowX, "Low mid (LowX)", "Break points", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (HighX, "High mid (HighX)", "Break points", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (OutX, "White (OutX)", "Break points", kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (Visualize, "Visualize", kNoGroup, false);
DeclareBoolParam (RChannel, "Channel R", kNoGroup, true);
DeclareBoolParam (GChannel, "Channel G", kNoGroup, true);
DeclareBoolParam (BChannel, "Channel B", kNoGroup, true);
DeclareBoolParam (ValueChannel, "Channel (HS)V Overrides RGB", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_curve_magic (float valueIn, float indexFraction)
// _CurveMagic derived from http://www.codeproject.com/KB/graphics/Spline_ImageCurve.aspx
// and modifed by jMovie.  This fn_curve_magic version very much simplifed and optimised
// by removing redundant code and variables - jwrl
{
   float2 controlPoint [4];
   float2 points [4] = { float2 (InX * 0.2745, InY),
                         float2 (LowX * 0.6275, LowY),
                         float2 ((HighX * 0.6667) + 0.3333, HighY),
                         float2 ((OutX * 0.3333) + 0.6667, OutY) };

   int fromXIdx = (indexFraction < 0.25) ? 0 : (indexFraction < 0.35) ? 1 : 2;

   controlPoint [0] = points [0];
   controlPoint [1] = points [1] * 6.0 - points [0];
   controlPoint [2] = points [2] * 6.0 - points [3];
   controlPoint [3] = points [3];

   controlPoint [2] = (controlPoint [2] - controlPoint [1] * 0.25) / 3.75;
   controlPoint [1] = (controlPoint [1] - controlPoint [2]) / 4.0;

   float t = (valueIn - points [fromXIdx].x) / (points [fromXIdx + 1].x - points [fromXIdx].x);
   float T = 1.0 - t;

   float2 b = T * (controlPoint [fromXIdx] * 2.0 + controlPoint [fromXIdx + 1]);

   b += t * (controlPoint [fromXIdx] + controlPoint [fromXIdx + 1] * 2.0);
   b *= t;
   b += T * T * points [fromXIdx];
   b *= T;
   b += t * t * t * points [fromXIdx + 1];

   return b.y;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclarePass (HSVsampler)
// Original Pass0_Input converted by changing _RGBtoHSV function to in-line code.
// All float3 variables converted to float4 to preserve alpha channel - jwrl
{
   if (IsOutOfBounds (uv2)) return kTransparentBlack;

   if (Visualize) return float4 (uv2.x, 0.0, 0.0, 1.0);

   float4 src_rgba = tex2D (Inp, uv2);

   if (!ValueChannel) return src_rgba;

   float4 HSV = float4 (0.0.xx, max (src_rgba.r, max (src_rgba.g, src_rgba.b)), src_rgba.a);

   float M = min (src_rgba.r, min (src_rgba.g, src_rgba.b));
   float C = HSV.z - M;

   if (C != 0.0) {
      HSV.y = C / HSV.z;

      float4 D = (((HSV.z - src_rgba) / 6.0) + (C / 2.0)) / C;

      if (src_rgba.r == HSV.z) HSV.x = D.b - D.g;
      else if (src_rgba.g == HSV.z) HSV.x = (1.0 / 3.0) + D.r - D.b;
      else if (src_rgba.b == HSV.z) HSV.x = (2.0 / 3.0) + D.g - D.r;

      if (HSV.x < 0.0) HSV.x += 1.0;

      if (HSV.x > 1.0) HSV.x -= 1.0;
   }

   return HSV;
}

DeclareEntryPoint (Scurve)
{
   if (IsOutOfBounds (uv2)) return kTransparentBlack;

   float points [6] = { 0.0, InX * 0.2745, LowX * 0.6275, (HighX * 0.6667) + 0.3333, (OutX * 0.3333) + 0.6667, 1.0 };

   float4 src_raw  = tex2D (Inp, uv2);
   float4 src_rgba = saturate (src_raw);
   float4 p2 = saturate (tex2D (HSVsampler, uv2));
   float4 src_hsv = p2, src_idx = 0.0;

   float alpha = p2.a;

   for (int i = 0; i < 6; ++i) {
      if (points [i] < p2.x) src_idx.x += 0.1;
      if (points [i] < p2.y) src_idx.y += 0.1;
      if (points [i] < p2.z) src_idx.z += 0.1;
   }

   p2.x = fn_curve_magic (p2.x, src_idx.x);

   if (Visualize) { if ((1.0 - uv2.y) < (p2.x)) src_rgba = 0.0; }
   else {
      src_hsv.z = fn_curve_magic (p2.z, src_idx.z);

      if (ValueChannel) {
         p2 = 0.0;

         float C = src_hsv.z * src_hsv.y;
         float H = src_hsv.x * 6.0;
         float X = C * (1.0 - abs (fmod (H, 2.0) - 1.0));

         if (src_hsv.y != 0.0) {
            int I = floor (H);

            if (I == 0) p2.xy = float2 (C, X);
            else if (I == 1) p2.xy = float2 (X, C);
            else if (I == 2) p2.yz = float2 (C, X);
            else if (I == 3) p2.yz = float2 (X, C);
            else if (I == 4) p2.xz = float2 (X, C);
            else p2.xz = float2 (C, X);
         }

         p2 += src_hsv.z - C;
         src_rgba.rgb = p2.xyz;
      }
      else {
         if (RChannel) src_rgba.r = p2.x;
         if (GChannel) src_rgba.g = fn_curve_magic (p2.y, src_idx.y);
         if (BChannel) src_rgba.b = src_hsv.z;
      }
   }

   return lerp (src_raw, saturate (src_rgba), tex2D (Mask, uv2));
}

