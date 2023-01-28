// @Maintainer jwrl
// @Released 2023-01-28
// @Author khaver
// @Created 2014-08-30

/**
 FlareTran is a transition that dissolves through an over-exposure style flare.  Amongst
 other things it can be used to simulate the burn out effect that happens when a film
 camera stops.  With mixed size and aspect ratio media it may be necessary to experiment
 with swapping the target track and/or adjusting the strength of the effect to get the
 best result.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlareTran_Dx.fx
//
// Version history:
//
// Updated 2023-01-28 jwrl
// Updated to provide LW 2022 revised cross platform support.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flare Tran", "Mix", "Art transitions", "Dissolves between images through an over-exposure style of flare", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Swap, "Swap target track", kNoGroup, false);

DeclareFloatParam (CentreX, "Origin", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Origin", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (stretch, "Stretch", kNoGroup, kNoFlags, 5.0, 0.0, 10.0);
DeclareFloatParam (Timing, "Timing", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParamAnimated (adjust, "Progress", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

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
   float flare = 1.0 - abs ((adjust * 2.0) - 1.0);

   float4 Color = (Swap) ? tex2D (Bgd, uv3) : tex2D (Fgd, uv3);

   if (Color.r < 1.0 - flare) Color.r = 0.0;
   if (Color.g < 1.0 - flare) Color.g = 0.0;
   if (Color.b < 1.0 - flare) Color.b = 0.0;

   return Color;
}

DeclareEntryPoint ()
{
   float2 xy0 = float2 (CentreX, 1.0 - CentreY);
   float2 xy1 = uv3 - xy0;

   float Stretch = 10.0 - stretch;

   float2 amount = Stretch / float2 (_OutputWidth, _OutputHeight);
   float2 adj = amount;

   // jwrl: Rather than the hard cut between sources in khaver's original, I have amended
   // it to be a dissolve that occupies 10% of the transition duration.  The original was
   // source = (adjust < Timing) ? tex2D (Fgd, xy1) : tex2D (Bgd, xy1);

   float mid_trans = saturate ((adjust - (Timing * 0.5) - 0.25) * 10.0);

   float4 source = lerp (tex2D (Fgd, uv3), tex2D (Bgd, uv3), mid_trans);
   float4 ret = tex2D (Flare, xy0 + (xy1 * adj));

   for (int count = 1; count < 15; count++) {
      adj += amount;
      ret += tex2D (Flare, xy0 + (xy1 * adj)) * count * Strength;
   }

   ret /= 17.0;
   ret = ret + source;

   return saturate (float4 (ret.rgb, 1.0));
}

