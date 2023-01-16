// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 Abstraction #1 uses a pattern that developed from my attempt to create a series of
 radiating or collapsing circles to transition between two sources.  Initially I
 rather unexpectedly produced a simple X wipe and while plugging in different values
 to try and track down the error, stumbled across this.  I liked it so I kept it.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Abstract_1_Dx_2022.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Abstraction #1 2022+", "Mix", "Abstract transitions", "An abstract geometric transition between two opaque sources", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Wipe direction", kNoGroup, 0, "Forward|Reverse");

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

DeclarePass (Fwd_A)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Fwd_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Forward)
{
   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate (Amount * 2.0));
   float2 xy2 = abs (uv3 - xy1) * XY_SCALE;

   float progress = pow ((Amount * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   float4 Fgnd = tex2D (Fwd_A, uv3);
   float4 Bgnd = tex2D (Fwd_B, uv3);
   float4 blnd = lerp (Fgnd, Bgnd, progress);

   progress = Amount * 2.0;

   blnd = lerp (Fgnd, blnd, saturate (progress));

   return lerp (blnd, Bgnd, saturate (progress - 1.0));
}

DeclarePass (Rev_A)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Rev_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Reverse)
{
   float2 xy1 = lerp (0.5.xx, float2 (CentreX, 1.0 - CentreY), saturate ((1.0 - Amount) * 2.0));
   float2 xy2 = abs (uv3 - xy1) * XY_SCALE;

   float progress = pow (((1.0 - Amount) * PROGRESS) + P_OFFSET, P_SCALE);
   float ctime, stime;

   sincos (progress, stime, ctime);
   xy1 = 0.4.xx;

   for (int i = 0; i < LOOP; ++i) {
      xy2  = abs (xy2 - xy1);
      xy2  = xy2 * ctime - xy2.yx * stime;
      xy1 *= 0.95;
   }

   progress = abs ((frac (length (xy2) * LOOP) - 0.5) * 2.0 + 0.5);

   float4 Fgnd = tex2D (Rev_A, uv3);
   float4 Bgnd = tex2D (Rev_B, uv3);
   float4 blnd = lerp (Fgnd, Bgnd, progress);

   progress = Amount * 3.0;

   blnd = lerp (Fgnd, blnd, saturate (progress));

   return lerp (blnd, Bgnd, saturate (progress - 2.0));
}

