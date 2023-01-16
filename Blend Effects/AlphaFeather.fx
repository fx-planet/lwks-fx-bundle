// @Maintainer jwrl
// @Released 2023-01-05
// @Author khaver
// @Created 2012-12-10

/**
 The Alpha Feather effect was created to help bed an externally generated graphic with
 an alpha channel into an existing background after it was noticed that the standard LW
 Blend/In Front effect can give foreground images sharp, slightly aliased edges.  It will
 allow feathering the edges of the foreground image with the background image by blurring
 both in the blend region.  The blurring is a true gaussian blur and provides controls to
 allow you to change the blur radius and threshold.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AlphaFeather.fx
//
// Version history:
//
// Update 2023-01-05 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Alpha Feather", "Mix", "Blend Effects", "Helps bed an externally generated graphic with transparency into a background", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (thresh, "Threshold", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (Feather, "Radius", kNoGroup, kNoFlags, 0.0, 0.0, 2.0);
DeclareFloatParam (Mix, "Mix", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (Show, "Show alpha", kNoGroup, false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float offset [5] = { 0.0, 1.0, 2.0, 3.0, 4.0 };
float weight [5] = { 0.2734375, 0.21875 / 4.0, 0.109375 / 4.0, 0.03125 / 4.0, 0.00390625 / 4.0 };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Composite)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 fg = tex2D (Fg, uv1);
   float4 bg = ReadPixel (Bg, uv2);
   float4 ret = lerp (bg, fg, fg.a * Opacity);

   ret.a = fg.a;

   return ret;
}

DeclareEntryPoint (AlphaFeather)
{
   float4 Bgnd = ReadPixel (Bg, uv2);

   if (IsOutOfBounds (uv1)) return Bgnd;

   float2 pixel = 1.0 / float2 (_OutputWidth, _OutputHeight);

   float4 orig = tex2D (Composite, uv3);
   float4 Cout, color = orig * weight [0];

   float check = orig.a;

   for (int i = 1; i < 5; i++) {
      Cout = tex2D (Composite, uv3 + (float2 (pixel.x * offset [i], 0.0) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 + (float2 (pixel.x * offset [i], 0.0) * Feather)) * weight [i];
      else color += orig * weight [i];

      Cout = tex2D (Composite, uv3 - (float2 (pixel.x * offset [i], 0.0) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 - (float2 (pixel.x * offset [i], 0.0) * Feather)) * weight[i];
      else color += orig * weight [i];

      Cout = tex2D (Composite, uv3 + (float2 (0.0, pixel.y * offset [i]) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 + (float2 (0.0, pixel.y * offset [i]) * Feather)) * weight [i];
      else color += orig * weight [i];

      Cout = tex2D (Composite, uv3 - (float2 (0.0, pixel.y * offset [i]) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 - (float2 (0.0, pixel.y * offset [i]) * Feather)) * weight [i];
      else color += orig * weight [i];

      Cout = tex2D (Composite, uv3 + (float2 (pixel.x * offset [i], pixel.y * offset [i]) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 + (float2 (pixel.x * offset [i], pixel.y * offset [i]) * Feather)) * weight [i];
      else color += orig * weight [i];

      Cout = tex2D (Composite, uv3 - (float2 (pixel.x * offset [i], pixel.y * offset [i]) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 - (float2 (pixel.x * offset [i], pixel.y * offset [i]) * Feather)) * weight [i];
      else color += orig * weight [i];

      Cout = tex2D (Composite, uv3 + (float2 (-pixel.x * offset [i], pixel.y * offset [i]) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 + (float2 (-pixel.x * offset [i], pixel.y * offset [i]) * Feather)) * weight [i];
      else color += orig * weight [i];

      Cout = tex2D (Composite, uv3 + (float2 (pixel.x * offset [i], -pixel.y * offset [i]) * Feather));

      if (abs (check - Cout.a) > thresh) color += tex2D (Composite, uv3 + (float2 (pixel.x * offset [i], -pixel.y * offset [i]) * Feather)) * weight [i];
      else color += orig * weight [i];
      }

   color.a = 1.0;
   orig.a = 1.0;

   float4 retval = Show ? check.xxxx : lerp (orig, color, Mix);

   return lerp (Bgnd, retval, tex2D (Mask, uv1));
}

