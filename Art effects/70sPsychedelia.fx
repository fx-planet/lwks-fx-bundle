// @Maintainer jwrl
// @Released 2022-12-31
// @Author jwrl
// @Created 2022-12-31

/**
 70s Psychedelia (70sPsychedelia.fx) creates a wide range of contouring effects from your
 original image.  Mixing over the original image can be adjusted from 0% to 100%, and the
 hue, saturation, and contour pattern can be tweaked.  The contours can also be smudged
 by a variable amount.

 This is an entirely original effect, but feel free to do what you will with it.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 70sPsychedelia.fx
//
// Version history:
//
// Built 2022-12-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("70s Psychedelia", "Stylize", "Art Effects", "An extreme highly adjustable posterization effect", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Pattern mix", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Contouring, "Contour level", kNoGroup, kNoFlags, 12.0, 0.0, 12.0);
DeclareFloatParam (Smudge, "Smudger", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareColourParam (ColourOne, "Colour one", "Colours", kNoFlags, 1.0, 0.0, 1.0, 1.0);
DeclareColourParam (ColourTwo, "Colour two", "Colours", kNoFlags, 1.0, 1.0, 0.0, 1.0);
DeclareColourParam (ColourBase, "Base colour", "Colours", kNoFlags, 1.0, 0.0, 0.5, 1.0);

DeclareFloatParam (HueShift, "Hue", "Colours", kNoFlags, 0.0, -180.0, 180.0);
DeclareFloatParam (Saturation, "Saturation", "Colours", "DisplayAsPercentage", 1.5, 0.0, 2.0);
DeclareFloatParam (Gain, "Gain", "Colours", "DisplayAsPercentage", 2.0, 0.0, 2.0);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_OutputWidth);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA_VAL float3 (0.3, 0.59, 0.11)
#define HUE      float3 (1.0, 2.0 / 3.0, 1.0 / 3.0)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Video)
{ return ReadPixel (Inp, uv1); }

DeclarePass (Contours)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float angle = 0.0;

   // The first thing that is done is to blur the image slightly.  This is done to
   // minimise any noise, aliassing, or other video artefacts before contouring.

   float2 halftex = float2 (1.0, _OutputAspectRatio) / (_OutputWidth + _OutputWidth);
   float2 scale   = halftex * 4.25;
   float2 xy, xy1 = uv2 + halftex;

   float4 retval = tex2D (Video, uv2);

   for (int i = 0; i < 12; i++) {
      sincos (angle, xy.y, xy.x);
      xy *= scale;
      retval += tex2D (Video, xy + xy1);
      angle += 30.0;
   }

   retval /= 13.0;

   // The next block of code creates the contours, mixing the three colours

   float amtC = max (Contouring, 0.0) + 0.325;
   float Col1 = frac ((0.5 + retval.r + retval.b) * 2.242 * amtC);
   float Col2 = frac ((0.5 + retval.g) * amtC);

   float3 rgb = max (ColourBase, max ((ColourOne * Col1), (ColourTwo * Col2))).rgb;

   rgb += min (ColourBase, min (ColourOne * Col1, ColourTwo * Col2)).rgb;
   rgb /= 2.0;

   // This is a synthetic luminance value to preserve contrast when using
   // heavily saturated colours.

   float luma  = saturate (Col1 * 0.333333 + Col2 * 0.666667);

   // From here on we use a modified version of RGB-HSV-RGB conversion to process
   // the hue and saturation adjustments.  The V component is replaced with the
   // synthetic luma value, which enhances the contouring produced by the effect.

   float4 p = lerp (float4 (rgb.bg, -1.0, 2.0 / 3.0),
                    float4 (rgb.gb, 0.0, -1.0 / 3.0), step (rgb.b, rgb.g));
   float4 q = lerp (float4 (p.xyw, rgb.r), float4 (rgb.r, p.yzx), step (p.x, rgb.r));

   float d = q.x - min (q.w, q.y);

   float3 hsv = float3 (abs (q.z + (q.w - q.y) / (6.0 * d)), d / q.x, luma);

   // Hue shift and saturation is now adjusted using frac() to control overflow in
   // the hue.  Range limiting for saturation only needs to ensure it's positive.

   hsv.x += (clamp (HueShift, -180.0, 180.0) / 360.0) + 1.0;
   hsv.x  = frac (hsv.x);
   hsv.y *= max (Saturation, 0.0);

   // Finally we convert back to RGB, adjust the gain and get out.

   rgb = saturate (abs (frac (hsv.xxx + HUE) * 6.0 - 3.0.xxx) - 1.0.xxx);
   rgb = hsv.z * lerp (1.0.xxx, rgb, hsv.y);
   rgb = saturate (((rgb - 0.5.xxx) * Gain) + 0.5.xxx);

   return float4 (rgb, retval.a);
}

DeclareEntryPoint (SeventiesPsychedelia)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgnd   = tex2D (Video, uv2);
   float4 retval = tex2D (Contours, uv2);
   float4 source = Fgnd;

   // The smudger is implemented as a variation on a radial blur first.  The range
   // of adjustment is limited to run between zero and an arbitrary value of 0.002.

   float2 xy1, xy2 = float2 (1.0, _OutputAspectRatio) * max (Smudge, 0.0) * 0.002;

   float angle = 0.0;

   for (int i = 0; i < 15; i++) {
      sincos (angle, xy1.x, xy1.y);    // Put sin into x component, cos into y.
      xy1 *= xy2;                      // Scale xy1 by aspect ratio and smudge amount.

      retval += tex2D (Contours, uv2 + xy1);   // Sample at 0 radians first, then
      retval += tex2D (Contours, uv2 - xy1);   // at Pi radians (180 degrees).

      xy1 *= 1.5;                      // Offset xy1 by 50% for a second sample pass.

      retval += tex2D (Contours, uv2 + xy1);
      retval += tex2D (Contours, uv2 - xy1);

      angle += 12.0;                   // Add 12 radians to the angle and go again.
   }

   // Divide the smudger result by four times the number of loop passes plus one.  This
   // value is because of the number of samples inside the loop plus the initial one.

   retval /= 61.0;

   // We then composite the result with the input image and quit.

   retval = lerp (Fgnd, retval, Fgnd.a * Amount);
   retval.a = Fgnd.a;

   return lerp (source, retval, tex2D (Mask, uv2));
}

