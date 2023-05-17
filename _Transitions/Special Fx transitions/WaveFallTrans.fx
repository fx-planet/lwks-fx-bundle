// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2018-06-13

/**
 This is a transition that splits the foreground image into sinusoidal strips or waves
 and compresses them to or expands them from zero height.  The vertical centring can be
 adjusted so that the foreground expands symmetrically or asymmetrically.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WaveFallTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Wave fall transition", "Mix", "Special Fx transitions", "Expands or compresses the foreground to sinusoidal strips or waves", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Spacing, "Spacing", "Waves", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (centreY, "Vertical centre", "Waves", kNoFlags, 0.5, 0.0, 1.0);

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

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

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

DeclareEntryPoint (WaveFallTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float Width = 10.0 + (Spacing * 40.0);
   float amount, Height;

   float2 xy;

   if (Blended) {
      maskBg = Bgnd;

      if (SwapDir) {
         Height = ((1.0 - cos (HALF_PI - (Amount * HALF_PI))) * HEIGHT) + 1.0;
         amount = 1.0 - Amount;
      }
      else {
         Height = ((1.0 - cos (Amount * HALF_PI)) * HEIGHT) + 1.0;
         amount = Amount;
      }

      xy.x = saturate (uv3.x + (sin (Width * uv3.y * PI) * amount));
      xy.y = saturate (((uv3.y - centreY) * Height) + centreY);

      Fgnd = ReadPixel (Fgd, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a * saturate ((1.0 - amount) * 5.0));
   }
   else {
      maskBg = Fgnd;
      Height = ((1.0 - abs (cos (Amount * PI))) * HEIGHT) + 1.0;

      xy.x = saturate (uv3.x + (sin (Width * uv3.y * PI) * Amount));
      xy.y = saturate (((uv3.y - centreY) * Height) + centreY);

      retval = ReadPixel (Fgd, xy);
      xy.x = saturate (uv3.x + (sin (Width * uv3.y * PI) * (1.0 - Amount)));
      retval = lerp (retval, ReadPixel (Bgd, xy), saturate ((Amount - 0.25) * 2.0));
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

