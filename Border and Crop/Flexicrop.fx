// @Maintainer jwrl
// @Released 2023-02_17
// @Author jwrl
// @Created 2023-02-14

/**
 This effect is a flexible vignette with the ability to apply a range of masks using
 the Lightworks mask effect.  The edges of the mask can be bordered with a bicolour
 shaded surround as a percentage of the edge softness.  Drop shadowing of the mask
 is included, and is set as an offset percentage.

 There is a limited 2D DVE function included which will allow the masked video to
 be scaled and positioned.  Since this is applied after the mask is generated it is
 advisable to set the mask up first.

 Because using the mask opacity to fade the foreground will give ugly results when
 a border is used, the master opacity is the best way to fade the effect out.  If
 the mask invert function is used the border colours will swap and the drop shadow
 will appear inside the mask.  To stop this happening you should use the master
 invert function.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Flexicrop.fx
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//
// Updated 2023-02-14 jwrl.
// Corrected bug that caused a potential edge of frame repeat when the mask was inverted.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flexible crop", "DVE", "Border and Crop", "A flexible bordered crop with drop shadow based on LW masking", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (Invert, "Invert effect", kNoGroup, false);

DeclareFloatParam (Scale, "Master size", "DVE", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (SizeX, "Size", "DVE", "SpecifiesPointX|DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (SizeY, "Size", "DVE", "SpecifiesPointY|DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Pos_X, "Position", "DVE", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Pos_Y, "Position", "DVE", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareBoolParam (UseBorder, "Show border (mask softness must be on)", "Border", true);

DeclareFloatParam (bStrength, "Strength", "Border", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (bSoft, "Softness", "Border", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (FlatColour, "Use inner colour only", "Border", false);

DeclareColourParam (BorderColour_1, "Inner colour", "Border", kNoFlags, 0.2, 0.8, 0.8, 1.0);
DeclareColourParam (BorderColour_2, "Outer colour", "Border", kNoFlags, 0.2, 0.1, 1.0, 1.0);

DeclareIntParam (UseShadow, "Use drop shadow", "Drop shadow", 1, "No|With border softness|With mask softness");

DeclareFloatParam (sStrength, "Strength", "Drop shadow", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (ShadowX, "Offset", "Drop shadow", "SpecifiesPointX|DisplayAsPercentage", 0.525, 0.4, 0.6);
DeclareFloatParam (ShadowY, "Offset", "Drop shadow", "SpecifiesPointY|DisplayAsPercentage", 0.475, 0.4, 0.6);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0,1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These first 2 passes are done to optionally invert the inputs to the effect and map
// their coordinates to the master sequence coordinates.

DeclarePass (Fgd)
{ return Invert ? ReadPixel (Bg, uv2) : ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return Invert ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Msk)
{
   float4 Fgnd = tex2D (Fgd, uv3);    // The only input required is the nominal foreground

   // We now generate the XY coordinates for the drop shadow

   float2 xy1 = uv3 - float2 (ShadowX - 0.5, (0.5 - ShadowY) * _OutputAspectRatio);

   // The mask softness data for both the the foreground and the drop shadow is now recovered.

   float FgndMask = tex2D (Mask, uv3).x;
   float ShadMask = tex2D (Mask, xy1).x;

   // Check if we're colouring the border or not and skip if no

   if (UseBorder) {

      // First the raw mask data is scaled to run from 0 to 1.5.  This allows us to generate
      // the three transitions that we require for the border colours.  The first, innerBorder,
      // has a maximum transition range of from 0 to 1 over two thirds of the mask softness,
      // starting at the inner edge.  The next, colourMixer, at maximum occupies the middle
      // third of the mask, and outerBorder at maximum softness takes up the final two thirds.

      float softness    = max (bSoft, 0.01);
      float outerBorder = 1.5 * FgndMask;
      float innerBorder = (1.5 - outerBorder) / softness;
      float drop_shadow = min (1.0, max ((1.5 * ShadMask) / softness, 0.0));

      // Now build the border colour, depending on whether it's flat or bicolour.

      float4 BorderColour;

      if (FlatColour) { BorderColour = BorderColour_1; }
      else {
         float colourMixer = (((outerBorder * 2.0) - 1.5) / softness) + 0.5;

         colourMixer = min (max (colourMixer, 0.0), 1.0);
         colourMixer = lerp (1.0, colourMixer, bStrength);

         // The transition between the inner and outer colours is now built

         BorderColour = lerp (BorderColour_2, BorderColour_1, colourMixer);
      }

      innerBorder = 1.0 - min (max (innerBorder, 0.0), 1.0);
      outerBorder = min (max (outerBorder / softness, 0.0), 1.0);

      // The foreground is now blended with the border colours

      innerBorder = lerp (1.0, innerBorder, bStrength);

      Fgnd  = lerp (BorderColour, Fgnd, innerBorder);

      // The two raw masks are adjusted to allow for the percentage border width.

      FgndMask = lerp (FgndMask, outerBorder, bStrength);
      if (UseShadow == 1) { ShadMask = lerp (ShadMask, drop_shadow, bStrength); }
   }

   // If we're using the drop shadow build it in retval, otherwise use transparent black

   float4 retval = UseShadow ? lerp (kTransparentBlack, BLACK, ShadMask * sStrength)
                             : kTransparentBlack;

   // Return the masked and bordered foreground over the drop shadow.

   return lerp (retval, Fgnd, FgndMask);
}

DeclareEntryPoint (Flexicrop)
{
   // Set up the scaled and positioned coordinates for the masked video

   float2 xy1 = (uv3 - float2 (Pos_X, 1.0 - Pos_Y)) / Scale;

   // We now scale X and Y separately using their own scale factors.

   xy1.x /= SizeX;
   xy1.y /= SizeY;

   // Now we re-centre the coordinates 

   xy1 += 0.5.xx;

   // Recover the scaled and repositioned masked foreground and the background video

   float4 Fgnd = ReadPixel (Msk, xy1);
   float4 Bgnd = tex2D (Bgd, uv3);

   // Mix everything and get out.

   return ((Fgnd - Bgnd) * Fgnd.a * Opacity) + Bgnd;
}

