// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This is a modified version of my "Dissolve through colour" but is very much simpler to
 use.  Apply it as you would a dissolve, adjust the percentage of the dissolve that you
 want to be colour and set the colour to what you want.  It defaults to a black colour
 with a colour duration of 10% of the total effect duration, for a quick dissolve through
 black.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlatColour_Dx.fx
//
// Version history:
//
// Built 2023-01-31 jwrl.
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

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

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

   float4 Fgnd = tex2D (Outgoing, uv3);
   float4 Bgnd = tex2D (Incoming, uv3);

   Fgnd = lerp (Fgnd, Colour, mix_fgd);

   float4 retval = lerp (Bgnd, Fgnd, mix_bgd);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;
      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

