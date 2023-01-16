// @Maintainer jwrl
// @Released 2023-01-16
// @Author baopao
// @Created 2013-10-23

/**
 A strong bilateral blur created by baopao with a little help from his friends.  Bilateral
 is based on Antitorgo's filter at http://www.blosser.org/d9/dlAviShader042.rar.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BilateralBlur.fx
//
// Version history:
//
// Update 2023-01-16 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bilateral blur", "Stylize", "Blurs and sharpens", "A strong bilateral blur created by baopao with a little help from his friends", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (FrameSize, "Blur window", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (BilateralBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;    // Ensures that only legal video is blurred

   float4 tempC0 = tex2D (Input, uv1);
   float4 Colour = tempC0;
   float4 normalizer = 1.0.xxxx;
   float4 tempC1, tempC2, tempW;

   float2 position;

   float width  = max (0.002, 1.0 - max (0.0, FrameSize));
   float height = _OutputHeight * width;

   width *= _OutputWidth;

   float stepX = 1.0 / width;
   float stepY = 1.0 / height;

   float p = 0.5;

   float x = stepX;
   float y, optX, optY, tempG;

   for (int i = 0; i < 2; i++) {
      y = stepY;
      optX = x * x * width * width * 0.125;
      position = uv1 + float2 (0.0, y);

      tempC1 = mirror2D (Inp, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = uv1 - float2 (0.0, y);

      tempC1 = mirror2D (Inp, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = uv1 + float2 (x, 0.0);

      tempC1 = mirror2D (Inp, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      position = uv1 - float2 (x, 0.0);

      tempC1 = mirror2D (Inp, position);
      tempC2 = tempC0 - tempC1;
      tempW  = exp (-(tempC2 * tempC2 * p) - optX);
      Colour += (tempC1 * tempW);

      normalizer += tempW;

      for (int j = 0; j < 2; j++) {
         optX += y * y * height * height * 0.125;

         position = uv1 + float2 (x, y);

         tempC1 = mirror2D (Inp, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = uv1 - float2 (x, -y);

         tempC1 = mirror2D (Inp, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = uv1 + float2 (x, -y);

         tempC1 = mirror2D (Inp, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         position = uv1 - float2 (x, y);

         tempC1 = mirror2D (Inp, position);
         tempC2 = tempC0 - tempC1;
         tempW  = exp (-(tempC2 * tempC2 * p) - optX);
         Colour += (tempC1 * tempW);

         normalizer += tempW;

         y += stepY;
      }

      x += stepX;
   }

   return lerp (tempC0, Colour / normalizer, tex2D (Mask, uv1));
}

