// @Maintainer jwrl
// @Released 2023-06-19
// @Author khaver
// @Created 2016-10-19

/**
 This is a delta mask or difference matte effect which  subtracts the background from the
 foreground to produce an image with transparency.  This can then be used with external
 blend or transform effects in the same way as a title or image key.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeltaMask.fx
//
// Version history:
//
// Updated 2023-06-19 jwrl.
// Changed DVE reference to transform.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Delta mask", "Key", "Key Extras", "This delta mask effect removes the background from the foreground.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (fg, bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Show, "Show", kNoGroup, false);
DeclareBoolParam (SplitScreen, "Split Screen", kNoGroup, false);
DeclareBoolParam (SwapTracks, "Swap Tracks", kNoGroup, false);

DeclareBoolParam (Red, "Red", kNoGroup, true);
DeclareFloatParam (RedThreshold, "Red Threshold", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (Green, "Green", kNoGroup, true);
DeclareFloatParam (GreenThreshold, "Green Threshold", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (Blue, "Blue", kNoGroup, true);
DeclareFloatParam (BlueThreshold, "Blue Threshold", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (MasterThreshold, "Master Threshold", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (BackgroundGain, "Background Gain", kNoGroup, "DisplayAsPercentage", 1.0, 0.0, 2.0);

DeclareBoolParam (InvertKey, "Invert Key", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (DeltaMask)
{
   float4 Fgd, Bgd;

   float2 xy;

   float ralph, galph, balph, alpha;

   if (SwapTracks) {
      Bgd = ReadPixel (fg, uv1);
      Fgd = ReadPixel (bg, uv2);
      xy = uv2;
   }
   else {
      Bgd = ReadPixel (bg, uv2);
      Fgd = ReadPixel (fg, uv1);
      xy = uv1;
   }

   Bgd *= BackgroundGain;

   if (SplitScreen && !Show) return (uv1.x < 0.5) ? Fgd : Bgd;

   ralph = abs (Bgd.r - Fgd.r);
   galph = abs (Bgd.g - Fgd.g);
   balph = abs (Bgd.b - Fgd.b);

   if (!Red) ralph = 0.0;
   if (!Green) galph = 0.0;
   if (!Blue) balph = 0.0;

   alpha = (ralph <= (RedThreshold + MasterThreshold))
        && (galph <= (GreenThreshold + MasterThreshold))
        && (balph <= (BlueThreshold + MasterThreshold)) ? 0.0 : 1.0;

   if (InvertKey) alpha = 1.0 - alpha;

   alpha *= tex2D (Mask, xy).x;

   if (!alpha) Fgd.rgb = kTransparentBlack;

   return (Show) ? float4 (alpha.xxx, 1.0) : float4 (Fgd.rgb, alpha);
}

