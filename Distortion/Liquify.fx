// @Maintainer jwrl
// @Released 2023-06-19
// @Author schrauber
// @Created 2020-10-23

/**
 This is an effect that mimics the popular liquify effect in art software.  While those
 perform the distortion by means of warp meshes, this effect instead distorts by means
 of an offset from a frame reference point.  The difference in the end result is slight.

 The edge of the frame can be mirrored, the area outside the frame can be black, or can
 be made transparent for use in other blend or transform effects.  When in the two latter
 modes the edge of frame can be softened.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect  Liquify.fx
//
// Version history:
//
// Updated 2023-06-19 jwrl.
// Changed DVE reference to transform.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Liquify", "Stylize", "Distortion", "Distorts the image in a soft liquid manner", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Area, "Distortion Area", kNoGroup, "DisplayAsPercentage", 0.5, 0.0, 1.5);
DeclareFloatParam (Strength, "Strength", kNoGroup, "DisplayAsPercentage", 0.5, 0.0, 1.0);
DeclareFloatParam (Soft, "Edge softness", kNoGroup, "DisplayAsPercentage", 0.0, -0.01, 0.2);

DeclareFloatParam (Xcentre, "Effect centre", kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (Xdistort, "Distortion Direction", kNoGroup, "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (Ydistort, "Distortion Direction", kNoGroup, "SpecifiesPointY", 0.6, 0.0, 1.0);

DeclareIntParam (modeAlpha, "Background", kNoGroup, 1, "Mirrored foreground|Opaque black|Transparent");

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_OutputWidth);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 MirrorEdge (sampler S, float2 uv)
{
   float2 xy = 1.0.xx - abs (2.0 * (frac (uv / 2.0) - 0.5.xx));

   return tex2D (S, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Liquify)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;                    // Quit if we're outside frame boundaries - applies with unmatched aspect ratios

   // This section is a heavily optimised version of the original shader ps_mirror()

   float2 offset = float2 (Xcentre, 1.0 - Ycentre);                 // Reference point offset
   float2 distortion = offset - float2 (Xdistort, 1.0 - Ydistort);  // Distance of the distortion point from the offset

   offset = uv1 - offset;                                           // Calculate coordinates relative to offset point
   offset.x *= _OutputAspectRatio;                                  // Correct the X offset by the aspect ratio

   float displace = min (1.0, distance (0.0.xx, offset));           // Displacement of the chosen pixel from reference

   displace = (1.0 - cos (displace * PI)) * 0.5;                    // Distance curve rounded to soften distortion in the effect centre

   float area = max (0.0, Area - displace);                         // Limits the maximum range of the distortion (removes residual distortion)

   area = (1.0 - cos (area * HALF_PI)) * 0.5;                       // Soft edge of the distortion area (S-curve)
   displace += area;                                                // Offset the displacement with the corrected area value
   area *= Strength * Area * 1.5;                                   // Adjust the strength only within the active area
   distortion *= area / max (1e-9, displace);                       // Distortion decreases with distance from the effect centre

   float4 retval = MirrorEdge (Input, uv1 + distortion);            // Take a distorted pixel sample from the sampler

   if (modeAlpha != 0) {                                            // Return with mirrored frame edges if modeAlpha is zero
      // From here on was originally executed in a separate function.  With code optimisations that is no longer necessary.

      float2 xy = uv1 - 0.5.xx;                                     // Centre sampler coordinates around 0 as midpoint
      float2 soft = float2 (1.0, _OutputAspectRatio);               // Preload soft with aspect ratio adjustment

      soft *= Soft + (1.0 /_OutputWidth);                           // Calculate the softness range
      soft *= min (1.0.xx, (0.5.xx - abs (xy)) / max (1e-9, soft)); // Remove the interpolation (soft = 0) if the output pixel is on the frame border
      xy = 0.5.xx - abs (xy + distortion);                          // Distance from the edges of the output frame (negative values are outside)
      soft = min (1.0.xx, xy / max (1e-9, soft));                   // Reverses the direction of action.  Scale is proportional to distance from frame edge

      retval.a *= saturate (min (soft.x, soft.y));                  // Alpha edge softness ramps from 0 to 1

      // We now exit using a slightly restructured version of the exit code from the original shader ps_border().  This gives a visible change when transparent
      // mode is selected, which will result in exactly the same appearance if the result is blended with black as is obtained when opaque black is selected.

      if (modeAlpha == 2) {
         retval.a = pow (retval.a, 0.5);                            // Getting the square root of alpha means that subsequent blends will look the same
         retval.rgb *= retval.a;                                    // when we multiply by the RGB by alpha then use lerp to combine with a background
      }
      else {
         retval.rgb *= retval.a;                                    // This is the original ps_border() exit condition for opaque black
         retval.a = 1.0;
      }
   }

   return lerp (ReadPixel (Input, uv1), retval, tex2D (Mask, uv1).x);
}

