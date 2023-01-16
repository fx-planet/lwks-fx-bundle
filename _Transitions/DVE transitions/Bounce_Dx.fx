// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 Enlarges the incoming image up to a preset size at the mid point then lets it fall
 back to normal size.  The transition can be linear or follow a preset smooth curve,
 and the midpoint of the transition is adjustable.  If the transition is outgoing it
 is necessary to set the type to bounce out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bounce_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bounce transition", "Mix", "DVE transitions", "Bounces the foreground up to a preset size then falls back", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Mid, "Midpoint", kNoGroup, "DisplayAsPercentage", 0.5, 0.1, 0.9);

DeclareIntParam (Ttype, "Transition type", kNoGroup, 0, "Bounce in|Bounce out");
DeclareIntParam (Curve, "Transition curve", kNoGroup, 0, "Linear|Curve 1|Curve 2");

DeclareIntParam (MidMode, "Mode", "Midpoint settings", 0, "Operate|Set up size");

DeclareFloatParam (MidScale, "Size", "Midpoint settings", "DisplayAsPercentage", 1.5, 0.0, 4.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.141592654
#define HALF_PI 1.570796327

#define ReadPixelOpaque(S, P) (IsOutOfBounds (P) ? float4 (0.0.xxx, 1.0) : tex2D (S, P))

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixelOpaque (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixelOpaque (Bg, uv2); }

DeclareEntryPoint (Bounce)
{
   float scale;

   if (MidMode) {
      scale = MidScale;
   }
   else {
      float amt_1 = smoothstep (0.0, Mid, Amount) + smoothstep (Mid, 1.0, Amount);
      float amt_2;

      // The above ranges the progress of the transition from 0.0 to 2.0, with 1.0
      // at the preset midpoint.  We now apply some simple trig curves if needed.

      if (Curve == 1) {
         amt_2 = (cos (amt_1 * PI) + 3.0) * 0.5;      // Swings between 2.0 > 1.0 > 2.0
         amt_1 = amt_1 > 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
      }
      else if (Curve == 2) {
         amt_2 = sin (amt_1 * HALF_PI);               // Swings between 0.0 > 1.0 > 0.0
         amt_1 = amt_1 < 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
      }

      // We now set up amt_1 to ramp from zero to 100% at the preset midpoint of the
      // transition and amt_2 to ramp from zero to 100% after that.

      amt_2 = max (amt_1 - 1.0, 0.0);
      amt_1 = min (amt_1, 1.0);

      // The next block of code sets s_1 to zero if we're transitioning in or 100% if
      // transitioning out.  The variable s_2 is set to the reverse of s_1.

      float s_1 = (float)Ttype;
      float s_2 = 1.0 - s_1;

      // Finally the transition ramps the scale from the start to the midpoint scale
      // value then ramps it from the midpoint value to the end scale.

      scale = lerp (lerp (s_1, MidScale, amt_1), s_2, amt_2);
   }

   // We now perform a simple scaling of the coordinates around the screen centre,
   // recover our foreground and background components, combine them and quit.

   float2 xy = ((uv3 - 0.5.xx) / scale) + 0.5.xx;

   float4 Fgnd, Bgnd;

   if (Ttype) {
      Fgnd = ReadPixel (Fgd, xy);
      Bgnd = ReadPixel (Bgd, uv3);
   }
   else {
      Bgnd = ReadPixel (Fgd, uv3);
      Fgnd = ReadPixel (Bgd, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

