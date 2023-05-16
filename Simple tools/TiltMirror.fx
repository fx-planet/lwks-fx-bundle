// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2023-03-25

/**
 This rotates two titles and/or image keys so that they either scroll in to a central
 vanishing point or scroll out from one.  The vanishing point can be horizontal best
 used for rolls, or vertical, for crawls.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiltMirror.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tilt and mirror", "DVE", "Simple tools", "Rotates a pair of rolls or image keys to scroll to a mid vanishing point", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Rotation axis", kNoGroup, 0, "Vertical|Horizontal");

DeclareFloatParam (Centre, "Centre point", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Rotate_1, "Rotation", "Upper/left - In_1", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Displace_1, "Displacement", "Upper/left - In_1", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Z_offs_1, "Z offset", "Upper/left - In_1", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Rotate_2, "Rotation", "Lower/right - In_2", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Displace_2, "Displacement", "Lower/right - In_2", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Z_offs_2, "Z offset", "Lower/right - In_2", kNoFlags, 0.5, 0.0, 1.0);

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

float4 fn_vertical (sampler In, float2 uv, float amt, float offset)
{
   float angle = amt * 0.5;
   float off_1 = lerp (0.15, 0.075, offset);
   float off_2 = off_1 + off_1;

   float B = (cos (angle * PI) + 1.0) * 0.5;
   float T = 1.0 - B;

   float X = sin (angle * PI) * off_2;
   float Y = sin (angle * TWO_PI) * off_1;
   float Z = 1.0 - (tan ((0.5 - abs (angle - 0.5)) * HALF_PI) * off_2);

   float2 xy = uv - float2 (0.5, -Y);

   if (angle > 0.5) {
      B = 1.0 - B;
      T = 1.0 - T;
      X = -X;
   }

   float2 topLeft  = float2 (-X, T);
   float2 topRight = float2 (1.0 + X, T);
   float2 botLeft  = float2 (X, B);
   float2 botRight = float2 (1.0 - X, B);

   xy.x *= Z;
   xy.x += 0.5;

   return fn_3Drotate (topLeft, topRight, botLeft, botRight, xy)
          ? tex2D (In, xy) : kTransparentBlack;
}

float4 fn_horizontal (sampler In, float2 uv, float amt, float offset)
{
   float angle = amt * 0.5;
   float off_1 = lerp (0.15, 0.075, offset);
   float off_2 = off_1 + off_1;

   float L = (1.0 - cos (angle * PI)) * 0.5;
   float R = 1.0 - L;

   float X = sin (angle * TWO_PI) * off_1;
   float Y = sin (angle * PI) * off_2;
   float Z = 1.0 - (tan ((0.5 - abs (angle - 0.5)) * HALF_PI) * off_2);

   float2 xy = uv - float2 (-X, 0.5);

   if (angle > 0.5) {
      L = 1.0 - L;
      R = 1.0 - R;
      Y = -Y;
   }

   float2 topLeft  = float2 (L, -Y);
   float2 topRight = float2 (R, Y);
   float2 botLeft  = float2 (L, 1.0 + Y);
   float2 botRight = float2 (R, 1.0 - Y);

   xy.y *= Z;
   xy.y += 0.5;

   return fn_3Drotate (topLeft, topRight, botLeft, botRight, xy)
          ? tex2D (In, xy) : kTransparentBlack;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Vertical

DeclarePass (Upper)
{ return fn_vertical (In_1, uv1, saturate (Rotate_1), Z_offs_1); }

DeclarePass (Lower)
{ return fn_vertical (In_2, uv2, 1.0 + saturate (Rotate_2), Z_offs_2); }

DeclareEntryPoint (Vertical)
{
   float disp_U = (saturate (Displace_1) * 0.5) - 0.48;
   float disp_L = (saturate (1.0 - Displace_2) * 0.5) - 0.02;

   float2 xy = uv3;

   float4 retval = kTransparentBlack;

   if (xy.y <= 1.0 - Centre) {
      xy.y -= disp_U;
      retval = ReadPixel (Upper, xy);
   }
   else {
      xy.y -= disp_L;
      retval = ReadPixel (Lower, xy);
   }

   return lerp (kTransparentBlack, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Horizontal

DeclarePass (Left)
{ return fn_horizontal (In_1, uv1, saturate (Rotate_1), Z_offs_1); }

DeclarePass (Right)
{ return fn_horizontal (In_2, uv2, 1.0 + saturate (Rotate_2), Z_offs_2); }

DeclareEntryPoint (Horizontal)
{
   float disp_L = (saturate (Displace_1) * 0.5) - 0.48;
   float disp_R = (saturate (1.0 - Displace_2) * 0.5) - 0.48;

   float2 xy = uv3;

   float4 retval = kTransparentBlack;

   if (xy.x <= Centre) {
      xy.x -= disp_L;
      retval = ReadPixel (Left, xy);
   }
   else {
      xy.x += disp_R;
      retval = ReadPixel (Right, xy);
   }

   return lerp (kTransparentBlack, retval, tex2D (Mask, uv3).x);
}

