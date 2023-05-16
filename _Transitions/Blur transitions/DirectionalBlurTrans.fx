// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2021-06-20

/**
 This effect applies a directional (motion) blur to the components, the angle and
 strength of which can be adjusted.  It then progressively reduces the blur to
 reveal the incoming image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalBlurTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Directional blur transition", "Mix", "Blur transitions", "Directionally blurs the foreground as it fades in or out", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Blurriness, "Blurriness", "Blur settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle, "Angle", "Blur settings", kNoFlags, 0.0, -180.00, 180.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI        3.1415926536

#define SAMPLES   30
#define SAMPSCALE 61

#define STRENGTH  0.005

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Bgnd, Fgnd = ReadPixel (Fg, uv1);

   if (Blended) {
      if ((Source == 0) && SwapDir) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (Bg, uv2);
      }
      else Bgnd = ReadPixel (Bg, uv2);

      if (Source == 0) {
         Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
         Fgnd.rgb *= Fgnd.a;
      }
      else if (Source == 1) {
         Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
         Fgnd.rgb /= Fgnd.a;
      }

      if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;
   }
   else Fgnd.a = 1.0;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 retval;

   if (Blended && SwapDir && (Source == 0)) { retval = ReadPixel (Fg, uv1); }
   else retval = ReadPixel (Bg, uv2);

   if (!Blended) retval.a = 1.0;

   return retval;
}

DeclarePass (Mixed)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   if (!Blended ) {
      float4 Bgnd = tex2D (Bgd, uv3);

      float amount = pow (1.0 - (abs (Amount - 0.5) * 2.0), 5.0) / 2.0;

      if (Amount > 0.5) amount = 1.0 - amount;
      Fgnd = lerp (Fgnd, Bgnd, amount);
   }

   return Fgnd;
}

DeclareEntryPoint (DirectionalBlurTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval = tex2D (Mixed, uv3);
   float4 maskBg;

   float2 blur, xy1 = uv3, xy2 = uv3;

   if (Blended) {
      maskBg = Bgnd;

      if (Blurriness > 0.0) {
         if (SwapDir) {
            sincos (radians (Angle), blur.y, blur.x);
            blur *= (1.0 - saturate (Amount)) * Blurriness * STRENGTH;
         }
         else {
            sincos (radians (Angle + 180.0), blur.y, blur.x);
            blur *= saturate (Amount) * Blurriness * STRENGTH;
         }

         blur.y *= _OutputAspectRatio;

         for (int i = 0; i < SAMPLES; i++) {
            xy1 += blur;
            xy2 -= blur;
            retval += tex2D (Mixed, xy1);
            retval += tex2D (Mixed, xy2);
         }

         retval /= SAMPSCALE;
      }

      retval.a *= SwapDir ? saturate (((Amount - 0.5) * 3.0) + 0.5)
                          : 1.0 - saturate (((Amount - 0.5) * 3.0) + 0.5);
      retval = lerp (Bgnd, retval, retval.a);
   }
   else {
      maskBg = Fgnd;

      if (Blurriness > 0.0) {
         sincos (radians (Angle), blur.y, blur.x);

         blur   *= sin (saturate (Amount) * PI) * Blurriness * STRENGTH;
         blur.y *= _OutputAspectRatio;

         for (int i = 0; i < SAMPLES; i++) {
            xy1 += blur;
            xy2 -= blur;
            retval += tex2D (Mixed, xy1);
            retval += tex2D (Mixed, xy2);
         }

         retval /= SAMPSCALE;
      }
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

