// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2020-07-19

/**
 This effect performs a whip pan style transition to bring an image onto or off the
 screen.  Unlike the blur dissolve effect, this effect also pans the foreground.  It
 is limited to producing vertical and horizontal whips only.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPanTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-07 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Whip pan transition", "Mix", "Blur transitions", "Uses a directional blur to simulate a whip pan between sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Mode, "Whip direction", kNoGroup, 0, "Left to right|Right to left|Top to bottom|Bottom to top");

DeclareFloatParam (Spread, "Spread", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

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

#define SAMPLES   60
#define SAMPSCALE 61

#define KSAMPLE   120
#define KSMPSCALE 121.0

#define STRENGTH  0.01

#define KSTRENGTH 0.00125

#define L_R       0
#define R_L       1
#define T_B       2
#define B_T       3

#define PI        3.14159265359
#define HALF_PI   1.5707963268

float2 _ang [4] = { { -1.5, 0.0 }, { 1.5, 0.0 }, { 0.0, -1.5 }, { 0.0, 1.5 } };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function is necessary because we can't set addressing modes

float4 MirrorPixel (sampler S, float2 xy)
{
   float2 xy1 = 1.0.xx - abs (2.0 * (frac (xy / 2.0) - 0.5.xx));

   return ReadPixel (S, xy1);
}

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

DeclareEntryPoint (WhipPanTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float2 blur1, blur2, xy1, xy2;

   float amount = saturate (Amount);   // Just in case someone types in silly numbers

   if (Blended) {
      maskBg = Bgnd;
      blur1 = _ang [Mode] * Spread;

      if (SwapDir) { blur1 *= (amount - 1.0); }
      else blur1 *= amount;

      xy1 = uv3 + blur1;
      Fgnd = ReadPixel (Fgd, xy1);

      if (Spread > 0.0) {
         blur1 *= STRENGTH;

         for (int i = 0; i < SAMPLES; i++) {
            xy1 += blur1;
            Fgnd += ReadPixel (Fgd, xy1);
         }
    
         Fgnd /= SAMPSCALE;
      }

      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }
   else {
      maskBg = Fgnd;

      blur1 = _ang [Mode] * Spread * 2.0;
      blur2 = blur1 * (amount - 1.0);

      blur1 *= amount;

      xy1 = uv3 + blur1;
      xy2 = uv3 + blur2;

      Fgnd = MirrorPixel (Fgd, xy1);
      Bgnd = MirrorPixel (Bgd, xy2);

      if (Spread > 0.0) {
         blur1 *= STRENGTH;
         blur2 *= STRENGTH;

         for (int i = 0; i < SAMPLES; i++) {
            xy1 += blur1;
            xy2 += blur2;
            Fgnd += MirrorPixel (Fgd, xy1);
            Bgnd += MirrorPixel (Bgd, xy2);
         }
    
         Fgnd /= SAMPSCALE;
         Bgnd /= SAMPSCALE;
      }

      retval = lerp (Fgnd, Bgnd, 0.5 - (cos (amount * PI) / 2.0));
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

