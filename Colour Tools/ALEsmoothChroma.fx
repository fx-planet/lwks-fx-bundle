// @Maintainer jwrl
// @Released 2023-02-17
// @Author baopao
// @Created 2013-06-03

/**
 This smooths the colour component of video media.  Its most appropriate use is probably
 to smooth chroma in 4:2:0 footage.  It works by converting the RGB signal to YCbCr then
 blurs just the chroma Cb/Cr components.  The result is then converted back to RGB using
 the original Y channel.  This ensures that luminance sharpness is maintained and just
 the colour component is softened.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ALEsmoothChroma.fx
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//
// Update 2023-01-17 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("ALE smooth chroma", "Colour", "Colour Tools", "This smooths the colour component of video media leaving the luminance unaffected", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (BlurAmount, "BlurAmount", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input)
{ return ReadPixel (Fg, uv1); }

DeclareEntryPoint (ALEsmoothChroma)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Inp = tex2D (Input, uv2);
   float4 ret = Inp;

   float A = ret.a;
   float Y = 0.065 + (ret.r * 0.257) + (ret.g * 0.504) + (ret.b * 0.098);
   float amount = BlurAmount * 0.01;

   ret += tex2D (Input, uv2 - float2 (amount, 0.0));
   ret += tex2D (Input, uv2 + float2 (amount, 0.0));
   ret += tex2D (Input, uv2 - float2 (0.0, amount));
   ret += tex2D (Input, uv2 + float2 (0.0, amount));
   amount += amount;
   ret += tex2D (Input, uv2 - float2 (amount, 0.0));
   ret += tex2D (Input, uv2 + float2 (amount, 0.0));
   ret += tex2D (Input, uv2 - float2 (0.0, amount));
   ret += tex2D (Input, uv2 + float2 (0.0, amount));
   ret /= 9.0;

   //RGB2CbCr
  
   float Cb = 0.5 - (ret.r * 0.148) - (ret.g * 0.291) + (ret.b * 0.439);
   float Cr = 0.5 + (ret.r * 0.439) - (ret.g * 0.368) - (ret.b * 0.071);

   //YCbCr2RGB   

   ret.r = 1.164 * (Y - 0.065) + 1.596 * (Cr - 0.5);
   ret.g = 1.164 * (Y - 0.065) - 0.813 * (Cr - 0.5) - 0.392 * (Cb - 0.5);
   ret.b = 1.164 * (Y - 0.065) + 2.017 * (Cb - 0.5);
   ret.a = A;

   return lerp (Inp, saturate (ret), tex2D (Mask, uv2));
}

