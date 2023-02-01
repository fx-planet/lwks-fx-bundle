// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This is a dissolve/wipe that uses sine & cos distortions to perform a rippling twist to
 transition between two images.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Twister_Dx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("The twister", "Mix", "Special Fx transitions", "Performs a rippling twist to transition between two video images", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (TransProfile, "Transition profile", kNoGroup, 1, "Left > right|Right > left"); 

DeclareFloatParam (Width, "Softness", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples, "Ripple amount", "Ripples", kNoFlags, 0.6, 0.0, 1.0);
DeclareFloatParam (Spread, "Ripple width", "Ripples", kNoFlags, 0.15, 0.0, 1.0);

DeclareFloatParam (Twists, "Twist amount", "Twists", kNoFlags, 0.25, 0.0, 1.0);

DeclareBoolParam (Show_Axis, "Show twist axis", "Twists", false);

DeclareFloatParam (Twist_Axis, "Twist axis", "Twists", kNoFlags, 0.5, 0.0, 1.0);

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
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Twister_Dx)
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;                 // Calculate softness range of the effect
   float maxVis = (TransProfile == 0) ? uv3.x : 1.0 - uv3.x;
   float minVis = range + maxVis - (Amount * (1.0 + range));            // The sense of the Amount parameter also has to change

   maxVis = range - minVis;                                             // Set up the maximum visibility

   float amount = saturate (maxVis / range);                            // Calculate the visibility
   float twistAxis = 1.0 - Twist_Axis;                                  // Invert the twist axis setting
   float T_Axis = uv3.y - twistAxis;                                    // Calculate the normalised twist axis

   float ripple_1 = max (0.0, RIPPLES * minVis);                        // Correct the ripples of the final effect
   float ripple_2 = max (0.0, RIPPLES * maxVis);
   float spread_1 = ripple_1 * Spread * SCALE;                          // Correct the spread
   float spread_2 = ripple_2 * Spread * SCALE;
   float modult_1 = pow (max (0.0, Ripples), 5.0) * ripple_1;           // Calculate the modulation factor
   float modult_2 = pow (max (0.0, Ripples), 5.0) * ripple_2;

   float offs_1 = sin (modult_1) * spread_1;                            // Calculate the vertical offset from the modulation and spread
   float offs_2 = sin (modult_2) * spread_2;
   float twst_1 = cos (modult_1 * Twists * 4.0);                        // Calculate the twists using cos () instead of sin ()
   float twst_2 = cos (modult_2 * Twists * 4.0);

   float2 xy1 = float2 (uv3.x, twistAxis + (T_Axis / twst_1) - offs_1); // Foreground X is uv3.x, foreground Y is modulated uv3.y
   float2 xy2 = float2 (uv3.x, twistAxis + (T_Axis / twst_2) - offs_2);

   float4 Bgnd = ReadPixel (Bgd, xy1);                                      // This version of the background has the modulation applied
   float4 Fgnd = ReadPixel (Fgd, xy2);                                      // Get the second partial composite
   float4 retval = lerp (Fgnd, Bgnd, amount);                           // Dissolve between the halves

   if (Show_Axis) {

      // To help with line-up this section produces a two-pixel wide line from the twist axis.  It's added to the output, and the
      // result is folded if it exceeds peak white.  This ensures that the line will remain visible regardless of the video content.

      retval.rgb -= max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0).xxx;
      retval.rgb  = max (0.0.xxx, retval.rgb) - min (0.0.xxx, retval.rgb);
   }

   return retval;
}

