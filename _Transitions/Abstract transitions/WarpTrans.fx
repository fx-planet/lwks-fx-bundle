// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2016-05-10

/**
 This is a dissolve that warps.  The warp is driven by the background image, and so will
 be different each time that it's used.  It supports titles and other blended effects.
 The two warp types are the original warp transition (now called smeared video) and the
 transmogrify transition, which is now called pixel cloud.  The original versions have
 now been withdrawn.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WarpTrans.fx
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
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Warp transition", "Mix", "Abstract transitions", "Warps into or out of titles, keys and images", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Warp type", kNoGroup, 0, "Smeared video|Pixel cloud");
DeclareFloatParam (Distortion, "Distortion", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (!Blended) return float4 ((ReadPixel (F, xy1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (B, xy2);
      Bgnd = ReadPixel (F, xy1);
   }
   else {
      Fgnd = ReadPixel (F, xy1);
      Bgnd = ReadPixel (B, xy2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (F, xy1) : ReadPixel (B, xy2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Warp_0

DeclarePass (Fg_0)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_0)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Warp_0)
{
   float4 Fgnd = tex2D (Fg_0, uv3);
   float4 Bgnd = tex2D (Bg_0, uv3);
   float4 maskBg, retval;

   float2 xy;

   float amount, warpFactor;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         retval = (Bgnd - 0.5.xxxx) * lerp (0.4, 3.2, Distortion);

         if (SwapDir) {
            warpFactor = 1.0 - sin (Amount * HALF_PI);
            amount = Amount;

            xy = uv3 + float2 (retval.y - 0.5, (retval.z - retval.x) * 2.0) * warpFactor;
         }
         else {
            warpFactor = 1.0 - cos (Amount * HALF_PI);
            amount = 1.0 - Amount;

            xy = uv3 + float2 ((retval.y - retval.z) * 2.0, 0.5 - retval.x) * warpFactor;
         }

         Fgnd = tex2D (Fg_0, xy);
         retval = lerp (Bgnd, Fgnd, amount);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, Fgnd.a);
   }
   else {
      warpFactor = sin (Amount * PI) * Distortion * 4.0;
      maskBg = Fgnd;

      xy = uv3 - float2 (Fgnd.b - Fgnd.r, Fgnd.g) * warpFactor;
      retval = tex2D (Fg_0, xy);
      xy = uv3 - float2 (Bgnd.b - Bgnd.r, Bgnd.g) * warpFactor;
      retval = lerp (retval, tex2D (Bg_0, xy), Amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Warp_1

DeclarePass (Fg_1)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_1)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Warp_1)
{
   float4 Fgnd = tex2D (Fg_1, uv3);
   float4 Bgnd = tex2D (Bg_1, uv3);
   float4 maskBg, retval;

   float scale = lerp (0.00054, 0.00055, Distortion);

   float2 xy, pixSize = uv3 * float2 (1.0, _OutputAspectRatio) * scale;

   float rand = frac (sin (dot (pixSize, float2 (18.5475, 89.3723))) * 54853.3754);

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         pixSize += ((uv3 * rand) - 0.5).xx;

         float amount;

         if (SwapDir) {
            amount = Amount;
            xy = saturate (pixSize + sqrt (1.0 - _Progress).xx);
            xy.y = 1.0 - xy.y;
         }
         else {
            amount = 1.0 - Amount;
            xy = saturate (pixSize + sqrt (_Progress).xx);
         }

         xy = lerp (xy, uv3, amount);
         Fgnd = tex2D (Fg_1, xy);
         retval = lerp (Bgnd, Fgnd, amount);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, Fgnd.a);
   }
   else {
      maskBg = Fgnd;
      xy = saturate (pixSize + (sqrt (1.0 - _Progress) - 0.5).xx + (uv3 * rand));

      float2 xy1 = lerp (uv3, saturate (pixSize + (sqrt (_Progress) - 0.5).xx + (uv3 * rand)), Amount);
      float2 xy2 = lerp (float2 (xy.x, 1.0 - xy.y), uv3, Amount);

      Fgnd = tex2D (Fg_1, xy1);
      Bgnd = tex2D (Bg_1, xy2);
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

