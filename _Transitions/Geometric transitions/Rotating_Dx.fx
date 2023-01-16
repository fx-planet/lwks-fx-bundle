// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 Transitions between two sources by rotating them horizontally or vertically.  The maths
 used is quite different to that used in the keyed version because of non-linearities that
 were acceptable for that use were not for this.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rotating_Dx.fx
//
// Revision history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rotating transition", "Mix", "Geometric transitions", "X or Y axis rotating transition", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Amount axis", kNoGroup, 0, "Vertical|Horizontal");

DeclareBoolParam (Reverse, "Reverse rotation", kNoGroup, false);

DeclareFloatParam (Offset, "Z offset", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool fn_3Drotate (float2 tl, float2 tr, float2 bl, float2 br, inout float2 uv3)
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

   float3 xyz = mul (float3 (uv3, 1.0), mul (m, float3x3 (1.0, 0.0.xx, -1.0.xx, -2.0, 0.0.xx, 1.0)));

   uv3 = xyz.xy / xyz.z;

   return (uv3.x >= 0.0) && (uv3.y >= 0.0) && (uv3.x <= 1.0) && (uv3.y <= 1.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Premix_V)
{ return (Amount < 0.5) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Main_V)
{
   float scale = lerp (0.1, 0.025, Offset);
   float L = (1.0 - cos (Amount * PI)) * 0.5;
   float R = 1.0 - L;
   float X = sin (Amount * TWO_PI) * scale;
   float Y = sin (Amount * PI) * (scale + scale);
   float Z = 1.0 - (tan ((0.5 - abs (Amount - 0.5)) * HALF_PI) * lerp (0.2, 0.0125, Offset));

   float2 xy = uv3;

   if (Amount >= 0.5) {
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

   float4 retval = tex2D (Premix_V, xy);

   return InRange ? retval : kTransparentBlack;
}

DeclarePass (Premix_H)
{ return (Amount < 0.5) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Main_H)
{
   float scale = lerp (0.1, 0.025, Offset);
   float B = (cos (Amount * PI) + 1.0) * 0.5;
   float T = 1.0 - B;
   float X = sin (Amount * PI) * (scale + scale);
   float Y = sin (Amount * TWO_PI) * scale;
   float Z = 1.0 - (tan ((0.5 - abs (Amount - 0.5)) * HALF_PI) * lerp (0.2, 0.0125, Offset));

   float2 xy = uv3;

   if (Amount >= 0.5) {
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

   float4 retval = tex2D (Premix_H, xy);

   return InRange ? retval : kTransparentBlack;
}

