// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2014-08-30

/**
 FlareTran is a transition that dissolves through an over-exposure style flare.  Amongst
 other things it can be used to simulate the burn out effect that happens when a film
 camera stops.  With mixed size and aspect ratio media it may be necessary to experiment
 with swapping the target track and/or adjusting the strength of the effect to get the
 best result.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlareTran.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flare transition", "Mix", "Art transitions", "Dissolves between images through an over-exposure style of flare", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Swap, "Swap target track", kNoGroup, false);

DeclareFloatParam (CentreX, "Origin", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Origin", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (stretch, "Stretch", kNoGroup, kNoFlags, 5.0, 0.0, 10.0);
DeclareFloatParam (Timing, "Timing", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Flare)
{
   float flare = 1.0 - abs ((Amount * 2.0) - 1.0);

   float4 Color = (Swap) ? tex2D (Bgd, uv3) : tex2D (Fgd, uv3);

   if (Color.r < 1.0 - flare) Color.r = 0.0;
   if (Color.g < 1.0 - flare) Color.g = 0.0;
   if (Color.b < 1.0 - flare) Color.b = 0.0;

   return Color;
}

DeclareEntryPoint (FlareTran)
{
   float2 xy0 = float2 (CentreX, 1.0 - CentreY);
   float2 xy1 = uv3 - xy0;

   float Stretch = 10.0 - stretch;

   float2 amt = Stretch / float2 (_OutputWidth, _OutputHeight);
   float2 adj = amt;

   // jwrl: Rather than the hard cut between sources in khaver's original, I have amended
   // it to be a dissolve that occupies 10% of the transition duration.  The original was
   // source = (Amount < Timing) ? tex2D (Fgd, xy1) : tex2D (Bgd, xy1);

   float mid_trans = saturate ((Amount - (Timing * 0.5) - 0.25) * 10.0);

   float4 source = lerp (tex2D (Fgd, uv3), tex2D (Bgd, uv3), mid_trans);
   float4 ret = tex2D (Flare, xy0 + (xy1 * adj));

   for (int count = 1; count < 15; count++) {
      adj += amt;
      ret += tex2D (Flare, xy0 + (xy1 * adj)) * count * Strength;
   }

   ret /= 17.0;
   ret = saturate (ret + source);
   ret.a = 1.0;

   return lerp (tex2D (Fgd, uv3), ret, tex2D (Mask, uv3).x);
}

