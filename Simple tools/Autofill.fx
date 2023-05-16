// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2021-09-01

/**
 This effect provides an automatic fill to clips which don't have the same aspect ratio
 as the sequence in which they're used.  The fill can be the blurred foreground, a flat
 colour, a blurred background, or mixtures of all three.  If no background is connected
 adjusting the background setting will fade the colour used by Bgd mix to black.

 What do the various controls do?

   Fill amount      - allows the fill outside the clip bounds to be faded in and out.
   Fill blur        - varies the fill blurriness.  0% passes the fill through unchanged.
   Fill/Fgd mix     - mixes the foreground with the fill colour and the fill background
                      mix prior to the blur being applied.
   Edge duplication - fill area can be a duplicate or a mirror of the foreground.
   Offset direction - allows either horizontal or vertical areas to be filled.
   Fill offset      - duplicated foreground video fill displacement.
   Fill scale       - horizontal and/or vertical fill scaling of foreground video.
   Fill colour      - self explanatory.
   Background       - mixes between the fill colour and the Bg (background) input if
                      it's connected, or fades the fill colour to black if it's not.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Autofill.fx
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Auto fill", "Stylize", "Simple tools", "Provides a fill for clips which don't have the same aspect ratio as the sequence", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Fill amount", kNoGroup, kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (FillBlur, "Fill blur", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (FillMix, "Fill/Fgd mix", "Fgd fill mode", kNoFlags, 0.75, 0.0, 1.0);

DeclareIntParam (FgdFillMode, "Edge duplication type", "Fgd fill mode", 0, "Mirror|Copy");
DeclareIntParam (FgdOffsDirection, "Offset direction", "Fgd fill mode", 0, "Horizontal|Vertical");

DeclareFloatParam (FgdDisplace, "Fill offset", "Fgd fill mode", kNoFlags, 0.32, 0.0, 1.0);

DeclareFloatParam (FgdScaleX, "Fill scale", "Fgd fill mode", "SpecifiesPointX|DisplayAsPercentage", 1.0, 0.25, 4.0);
DeclareFloatParam (FgdScaleY, "Fill scale", "Fgd fill mode", "SpecifiesPointY|DisplayAsPercentage", 1.0, 0.25, 4.0);

DeclareColourParam (FillColour, "Fill colour", "Mix between fill colour and background", kNoFlags, 0.24, 0.49, 1.0, 1.0);

DeclareFloatParam (BgndMix, "Background", "Mix between fill colour and background", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_blur (sampler s, float2 uv, int run)
{
   // First we check to see if we need to do the blur at all.  If not we get out.

   if (FillBlur <= 0.0) return tex2D (s, uv);

   float4 retval = kTransparentBlack;  // Set to all zeros at the start of the blur.

   // xy1 will be used to address the rotation vectors, xy2 to address the scaled
   // blur amount

   float2 xy1, xy2 = float2 (1.0, _OutputAspectRatio) * FillBlur * 0.05;

   // Ar is used to calculate the angle of rotation.  Increments by 7.5 degrees (in
   // radians) on each run to oversample the blur at a different angle each time.

   float Ar = run * 0.1309;

   // The following for-next loop samples at 30 degree offsets 12 times for a total
   // of 360 degrees.

   for (int i = 0; i < 12; i++) {
      sincos (Ar, xy1.y, xy1.x); // Calculate the rotation vectors from the angle
      xy1 *= xy2;                // Apply the scaled blur to them
      xy1 += uv;                 // Add the address of the pixel that we need
      retval += tex2D (s, xy1);  // Add the offset pixel to retval to give the blur
      Ar += 0.5236;              // Add 30 degrees in radians to the angle of rotation
   }

   // Divide the blurred result by 12 to bring the video back to legal levels and quit.

   return retval / 12.0;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (FgdScl)
{
   float2 scale = float2 (FgdScaleX, FgdScaleY);

   if (FgdOffsDirection) { if (FgdFillMode == 0) scale.y = -scale.y; }
   else { if (FgdFillMode == 0) scale.x = -scale.x; }

   float2 xy = ((uv3 - 0.5.xx) / scale) + 0.5.xx;

   return ReadPixel (Fgd, xy);
}

DeclarePass (Fill_0)
{
   float2 pos = FgdOffsDirection ? float2 (0.0, FgdDisplace)
                                 : float2 (FgdDisplace, 0.0);
   float2 xy1 = uv3 - pos;
   float2 xy2 = uv3 + pos;

   float4 Fgnd = ReadPixel (FgdScl, xy1);
   float4 Bgnd = lerp (FillColour, ReadPixel (Bg, uv2), BgndMix);

   Fgnd = lerp (ReadPixel (FgdScl, xy2), Fgnd, Fgnd.a);

   return lerp (kTransparentBlack, lerp (Bgnd, Fgnd, FillMix), Amount);
}

DeclarePass (Fill_1)
{ return fn_blur (Fill_0, uv3, 0); }

DeclarePass (Fill_2)
{ return fn_blur (Fill_1, uv3, 1); }

DeclarePass (Fill_3)
{ return fn_blur (Fill_2, uv3, 2); }

DeclareEntryPoint (Autofill)
{
   // We're on the last run so if we're inside legal foreground boundaries we
   // return the unmodified foreground video.

   float4 Fgnd = ReadPixel (Fg, uv1);

   return lerp (fn_blur (Fill_3, uv3, 3), Fgnd, Fgnd.a);
}

