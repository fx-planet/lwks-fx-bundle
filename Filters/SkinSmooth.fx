// @Maintainer jwrl
// @Released 2023-05-16
// @Author baopao
// @Created 2014-07-06

/**
 Smooths flesh tones to reduce visible skin blemishes.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SkinSmooth.fx
//
// SkinSmooth by baopao
//
// Based on: http://www.blosser.org/d9/dlAviShader042.rar
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Skin smooth", "Stylize", "Filters", "Smooths flesh tones to reduce visible skin blemishes", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (IMG, MSK);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (FrameSize, "Sample size", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (RedMask, "Red mask", kNoGroup, true);

DeclareFloatParam (MaskBrightness, "Mask brightness", kNoGroup, kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (MaskGamma, "Mask gamma", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);

DeclareBoolParam (ShowRedMask, "Show red mask", kNoGroup, false);
DeclareBoolParam (InputMask, "Use external mask", kNoGroup, false);
DeclareBoolParam (ShowMask, "Show external mask", kNoGroup, false);

DeclareColourParam (ShowMaskColour, "Ext mask colour", kNoGroup, kNoFlags, 0.0, 1.0, 0.0, 1.0);

DeclareFloatParam (ShowMaskAmount, "Ext mask mix", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (IMG, uv1); }

DeclarePass (Masked)
{ return ReadPixel (MSK, uv2); }

DeclareEntryPoint (SkinSmooth)
{
   float stepX = _OutputWidth * (1.0 - (min (1.0, FrameSize) * 0.75));
   float stepY = stepX / _OutputAspectRatio;
   float w2t = stepX * stepX / 8.0;
   float h2t = stepY * stepY / 8.0;

   stepX = 1.0 / stepX;
   stepY = 1.0 / stepY;

   float4 bgPix = tex2D (Inp, uv3);
   float4 Mask = tex2D (Masked, uv3);
   float4 Color = bgPix;

   float3 normalizer = 1.0.xxx;
   float3 tempC0 = Color.rgb;
   float3 tempC1, tempC2, tempW;

   float startX = -stepX * 2.0;
   float startY = -stepY * 2.0;
   float p = Amount == 0.0 ? 5000000000.0 : 0.5 / (Amount * Amount);
   float x = stepX;
   float optX, optY, y;

   float2 position;

   for (int i = 0; i < 2; i++) {
      y = stepY;
      optX = x * x * w2t;

      position = uv3 + float2 (0.0, y);
      tempC1 = tex2D (Inp, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      position = uv3 - float2 (0.0, y);
      tempC1 = tex2D (Inp, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      position = uv3 + float2 (x, 0.0);
      tempC1 = tex2D (Inp, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      position = uv3 - float2 (x, 0.0);
      tempC1 = tex2D (Inp, position).rgb;
      tempC2 = tempC0 - tempC1;
      tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
      Color.rgb += tempC1 * tempW;
      normalizer += tempW;

      for (int j = 0; j < 2; j++) {
         optX += y * y * h2t;

         position = uv3 + float2 (x, y);
         tempC1 = tex2D (Inp, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp(-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += tempC1 * tempW;
         normalizer += tempW;

         position = uv3 - float2 (x, -y);
         tempC1 = tex2D (Inp, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += tempC1 * tempW;
         normalizer += tempW;

         position = uv3 + float2 (x, -y);
         tempC1 = tex2D (Inp, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += (tempC1 * tempW);
         normalizer += (tempW);

         position = uv3 - float2 (x, y);
         tempC1 = tex2D (Inp, position).rgb;
         tempC2 = tempC0 - tempC1;
         tempW = exp (-(tempC2 * tempC2 * p) - optX.xxx);
         Color.rgb += tempC1 * tempW;
         normalizer += tempW;

         y += stepY;
      }

      x += stepX;
   }

   Color.rgb /= normalizer;

   float R_Mask = (lerp (bgPix.r, bgPix.g, 0.5) - bgPix.b);

   R_Mask = saturate (pow (R_Mask, 1.0 / MaskGamma) * MaskBrightness);

   if (RedMask) Color = lerp (bgPix, Color, R_Mask);
   if (ShowRedMask) Color = R_Mask.xxxx;
   if (InputMask) Color = lerp (bgPix, Color, Mask); 
   if (ShowMask) Color = lerp (bgPix, ShowMaskColour, ShowMaskAmount * Mask);

   return lerp (kTransparentBlack, Color, bgPix.a);
}

