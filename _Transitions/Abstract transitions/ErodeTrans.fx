// @Maintainer jwrl
// @Released 2023-06-19
// @Author jwrl
// @Created 2016-12-10

/**
 This effect transitions between two video sources using a mixed key.  The result is
 that one image appears to "erode" into the other as if being eaten away by acid.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ErodeTrans.fx
//
// Version history:
//
// Updated 2023-06-19 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Erosion transition", "Mix", "Abstract transitions", "Transitions between two video sources using a luma key process", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");
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

#define PI 3.1415926536

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

DeclareEntryPoint (Erosion)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float a_1, a_2;

   if (Blended) {
      if (ShowKey) {
         maskBg = kTransparentBlack;
         retval = lerp (maskBg, Fgnd, Fgnd.a);
      }
      else {
         a_1 = Amount > 0.5 ? 1.0 - (sin (Amount * PI) / 2.0) : sin (Amount * PI) / 2.0;

         if (SwapDir) { a_2 = pow (Amount, 0.25); }
         else {
            a_1 = 1.0 - a_1;
            a_2 = pow (1.0 - Amount, 0.25);
         }

         retval = max (Bgnd.r, max (Bgnd.g, Bgnd.b)) < a_1 ? Fgnd : Bgnd;
         retval = lerp (Bgnd, retval, Fgnd.a * a_2);
         maskBg = Bgnd;
      }
   }
   else {
      maskBg = Fgnd;

      a_1 = Amount * 1.5;
      a_2 = max (0.0, a_1 - 0.5);
      a_1 = min (a_1, 1.0);

      float4 m_1 = (Fgnd + Bgnd) * 0.5;
      float4 m_2 = max (m_1.r, max (m_1.g, m_1.b)) >= a_1 ? Fgnd : m_1;

      retval = max (m_2.r, max (m_2.g, m_2.b)) >= a_2 ? m_2 : Bgnd;

      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

