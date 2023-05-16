// @Maintainer jwrl
// @Released 2023-05-16
// @Author windsturm
// @Created 2012-12-11

/**
 This effect simulates the dot pattern used in a black and white half-tone print image.
 The colours used for background and dots are user adjustable.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Halftone.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Halftone", "Stylize", "Print Effects", "Simulates the dot pattern used in a black and white half-tone print image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (toneMode, "Tone Mode", kNoGroup, 0, "Darkness|Brightness|SourceColor");
DeclareIntParam (lumaMode, "Luma Mode", kNoGroup, 0, "BT709|BT470|BT601");

DeclareFloatParam (centerX, "Center", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (centerY, "Center", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (dotSize, "Size", kNoGroup, kNoFlags, 0.01, 0.0, 1.0);
DeclareFloatParam (Angle, "Angle", kNoGroup, kNoFlags, 0.0, 0.0, 360.0);

DeclareColourParam (colorFG, "Foreground", "Color", kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareColourParam (colorBG, "Background", "Color", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SQRT_2 1.414214

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2x2 RotationMatrix (float rotation)
{
   float c, s;

   sincos (rotation, s, c);

   return float2x2 (c, -s, s ,c);
}

float4 half_tone (sampler ss, float2 uv, float s, float angle, float a)
{
   float2 xy  = uv;
   float2 asp = float2 (1.0, _OutputAspectRatio);

   float2 centerXY = float2 (centerX, 1.0 - centerY);
   float2 pointXY  = mul ((xy - centerXY) / asp, RotationMatrix (radians (angle)));

   pointXY += (s / 2.0);
   pointXY = round (pointXY / dotSize) * dotSize;
   pointXY = mul (pointXY, RotationMatrix (radians (-angle)));
   pointXY = pointXY * asp + centerXY;

   float4 pointCol = tex2D (ss, pointXY);

   // xy slide

   float2 slideXY = mul (float2 (s / SQRT_2, 0.0), RotationMatrix (radians ((angle + a) * -1.0)));
   slideXY *= asp;

   float luma;

   if (lumaMode == 0) { luma = dot (float3 (0.212649, 0.715169, 0.072182), pointCol.rgb); }
   else if (lumaMode == 1) { luma = dot (float3 (0.222015, 0.706655, 0.071330), pointCol.rgb); }
   else luma = dot (float3 (0.298912, 0.586611, 0.114478), pointCol.rgb);

   float4 fgColor = colorFG;

   if (toneMode == 2) fgColor = pointCol;

   asp *= dotSize * ((toneMode == 0) ? 1.0 - luma : luma);
   xy += slideXY;

   float2 aspectAdjustedpos = ((xy - pointXY) / asp) + pointXY;

   return (distance (aspectAdjustedpos, pointXY) < 0.5) ? fgColor : -1.0.xxxx;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (s0)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (Halftone)
{
   float4 retval, source = tex2D (s0, uv2);

   if (dotSize <= 0.0) { retval = source; }
   else {
      float4 ret1 = half_tone (s0, uv2, 0.0, Angle, 0.0);
      float4 ret2 = half_tone (s0, uv2, dotSize, Angle, 45.0);

      retval = (ret1.a > -1.0 || ret2.a > -1.0) ? max (ret1, ret2) : colorBG;

      if (IsOutOfBounds (uv2)) retval = kTransparentBlack;
   }

   return lerp (source, retval, tex2D (Mask, uv2).x);
}

