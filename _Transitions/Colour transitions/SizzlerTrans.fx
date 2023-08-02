// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2017-05-12

/**
 This effect dissolves two images or a blended foreground image in or out through a
 complex colour translation while performing what is essentially a non-additive mix.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SizzlerTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sizzler transition", "Mix", "Colour transitions", "Transition using a complex colour translation", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Saturation, "Saturation", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (HueCycle, "Cycle rate", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_sizzler (float4 Fgnd, float4 Bgnd, float amt)
{
   float4 nonAdd = max (Fgnd * min (1.0, 2.0 * (1.0 - amt)), Bgnd * min (1.0, 2.0 * amt));
   float4 premix = max (Fgnd, Bgnd);

   float Luma  = 0.1 + (0.5 * premix.x);
   float Satn  = premix.y * Saturation;
   float Hue   = frac (premix.z + (amt * HueCycle));

   float HueX3 = 3.0 * Hue;
   float Hfac  = (floor (HueX3) + 0.5) / 3.0;

   Hue = SQRT_3 * tan ((Hue - Hfac) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;
   float Alpha = premix.w;

   float4 retval = (HueX3 < 1.0) ? float4 (Green, Blue, Red, Alpha)
                 : (HueX3 < 2.0) ? float4 (Red, Green, Blue, Alpha)
                                 : float4 (Blue, Red, Green, Alpha);

   return lerp (retval, nonAdd, pow (2.0 * (0.5 - amt), 2.0));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclareEntryPoint (SizzlerTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   if (Blended) {
      if (ShowKey) {
         maskBg = kTransparentBlack;
         retval = lerp (maskBg, Fgnd, Fgnd.a);
      }
      else {
         float amt = SwapDir ? 1.0 - Amount : Amount;

         retval = lerp (Bgnd, fn_sizzler (Fgnd, Bgnd, amt), Fgnd.a);
         maskBg = Bgnd;
      }
   }
   else {
      retval = fn_sizzler (Fgnd, Bgnd, Amount);
      maskBg = Fgnd;
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

