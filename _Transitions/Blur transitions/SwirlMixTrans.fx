// @Maintainer jwrl
// @Released 2023-01-28
// @Author schrauber
// @Created 2017-11-13

/**
 This effect transitions to the incoming clip by causing it to rise from the depths
 like a geyser.  During the first half of the effect the whirl begins and increases
 its rotation to a maximum at the 50% point.  A zoom in is also applied during this
 phase.  During the second half the zoom oscillates as the incoming image mixes in.
 Finally, the zoom reduces to zero as the transition completes.

 If the spin rotation is reduced to zero the outgoing image pinches to the centre
 and holds up to the 50% point.  It then bounces back and produces ripples in the
 outgoing image which cause it to transition from the centre to the incoming image.

 Phase of the transition effect (schrauber's original notes):

 Progress 0 to 0.5:
    -Whirl begins to wind, and reaches the highest speed of rotation at Progress 0.5.
    -Increasing negative zoom in the center.

 Progress 0.5 to 1: Unroll
    -Progress 0.5  to 0.75 : constant zoom
    -Progress 0.75 to 1    : Positive zoom (geyser), oscillating zoom, subside
    -Progress 0.78 to 0.95 : Mixing the inputs, starting in the center

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SwirlMix_Dx.fx
//
// Version history:
//
// Updated 2023-01-16 jwrl
// Updated to provide LW 2022 revised cross platform support.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Swirl mix", "Mix", "Blur transitions", "Uses a spin effect to transition between two sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Progress, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Zoom, "Swirl depth", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Spin, "Revolutions", "Rotation", kNoFlags, 10.0, -62.0, 62.0);
DeclareFloatParam (Border, "Fill gaps", "Rotation", kNoFlags, 0.9, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define PI      3.1415926536
#define TWO_PI  6.2831853072

#define CENTRE     0.5

#define FREQ       20.0      // Frequency of the zoom oscillation
#define PHASE      0.5       // 90 ° phase shift of the zoom oscillation. Valid from progress 0.75
#define AREA       100.0     // Area of the regional zoom
#define ZOOMPOWER  12.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rotation (sampler Source, float2 uv)
{ 
   float2 vCT = (uv - CENTRE);        // Vector between Center and Texel

   // ------ ROTATION --------

   // WhirlCenter:  Number of revolutions in the center. With increasing distance from the center, this number of revolutions decreases.
   // WhirlOutside: Unrolling from the outside. The number corresponds to the rotation in the center, with an undistorted rotation. (undistorted: WhirlOutside = WhirlCenter)

   float WhirlCenter  = (1.0 - cos (Progress * PI)) * 0.5;                          // Rotation starts slowly, gets faster, and ends slowly (S-curve).
   float WhirlOutside = (1.0 - cos (saturate ((Progress * 2.0 - 1.0)) * PI)) * 0.5; // Unrolling starts slowly from the middle of the effect runtime (S-curve).

   WhirlCenter -= WhirlOutside;
   WhirlCenter *= length (float2 (vCT.x, vCT.y / _OutputAspectRatio));              // Distance from the center
   WhirlCenter += WhirlOutside;

   float angle = radians (WhirlCenter * round (Spin) * 360.0);
   float Tsin, Tcos;    // Sine and cosine of the set angle.

   sincos (angle, Tsin , Tcos);
   vCT.x *= _OutputAspectRatio;       // Vector between Center and Texel, corrected the aspect ratio.

   // Position vectors

   float2 posSpin = float2 ((vCT.x * Tcos) - (vCT.y * Tsin), (vCT.x * Tsin) + (vCT.y * Tcos)); 

   posSpin = float2 (posSpin.x / _OutputAspectRatio, posSpin.y) + CENTRE;

   // ------ OUTPUT-------

   float overEdge = (pow (1.0 - Border, 2.0) * 1000.0);       // Setting characteristic of the border width

   float4 retval = tex2D (Source, posSpin);

   posSpin = max (abs (posSpin - CENTRE) - CENTRE, 0.0);
   overEdge = saturate (overEdge * max (posSpin.x, posSpin.y));

   return lerp (retval, float4 (0.0.xxx, retval.a), overEdge);
}

float4 fn_zoom (sampler Twist, float2 uv, out float distC)
{ 
   // --- Automatic zoom change in effect progress ----
   // Progress 0    to  0.5 : increasing negative zoom
   // Progress 0.5  to  0.75: constant zoom
   // Progress 0.75 to  1   : Oscillating zoom, subside

   float zoom = min (Progress, 0.5);                          // negative zoom (Progress 0 to 0.75)

   zoom = Zoom * (1.0 - cos (zoom * TWO_PI)) * 0.5;           // Creates a smooth zoom start & zoom end (S-curve) from Progress 0 to 0.5

   if (Progress > 0.75) {                                     // Progress 0.75 to 1 (Swinging zoom)
      zoom = sin (((Progress * FREQ) - PHASE) * PI);          // Zoom oscillation
      zoom *= Zoom * saturate ((1.0 - Progress) * 4.0);       // Damping the zoom from progress 0.75   The formula scales the progress range from 0.75 ... 1   to   1 ... 0; 
   }

   // ------  Inverted regional zoom ------

   float2 vCT = CENTRE - uv;                                  // Vector between Center and Texel

   distC = length (float2 (vCT.x * _OutputAspectRatio, vCT.y));

   float distortion  = (distC * ((distC * AREA) + 1.0)) + 1.0; 
   float distortion2 = min (length (vCT), CENTRE) - CENTRE;   // The limitation to CENTRE (0.5) preventing distortion of the corners.

   zoom /= max (distortion, 1e-6);

   float2 posZoom = uv + (distortion2 * vCT * zoom * ZOOMPOWER); 

   // ------ OUTPUT-------

   return tex2D (Twist, posZoom);           
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FgSource)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (FgTwist)
{ return fn_rotation (FgSource, uv3); }

DeclarePass (BgSource)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (BgTwist)
{ return fn_rotation (BgSource, uv3); }

DeclareEntryPoint (SwirlMix_Dx)
{
   float Cdist;

   float4 FgZoom = fn_zoom (FgTwist, uv3, Cdist);     // Recover the foreground component
   float4 BgZoom = fn_zoom (BgTwist, uv3, Cdist);     // Recover the background component

   float mix = saturate ((Progress - 0.78) * 6.0);    // Scale the progress range from > 0.78 to 0 ... 1

   mix = saturate (mix / Cdist);                      // Divide mix by distance from the center
   mix = (1.0 - cos (mix * PI)) * 0.5;                // Makes the spatial boundary of the blended clips narrower.
   mix = (1.0 - cos (mix * PI)) * 0.5;                // Makes the spatial boundary of the mixed clips even narrower.

   return lerp (FgZoom, BgZoom, mix);
}

