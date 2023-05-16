// @Maintainer jwrl
// @Released 2023-05-17
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

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   if (Blended) {
      float4 Bgnd = ReadPixel (Bg, uv2);

      if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
      else {
         if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

         Fgnd.rgb = SwapDir ? Bgnd.rgb : lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a);
      }
      Fgnd.a = pow (Fgnd.a, 0.1);
   }
   else Fgnd.a = 1.0;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = ReadPixel (Bg, uv2);

   if (Blended && SwapDir) {

      if (Source > 0) {
         float4 Fgnd = ReadPixel (Fg, uv1);

         if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

         Bgnd = lerp (Bgnd, Fgnd, Fgnd.a);
      }
   }

   return Bgnd;
}

DeclareEntryPoint (SizzlerTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float4 nonAdd = max (Fgnd * min (1.0, 2.0 * (1.0 - Amount)), Bgnd * min (1.0, 2.0 * Amount));
      float4 premix = max (Fgnd, Bgnd);

      float Alpha = premix.w;
      float Luma  = 0.1 + (0.5 * premix.x);
      float Satn  = premix.y * Saturation;
      float Hue   = frac (premix.z + (Amount * HueCycle));
      float LumX3 = 3.0 * Luma;

      float HueX3 = 3.0 * Hue;
      float Hfac  = (floor (HueX3) + 0.5) / 3.0;

      Hue = SQRT_3 * tan ((Hue - Hfac) * TWO_PI);

      float Red   = (1.0 - Satn) * Luma;
      float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
      float Green = 3.0 * Luma - Blue - Red;

      retval = (HueX3 < 1.0) ? float4 (Green, Blue, Red, Alpha)
             : (HueX3 < 2.0) ? float4 (Red, Green, Blue, Alpha)
                             : float4 (Blue, Red, Green, Alpha);

      float mixval = abs (2.0 * (0.5 - Amount));

      mixval *= mixval;

      retval = lerp (retval, nonAdd, mixval);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

