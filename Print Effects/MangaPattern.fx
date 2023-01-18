// @Maintainer jwrl
// @Released 2023-01-18
// @Author windsturm
// @Author jwrl
// @Created 2012-05-23

/**
 This simulates the star pattern and hard contours used to create tonal values in a Manga
 half-tone image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MangaPattern.fx
//
// Version history:
//
// Updated 2023-01-18 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Manga pattern", "Stylize", "Print Effects", "This simulates the star pattern and hard contours used to create tonal values in a Manga half-tone image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (skipGS, "Greyscale derived from:", NoGroup, 0, "Luminance|RGB average");

DeclareFloatParam (threshold, "Pattern size", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (td1, "Black threshold", "Sample threshold", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (td2, "Dark grey", "Sample threshold", kNoFlags, 0.4, 0.0, 1.0);
DeclareFloatParam (td3, "Light grey", "Sample threshold", kNoFlags, 0.6, 0.0, 1.0);
DeclareFloatParam (td4, "White threshold", "Sample threshold", kNoFlags, 0.8, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_OutputWidth);

DeclareIntParam (_InputOrientation);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define _IsPortrait (abs (_InputOrientation - 180) == 90)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (MangaPattern)
{
   float3 d_0 [] = { { 0.44, 0.75, 0.93 }, { 0.15, 0.46, 0.56 }, { 0.84, 0.95, 1.0 },
                     { 0.8,  0.93, 1.0  }, { 0.0,  0.0,  0.12 } };

   int pArray [] = { 0, 1, 0, 2, 3, 2, 1, 4, 1, 3, 5, 3, 0, 1, 0, 2, 3, 2,
                     2, 3, 2, 0, 1, 0, 3, 5, 3, 1, 4, 1, 2, 3, 2, 0, 1, 0 };

   float4 color = ReadPixel (Input, uv1);

   float2 xy = float2 (1.0, _OutputAspectRatio);

   int2 pSize = _IsPortrait ? _OutputWidth * xy : _OutputWidth / xy;
   int2 pixXY = fmod (uv1 * pSize * (1.0 - threshold), 6.0.xx);

   int p = pArray [pixXY.x + (pixXY.y * 6)];

   float4 dots = float4 (d_0 [p], 1.0);

   if (p < 5) {
      float luma = (skipGS == 1) ? (color.r + color.g + color.b) / 3.0
                                 : dot (color.rgb, float3 (0.299, 0.587, 0.114));

      if (luma < td1) dots = float2 (0.0, 1.0).xxxy;
      else if (luma < td2) dots.yz = dots.xx;
      else if (luma < td3) dots.xz = dots.yy;
      else if (luma <= td4) dots.xy = dots.zz;
      else dots = 1.0.xxxx;
   }
   else dots = 1.0.xxxx;

   if (IsOutOfBounds (uv1)) dots = kTransparentBlack;

   return lerp (color, dots, tex2D (Mask, uv1));
}

