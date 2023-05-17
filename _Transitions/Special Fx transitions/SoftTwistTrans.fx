// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2017-11-08

/**
 This is a dissolve/wipe that uses sine & cos distortions to perform a rippling twist to
 transition between two images or to establish or remove the blended foreground.  The
 range of effect variations possible with different combinations of settings is almost
 inifinite.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftTwistTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Soft twist transition", "Mix", "Special Fx transitions", "Performs a rippling twist to transition between two video images", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (TransProfile, "Transition profile", kNoGroup, 1, "Left > right profile A|Left > right profile B|Right > left profile A|Right > left profile B");

DeclareFloatParam (Width, "Softness", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples, "Ripple amount", "Ripples", kNoFlags, 0.6, 0.0, 1.0);
DeclareFloatParam (Spread, "Ripple width", "Ripples", kNoFlags, 0.15, 0.0, 1.0);

DeclareFloatParam (Twists, "Twist amount", "Twists", kNoFlags, 0.25, 0.0, 1.0);

DeclareBoolParam (Show_Axis, "Show twist axis", "Twists", false);

DeclareFloatParam (Twist_Axis, "Twist axis", "Twists", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputHeight);

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

DeclareEntryPoint (TwisterTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float2 xy;

   float range = max (0.0, Width * SOFTNESS) + OFFSET;         // Calculate softness range of the effect
   float amount, maxVis, minVis, modulate, offset;
   float ripples, spread, T_Axis, twistAxis, twists;

   int Mode = (int) fmod ((float)TransProfile, 2.0);

   if (Blended && !SwapDir) {
      maxVis = (Mode == TransProfile) ? 1.0 - uv3.x : uv3.x;
      maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;
      twistAxis = 1.0 - Twist_Axis;
      ripples = max (0.0, RIPPLES * (range - maxVis));
   }
   else {
      maxVis = Mode == TransProfile ? uv3.x : 1.0 - uv3.x;
      minVis = range + maxVis - (Amount * (1.0 + range));         // The sense of the Amount parameter has to change

      if (Blended) {
         maxVis = Amount * (1.0 + range) - maxVis;
         twistAxis = 1.0 - Twist_Axis;
         ripples = max (0.0, RIPPLES * (range - maxVis));
      }
      else {
         maxVis = range - minVis;                                 // Set up the maximum visibility
         twistAxis = 1.0 - Twist_Axis;                            // Invert the twist axis setting
         ripples = max (0.0, RIPPLES * minVis);                   // Correct the ripples of the final effect
      }
   }

   amount = saturate (maxVis / range);                            // Calculate the visibility
   T_Axis = uv3.y - twistAxis;                                    // Calculate the normalised twist axis

   spread   = ripples * Spread * SCALE;                           // Correct the spread
   modulate = pow (max (0.0, Ripples), 5.0) * ripples;            // Calculate the modulation factor
   offset   = sin (modulate) * spread;                            // Calculate the vertical offset from the modulation and spread
   twists   = cos (modulate * Twists * 4.0);                      // Calculate the twists using cos () instead of sin ()

   xy = float2 (uv3.x, twistAxis + (T_Axis / twists) - offset);   // Foreground X is uv3.x, foreground Y is modulated uv3.y

   if (Blended) {
      maskBg = Bgnd;
      xy.y += offset * float (Mode * 2);

      Fgnd = ReadPixel (Fgd, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a * amount);
   }
   else {
      maskBg = Fgnd;
      Bgnd = ReadPixel (Bgd, xy);                                 // This version of the background has the modulation applied

      ripples  = max (0.0, RIPPLES * maxVis);
      spread   = ripples * Spread * SCALE;
      modulate = pow (max (0.0, Ripples), 5.0) * ripples;
      offset   = sin (modulate) * spread;
      twists   = cos (modulate * Twists * 4.0);

      xy = float2 (uv3.x, twistAxis + (T_Axis / twists) - offset);

      Fgnd = ReadPixel (Fgd, xy);                                 // Get the second partial composite
      retval = lerp (Fgnd, Bgnd, amount);                         // Dissolve between the halves
   }

   retval = lerp (maskBg, retval, tex2D (Mask, uv3).x);           // Mask now, because we can't afford to mask the twist axis

   if (Show_Axis) {

      // To help with line-up this section produces a two-pixel wide line from the twist axis.  It's added to the output, and the
      // result is folded if it exceeds peak white.  This ensures that the line will remain visible regardless of the video content.

      retval.rgb -= max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0).xxx;
      retval.rgb  = max (0.0.xxx, retval.rgb) - min (0.0.xxx, retval.rgb);
   }

   return retval;
}

