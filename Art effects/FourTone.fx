// @Maintainer jwrl
// @Released 2023-05-14
// @Author idealsceneprod (Val Gameiro)
// @Created 2014-12-24

/**
 Four tone (FourtoneFx.fx) is a posterization effect that extends the existing Lightworks
 Two Tone and Tri-Tone effects.  It reduces input video to four tonal values.  Blending and
 colour values are all adjustable.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FourTone.fx
//
// Version history:
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Four tone", "Colour", "Art Effects", "Extends the existing Lightworks Two Tone and Tri-Tone effects to provide four tonal values", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Level1, "Threshold One", kNoGroup, kNoFlags, 0.33, 0.0, 1.0);
DeclareFloatParam (Level2, "Threshold Two", kNoGroup, kNoFlags, 0.66, 0.0, 1.0);
DeclareFloatParam (Level3, "Threshold Three", kNoGroup, kNoFlags, 0.75, 0.0, 1.0);

DeclareColourParam (DarkColour, "Dark Colour", kNoGroup, kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareColourParam (MidColour, "Mid Dark Colour", kNoGroup, kNoFlags, 0.3, 0.3, 0.3, 1.0);
DeclareColourParam (MidColour2, "Mid Light Colour", kNoGroup, kNoFlags, 0.7, 0.7, 0.7, 1.0);
DeclareColourParam (LightColour, "Light Colour", kNoGroup, kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputHeight);
DeclareFloatParam (_OutputWidth);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };  // Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Threshold)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 src1 = ReadPixel (Input, uv1);

   float srcLum = ((src1.r * 0.3) + (src1.g * 0.59) + (src1.b * 0.11));

   if (srcLum < Level1) src1.rgb = DarkColour.rgb;
   else if ( srcLum < Level2 ) src1.rgb = MidColour.rgb;
   else if ( srcLum < Level3 ) src1.rgb = MidColour2.rgb;
   else src1.rgb = LightColour.rgb;

   return src1;
}

DeclarePass (Blur)
{
   if (IsOutOfBounds (uv2)) return kTransparentBlack;

   // Explicitly query BETWEEN pixels to get extra averaging

   float2 onePixAcross   = float2 (0.5 / _OutputWidth, 0.0);
   float2 twoPixAcross   = float2 (1.5 / _OutputWidth, 0.0);
   float2 threePixAcross = float2 (2.5 / _OutputWidth, 0.0);

   float4 keyPix = tex2D (Threshold, uv2);
   float4 result = keyPix * blur [0];

   result += tex2D (Threshold, uv2 + onePixAcross)   * blur [1];
   result += tex2D (Threshold, uv2 - onePixAcross)   * blur [1];
   result += tex2D (Threshold, uv2 + twoPixAcross)   * blur [2];
   result += tex2D (Threshold, uv2 - twoPixAcross)   * blur [2];
   result += tex2D (Threshold, uv2 + threePixAcross) * blur [3];
   result += tex2D (Threshold, uv2 - threePixAcross) * blur [3];
   result.a = keyPix.a;

   return result;
}

DeclareEntryPoint (FourTone)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   // Explicitly query BETWEEN pixels to get extra averaging

   float2 onePixDown   = float2 (0.0, 0.5 / _OutputHeight);
   float2 twoPixDown   = float2 (0.0, 1.5 / _OutputHeight);
   float2 threePixDown = float2 (0.0, 2.5 / _OutputHeight);

   float4 source = tex2D (Input, uv1);
   float4 keyPix = tex2D (Blur, uv2);

   float4 result = keyPix * blur [0];
   result += tex2D (Blur, uv2 + onePixDown)   * blur [1];
   result += tex2D (Blur, uv2 - onePixDown)   * blur [1];
   result += tex2D (Blur, uv2 + twoPixDown)   * blur [2];
   result += tex2D (Blur, uv2 - twoPixDown)   * blur [2];
   result += tex2D (Blur, uv2 + threePixDown) * blur [3];
   result += tex2D (Blur, uv2 - threePixDown) * blur [3];
   result.a = keyPix.a;

   result = lerp (source, result, source.a);
   result.a = source.a;

   return lerp (source, result, tex2D (Mask, uv1).x);
}
