// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2015-10-12

/**
 This effect performs a blurred transition between two video sources.  It has been
 designed from the ground up to handle varying frame sizes and aspect ratios.  It
 can be used with standard video, title effects, image keys or other blended video
 layer(s).

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlurTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Blur transition", "Mix", "Blur transitions", "Uses a blur to drive the transition", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Blurriness, "Blurriness", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

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
#define HALF_PI   1.5707963268

#define STRENGTH  0.005

#define SAMPLES   30
#define SAMPSCALE 61

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
      Fgnd = lerp (Fgnd, Bgnd, saturate (Amount + Amount - 0.5));
   }

   return Fgnd;
}

DeclarePass (BlurX)
{
   float4 retval = tex2D (Mixed, uv3);

   float amount;

   if (Blended) {
      amount  = SwapDir ? 1.0 - Amount : Amount;
      amount *= Blurriness * STRENGTH / _OutputAspectRatio;
   }
   else amount = sin (saturate (Amount) * PI) * Blurriness * STRENGTH / _OutputAspectRatio;

   if (Blurriness > 0.0) {
      float2 blur = float2 (amount, 0.0);
      float2 xy1 = uv3, xy2 = uv3;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (Mixed, xy1);
         retval += tex2D (Mixed, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

DeclareEntryPoint (BlurTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float2 xy1 = uv3, xy2 = uv3;
   float2 blur;

   if (Blended) {
      maskBg = Bgnd;
      retval = tex2D (BlurX, uv3);

      if (Blurriness > 0.0) {
         blur = SwapDir ? float2 (0.0, (1.0 - Amount) * Blurriness * STRENGTH)
                        : float2 (0.0, Amount * Blurriness * STRENGTH);

         for (int i = 0; i < SAMPLES; i++) {
            xy1 -= blur;
            xy2 += blur;
            retval += tex2D (BlurX, xy1);
            retval += tex2D (BlurX, xy2);
         }
    
         retval /= SAMPSCALE;
      }

      retval.a *= SwapDir ? sin (saturate (Amount * 2.0) * HALF_PI)
                          : cos (saturate (Amount - 0.5) * PI);

      retval = lerp (Bgnd, retval, retval.a);
   }
   else {
      maskBg = Fgnd;
      retval = tex2D (BlurX, uv3);

      if (Blurriness > 0.0) {
         blur = float2 (0.0, sin (saturate (Amount) * PI) * Blurriness * STRENGTH);

         for (int i = 0; i < SAMPLES; i++) {
            xy1 -= blur;
            xy2 += blur;
            retval += tex2D (BlurX, xy1);
            retval += tex2D (BlurX, xy2);
         }
    
         retval /= SAMPSCALE;
      }
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

