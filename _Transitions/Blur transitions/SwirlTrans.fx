// @Maintainer jwrl
// @Released 2023-08-02
// @Author schrauber
// @Author jwrl
// @Created 2017-11-13

/**
 This swirl effect is a combination of schrauber's and jwrl's swirl mixes.   It
 transitions to the incoming clip by causing it to rise from the depths like a
 geyser.  During the first half of the effect the whirl begins and increases its
 rotation to a maximum at the 50% point.  A zoom in is also applied during this
 phase.  During the second half the zoom oscillates as the incoming image mixes
 in.  Finally, the zoom reduces to zero as the transition completes.

 If the spin rotation is reduced to zero the outgoing image pinches to the centre
 and holds up to the 50% point.  It then bounces back and produces ripples in the
 outgoing image which cause it to transition from the centre to the incoming image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SwirlTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Swirl transition", "Mix", "Blur transitions", "A swirl mix effect used as a transition between video sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Amplitude, "Swirl depth", "Rotation", kNoFlags, 0.5, -1.0, 1.0);
DeclareFloatParam (Rate, "Revolutions", "Rotation", kNoFlags, 2.5, -10.0, 10.0);
DeclareFloatParam (FillGaps, "Fill gaps", "Rotation", kNoFlags, 0.9, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareFloatParam (Start, "Start angle", "Blend swirl", kNoFlags, 0.0, -360.0, 360.0);
DeclareFloatParam (CentreX, "Spin centre", "Blend swirl", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Spin centre", "Blend swirl", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define CENTRE     0.5

#define FREQ       20.0      // Frequency of the zoom oscillation
#define PHASE      0.5       // 90° phase shift of the zoom oscillation. Valid from progress 0.75
#define AREA       100.0     // Area of the regional zoom
#define ZOOMPOWER  12.0

#define TWO_PI  6.2831853072
#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rotation (sampler Source, float2 uv)
{ 
   float2 vCT = (uv - CENTRE);         // Vector between Center and Texel

   // ------ ROTATION --------

   // WhirlCenter:  Number of revolutions in the center. With increasing distance from the center, this number of revolutions decreases.
   // WhirlOutside: Unrolling from the outside. The number corresponds to the rotation in the center, with an undistorted rotation. (undistorted: WhirlOutside = WhirlCenter)

   float WhirlCenter  = (1.0 - cos (Amount * PI)) * 0.5;                // Rotation starts slowly, gets faster, and ends slowly (S-curve).
   float WhirlOutside = (1.0 - cos (saturate ((Amount * 2.0 - 1.0)) * PI)) * 0.5; // Unrolling starts slowly from the middle of the effect runtime (S-curve).

   WhirlCenter -= WhirlOutside;
   WhirlCenter *= length (float2 (vCT.x, vCT.y / _OutputAspectRatio));  // Distance from the center
   WhirlCenter += WhirlOutside;

   float angle = radians (WhirlCenter * round (Rate) * 360.0);
   float Tsin, Tcos;    // Sine and cosine of the set angle.

   sincos (angle, Tsin , Tcos);
   vCT.x *= _OutputAspectRatio;       // Vector between Center and Texel, corrected the aspect ratio.

   // Position vectors

   float2 posRate = float2 ((vCT.x * Tcos) - (vCT.y * Tsin), (vCT.x * Tsin) + (vCT.y * Tcos)); 

   posRate = float2 (posRate.x / _OutputAspectRatio, posRate.y) + CENTRE;

   // ------ OUTPUT-------

   float overEdge = (pow (1.0 - FillGaps, 2.0) * 1000.0);         // Setting characteristic of the border width

   float4 retval = tex2D (Source, posRate);

   posRate = max (abs (posRate - CENTRE) - CENTRE, 0.0);
   overEdge = saturate (overEdge * max (posRate.x, posRate.y));

   return lerp (retval, float4 (0.0.xxx, retval.a), overEdge);
}

float4 fn_zoom (sampler Twist, float2 uv, out float distC)
{ 
   // --- Automatic zoom change in effect progress ----
   // Amount 0    to  0.5 : increasing negative zoom
   // Amount 0.5  to  0.75: constant zoom
   // Amount 0.75 to  1   : Oscillating zoom, subside

   float zoom = min (Amount, 0.5);                                // negative zoom (Amount 0 to 0.75)

   zoom = Amplitude * (1.0 - cos (zoom * TWO_PI)) * 0.5;          // Creates a smooth zoom start & zoom end (S-curve) from Amount 0 to 0.5

   if (Amount > 0.75) {                                           // Amount 0.75 to 1 (Swinging zoom)
      zoom = sin (((Amount * FREQ) - PHASE) * PI);                // Amplitude oscillation
      zoom *= Amplitude * saturate ((1.0 - Amount) * 4.0);        // Damping the zoom from progress 0.75   The formula scales the progress range from 0.75 ... 1   to   1 ... 0; 
   }

   // ------  Inverted regional zoom ------

   float2 vCT = CENTRE - uv;                                      // Vector between Center and Texel

   distC = length (float2 (vCT.x * _OutputAspectRatio, vCT.y));

   float distortion  = (distC * ((distC * AREA) + 1.0)) + 1.0; 
   float distortion2 = min (length (vCT), CENTRE) - CENTRE;       // The limitation to CENTRE (0.5) preventing distortion of the corners.

   zoom /= max (distortion, 1e-6);

   float2 posAmplitude = uv + (distortion2 * vCT * zoom * ZOOMPOWER); 

   // ------ OUTPUT-------

   return tex2D (Twist, posAmplitude);           
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclarePass (FgTwist)
{ return Blended ? kTransparentBlack : fn_rotation (Fgd, uv3); }

DeclarePass (BgTwist)
{ return Blended ? kTransparentBlack : fn_rotation (Bgd, uv3); }

DeclareEntryPoint (SwirlTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float amount;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         amount = SwapDir ? Amount : 1.0 - Amount;

         float2 centre = float2 (CentreX, 1.0 - CentreY);
         float2 xy, xy1 = uv3 - centre;

         float3 spin = float3 (Amplitude, Start, Rate) * (1.0 - amount);

         float angle = (length (xy1) * spin.x * TWO_PI) + radians (spin.y);
         float scale0, scale90;

         amount = sin (amount * HALF_PI);
         sincos (angle + (spin.z * _Length * PI), scale90, scale0);
         xy = (xy1 * scale0) - (float2 (xy1.y, -xy1.x) * scale90) + centre;

         retval = ReadPixel (Fgd, xy);
         retval.a *= amount;
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      maskBg = Fgnd;

      float Cdist;

      float4 FgZoom = fn_zoom (FgTwist, uv3, Cdist);  // Recover the foreground component
      float4 BgZoom = fn_zoom (BgTwist, uv3, Cdist);  // Recover the background component

      amount = saturate ((Amount - 0.78) * 6.0);      // Scale the progress range from > 0.78 to 0 ... 1

      amount = saturate (amount / Cdist);             // Divide amount by distance from the center
      amount = (1.0 - cos (amount * PI)) * 0.5;       // Makes the spatial boundary of the blended clips narrower.
      amount = (1.0 - cos (amount * PI)) * 0.5;       // Makes the spatial boundary of the amounted clips even narrower.

      retval = lerp (FgZoom, BgZoom, amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

