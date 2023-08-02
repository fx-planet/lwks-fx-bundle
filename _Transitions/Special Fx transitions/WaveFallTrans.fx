// @Maintainer jwrl
// @Released 2023-08-02
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
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-13 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
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

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

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

DeclareEntryPoint (WaveFallTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float Width = 10.0 + (Spacing * 40.0);
   float amount, Height;

   float2 xy;

   if (Blended) {
      if (ShowKey) {
         maskBg = kTransparentBlack;
         retval = Fgnd;
      }
      else {
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
         retval = lerp (Bgnd, Fgnd, saturate ((1.0 - amount) * 5.0));
         retval.a = Fgnd.a;
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
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

