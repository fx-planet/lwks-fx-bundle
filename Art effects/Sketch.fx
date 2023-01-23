// @Maintainer jwrl
// @Released 2023-01-23
// @Author khaver
// @Created 2012-08-21

/**
 Sketch (Sketch_2022.fx) simulates a sketch from a standard video source.  An extremely
 wide range of adjustment parameters have been provided which should meet most needs.
 Border line colour is adjustable, as are the individual thresholds for each RGB channel.

 Shadow area colour can also be adjusted for best effect.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sketch.fx
//
// Version history:
//
// Update 2023-01-23 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sketch", "Stylize", "Art Effects", "Converts any standard video source or graphic to a simple sketch", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Invert, "Invert All", kNoGroup, false);

DeclareColourParam (BorderLineColor, "Color", "Lines", kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareFloatParam (Strength, "Strength", "Lines", kNoFlags, 1.0, 0.0, 20.0);

DeclareBoolParam (InvLines, "Invert", "Lines", false);

DeclareFloatParam (RLevel, "Red Threshold", "Background", kNoFlags, 0.3, 0.0, 1.0);
DeclareFloatParam (GLevel, "Green Threshold", "Background", kNoFlags, 0.59, 0.0, 1.0);
DeclareFloatParam (BLevel, "Blue Threshold", "Background", kNoFlags, 0.11, 0.0, 1.0);
DeclareFloatParam (Level, "Shadow Amount", "Background", kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (DarkColor, "Shadow Color", "Background", kNoFlags, 0.5, 0.5, 0.5, 1.0);
DeclareColourParam (LightColor, "Highlight Color", "Background", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareBoolParam (Swap, "Swap", "Background", false);
DeclareBoolParam (InvBack, "Invert", "Background", false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

int GX [3][3] =
{
    { -1, +0, +1 },
    { -2, +0, +2 },
    { -1, +0, +1 },
};

int GY [3][3] =
{
    { +1, +2, +1 },
    { +0, +0, +0 },
    { -1, -2, -1 },
};

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Threshold)
{
   float4 src1 = ReadPixel (Input, uv1);

   if (IsOutOfBounds (uv1) || (src1.a <= 0.0)) return kTransparentBlack;

   float srcLum = saturate ((src1.r * RLevel) + (src1.g * GLevel) + (src1.b * BLevel));

   if (Swap) src1.rgb = (srcLum <= Level) ? LightColor.rgb : DarkColor.rgb;
   else src1.rgb = (srcLum > Level) ? LightColor.rgb : DarkColor.rgb;

   if (InvBack) src1 = 1.0.xxxx - src1;

   return src1;
}

DeclarePass (Blur1)
{
   float4 blurred = tex2D (Threshold, uv2);

   if (IsOutOfBounds (uv1) || (blurred.a <= 0.0)) return kTransparentBlack;

   float one   = 1.0 / _OutputWidth;
   float tap1  = uv2.x + one;
   float ntap1 = uv2.x - one;

   blurred += tex2D (Threshold, float2 (tap1,  uv2.y));
   blurred += tex2D (Threshold, float2 (ntap1, uv2.y));

   return blurred / 3.0;
}

DeclarePass (Blur2)
{
   float4 ret = tex2D (Blur1, uv2);

   if (IsOutOfBounds (uv1) || (ret.a <= 0.0)) return kTransparentBlack;

   float one  = 1.0 / _OutputHeight;
   float tap1 = uv2.y + one;
   float ntap1 = uv2.y - one;

   ret += tex2D (Blur1, float2 (uv2.x, tap1));
   ret += tex2D (Blur1, float2 (uv2.x, ntap1));

   return ret / 3.0;
}

DeclareEntryPoint (Sketch)
{
   float alpha = ReadPixel (Input, uv1).a;

   if (IsOutOfBounds (uv1) || (alpha <= 0.0)) return kTransparentBlack;

   float4 bl = BorderLineColor;

   float2 PixelSize = 1.0 / float2 (_OutputWidth, _OutputHeight);
   float2 pix;

   float sumX = 0.0;
   float sumY = 0.0;
   float val;

   for (int i = -1; i <= 1; i++) {

      for (int j = -1; j <= 1; j++) {
         pix = float2 (i * PixelSize.x, j * PixelSize.y);
         val = dot (tex2D (Input, uv1 + pix).rgb, float3 (0.3, 0.59, 0.11));

         sumX += val * GX [i + 1][j + 1] * Strength;
         sumY += val * GY [i + 1][j + 1] * Strength;
      }
   }

   float4 color = 1.0.xxxx - (saturate (abs (sumX) + abs (sumY)) * (1.0.xxxx - bl));
   color.a = (color.r + color.g + color.b) / 3.0;

   if (InvLines) color.rgb = 1.0.xxx - color.rgb;

   float4 back = tex2D (Blur2, uv2 - (PixelSize * 1.5));
   float4 src1 = ReadPixel (Input, uv1);

   if (Invert) return 1.0.xxxx - lerp (color, back, color.a);

   color = lerp (color, back, color.a);
   color.a = alpha;

   return lerp (src1, color, tex2D (Mask, uv1).x);
}

