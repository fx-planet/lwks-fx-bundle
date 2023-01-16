// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is a modified version of my "Dissolve through colour" but is very much simpler to
 use.  Apply it as you would a dissolve, adjust the percentage of the dissolve that you
 want to be colour and set the colour to what you want.  It defaults to a black colour
 with a colour duration of 10% of the total effect duration, for a quick dissolve through
 black.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlatColour_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dissolve thru flat colour", "Mix", "Colour transitions", "Dissolves to a flat user defined colour then from that to the incoming image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (cDuration, "Duration", "Colour setup", kNoFlags, 0.1, 0.0, 1.0);

DeclareColourParam (Colour, "Colour", "Colour setup", kNoFlags, 0.0, 0.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FlatColour_Dx)
{
   float mix_bgd = min (1.0, (1.0 - Amount) * 2.0);
   float mix_fgd = min (1.0, Amount * 2.0);

   if (cDuration < 1.0) {
      float duration = 1.0 - cDuration;

      mix_bgd = min (1.0, mix_bgd / duration);
      mix_fgd = min (1.0, mix_fgd / duration);
   }
   else {
      mix_bgd = 1.0;
      mix_fgd = 1.0;
   }

   float4 retval = lerp (ReadPixel (Fg, uv1), Colour, mix_fgd);

   return lerp (ReadPixel (Bg, uv2), retval, mix_bgd);
}

