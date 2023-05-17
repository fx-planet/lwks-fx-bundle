// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2017-10-30

/**
 This is a dissolve/wipe that uses a sine distortion to do a left-right or right-left
 transition between the inputs.  The phase can also be offset by 180 degrees.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SineTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sine transition", "Mix", "Special Fx transitions", "Uses a sine distortion to do a left-right or right-left transition between the inputs", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Direction, "Direction", kNoGroup, 0, "Left to right|Right to left");

DeclareIntParam (Mode, "Distortion", "Ripples", 0, "Normal|Inverted");

DeclareFloatParam (Softness, "Softness", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples, "Ripples", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Spread, "Spread", "Ripples", kNoFlags, 0.5, 0.0, 1.0);

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

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

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

DeclareEntryPoint (SineTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float maxVis, x;

   float range  = max (0.0, Softness * SOFTNESS) + OFFSET;

   if (Blended && !SwapDir) {
      maxVis = (1.0 - Amount) * (1.0 + range);
      x = (Direction == 0) ? 1.0 - uv3.x : uv3.x;
   }
   else {
      maxVis = Amount * (1.0 + range);
      x = (Direction == 0) ? uv3.x : 1.0 - uv3.x;
   }

   float minVis = maxVis - range;
   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? uv3 + float2 (0.0, offset) : uv3 - float2 (0.0, offset);

   if (Blended) {
      maskBg = Bgnd;
      Fgnd = ReadPixel (Fgd, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a * amount);
   }
   else {
      maskBg = Fgnd;
      Bgnd = ReadPixel (Bgd, xy);
      retval = lerp (Fgnd, Bgnd, amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

