// @Maintainer jwrl
// @Released 2023-01-26
// @Author baopao
// @Created 2013-06-07

/**
 This sophisticated chromakey has the same range of adjustments that you would expect to
 find on expensive commercial tools.  It's particularly effective on fine detail.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AleChromakey.fx
//
// Created by baopao (http://www.alessandrodallafontana.com).
//
// Version history:
//
// Updated 2023-01-26 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("ALE ChromaKey", "Key", "Key Extras", "A sophisticated chromakey that is particularly effective on fine detail", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (fg, bg, despill);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (ChromaKey, "ChromaKey", kNoGroup, 0, "Green|Blue");

DeclareFloatParam (RedAmount, "RedAmount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (FgVal, "FgVal", kNoGroup, kNoFlags, 0.45, 0.0, 1.0);
DeclareFloatParam (BgVal, "BgVal", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (GammaFG, "GammaFG", kNoGroup, kNoFlags, 2.0, 0.0, 4.0);
DeclareFloatParam (GammaBG, "GammaBG", kNoGroup, kNoFlags, 0.4, 0.0, 2.0);
DeclareFloatParam (GammaMix, "GammaMix", kNoGroup, kNoFlags, 2.0, 0.0, 5.0);

DeclareColourParam (ColorReplace, "ColorReplace", kNoGroup, kNoFlags, 0.5, 0.5, 0.5, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FG)
{ return ReadPixel (fg, uv1); }           // Color FG

DeclarePass (BG)
{ return ReadPixel (bg, uv2); }           // Color BG

DeclarePass (Blur)
{ return ReadPixel (despill, uv3); }      // BG Blur imput

DeclareEntryPoint (AleChromakey)
{
   float4 color = tex2D (FG, uv4);
   float4 colorBG = tex2D (BG, uv4);
   float4 colorBGblur = tex2D (Blur, uv4);

   float MixRB, KeyG;

   if (ChromaKey) {                              // Blue key
      MixRB = saturate (color.b - lerp (color.r, color.g, RedAmount));
      KeyG  = color.b - MixRB;
   }
   else {                                        // Green key
      MixRB = saturate (color.g - lerp (color.r, color.b, RedAmount));
      KeyG  = color.g - MixRB;
   }

   float MaskFG = saturate (1.0 - MixRB * FgVal / KeyG);
   float MaskBG = saturate (MixRB / BgVal);

   MaskFG = pow (MaskFG, 1.0 / GammaFG);
   MaskBG = pow (MaskBG, 1.0 / GammaBG);

   float OverMask = 1.0 - MaskFG - MaskBG;

   if (ChromaKey) { color.b = KeyG; }
   else color.g = KeyG;

   color  = lerp (color, ColorReplace + colorBGblur, MixRB);
   color *= MaskFG;
   color += colorBG * MaskBG;

   color = IsOutOfBounds (uv1) ? colorBG : lerp (color, pow (color, 1.0 / GammaMix), OverMask);

   return lerp (colorBG, color, tex2D (Mask, uv4).x);
}

