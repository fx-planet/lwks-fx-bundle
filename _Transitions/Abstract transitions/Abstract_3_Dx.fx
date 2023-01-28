// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This is the second effect based on an earlier effect Abstraction #1.  It uses the
 same pattern but applies the second half symmetrically into and out of the effect.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Abstract_3_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Abstraction #3", "Mix", "Abstract transitions", "An abstract geometric transition between two opaque sources", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (CentreX, "Mid position", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Mid position", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define XY_SCALE 0.25

#define PROGRESS 0.35
#define P_OFFSET 0.3125
#define P_SCALE  4

#define LOOP     50

#define TWO_PI   6.2831853072
#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint ()
{
   float amount   = (Amount < 0.5) ? 1.0 - Amount : Amount;
   float progress = pow ((amount * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate (amount * 2.0));
   float2 xy2 = abs (uv3 - xy1) * XY_SCALE;

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   float4 Fgnd = tex2D (Outgoing, uv3);
   float4 Bgnd = tex2D (Incoming, uv3);
   float4 blnd = lerp (Fgnd, Bgnd, progress);

   progress = Amount * 3.0;

   blnd = lerp (Fgnd, blnd, saturate (progress));

   return lerp (blnd, Bgnd, saturate (progress - 2.0));
}

