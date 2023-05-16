// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2020-11-29

/**
 This 2D DVE performs in the same way as the Lightworks version does, but with some
 significant differences.  First, there is no drop shadow support.  Second, instead
 of the drop shadow you get a border.  This can be set to either eat into the Fg,
 or surround the Fg image.  This allows for those cases where the border is invisible
 because the image isn't cropped.  This has been provided at the expense of the
 masking provided in current versions of the 2D DVE.

 Also added in this version is the ability to rotate the image.  And fourth, the
 image can be duplicated as you zoom out either directly or as a mirrored image.
 Mirroring can be horizontal or vertical only, or on both axes.  Fifth, all size
 adjustment follows a square law.  The range you will see in your sequence is the
 same as you see in the Lightworks effect, but the adjustment settings are from
 zero to the square root of ten - a little over three.  This has been done to make
 size reduction more easily controllable.

 The final image that the effect produces has a composite alpha channel built from
 a combination of the background and foreground.  If the background has transparency
 it will be preserved wherever the foreground isn't present.

 There is one final difference when compared with the Lightworks 2D DVE: the background
 can be faded to opaque black.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 2dDVErepeats.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("2D DVE with repeats", "DVE", "DVE Extras", "A 2D DVE that can duplicate the foreground image as you zoom out", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Repeats, "Repeat mode", kNoGroup, 0, "No repeats|Repeat duplicated|Repeat mirrored|Horizontal mirror|Vertical mirror");

DeclareFloatParam (PosX, "Position", kNoGroup, "SpecifiesPointX", 0.5, -1.0, 2.0);
DeclareFloatParam (PosY, "Position", kNoGroup, "SpecifiesPointY", 0.5, -1.0, 2.0);
DeclareFloatParam (Angle, "Angle", kNoGroup, kNoFlags, 0.0, -180.0, 180.0);

DeclareFloatParam (MasterScale, "Master", "Scale", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (XScale, "X", "Scale", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (YScale, "Y", "Scale", kNoFlags, 1.0, 0.0, 3.16227766);

DeclareFloatParam (CropLeft, "Left", "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropTop, "Top", "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropRight, "Right", "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropBottom, "Bottom", "Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Border, "Width", "Border", kNoFlags, 0.0, 0.0, 1.0);
DeclareColourParam (Colour, "Border colour", "Border", kNoFlags, 0.49, 0.561, 1.0, 1.0);
DeclareIntParam (OuterBorder, "Border outside foreground", "Border", 1, "No|Yes");

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Background, "Background", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (Blanking, "Crop foreground to background", kNoGroup, 0, "No|Yes");

DeclareIntParam (_FgOrientation);

DeclareFloatParam (_FgWidth);
DeclareFloatParam (_FgHeight);

DeclareFloat4Param (_FgExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float getCrop (out float L, out float T, out float R, out float B)
{
   float4 crop = float4 (CropLeft, CropTop, CropRight, CropBottom);

   float AR;

   if (abs (abs (_FgOrientation - 90) - 90)) {
      crop = crop.wxyz;
      AR = _FgHeight / _FgWidth;
   }
   else AR = _FgWidth / _FgHeight;

   if (_FgOrientation > 90) { crop = crop.zwxy; }

   L = crop.x;
   T = crop.y;
   R = 1.0 - crop.z;
   B = 1.0 - crop.w;

   return AR;
}

float2 fixPosition ()
{
   float2 pos = _FgOrientation == 90  ? 0.5.xx - float2 (PosY, PosX)
              : _FgOrientation == 180 ? float2 (PosX - 0.5, 0.5 - PosY)
              : _FgOrientation == 270 ? float2 (PosY, PosX) - 0.5.xx
                                      : float2 (0.5 - PosX, PosY - 0.5);

   return pos * abs (_FgExtents.xy - _FgExtents.zw);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Crop)
{
   // We first get the crop settings from getCrop(), which also returns the Fg aspect
   // ratio.  That's used to scale the horizontal border thickness for use as vertical.
   // The border is then either subtracted from the top and left crop values and added
   // to the right and bottom values to give a border outside the crop, or the reverse
   // is done to place the border inside the crop.

   float BdrL, BdrT, BdrR, BdrB;
   float CropL, CropT, CropR, CropB;
   float BdrX = Border * 0.25;
   float BdrY = BdrX * getCrop (CropL, CropT, CropR, CropB);

   if (OuterBorder) {
      BdrL = CropL - BdrX;
      BdrT = CropT - BdrY;
      BdrR = CropR + BdrX;
      BdrB = CropB + BdrY;
   }
   else {
      BdrL = CropL; CropL += BdrX;
      BdrT = CropT; CropT += BdrY;
      BdrR = CropR; CropR -= BdrX;
      BdrB = CropB; CropB -= BdrY;
   }

   // Now we set up our sample geometry.  Using uv3 allows us to rotate and scale the
   // Fg image to the sequence output coordinates.  This is necessary for the next pass.

   float4 retval;

   if ((uv3.x >= CropL) && (uv3.x <= CropR) && (uv3.y >= CropT) && (uv3.y <= CropB)) {
      retval = tex2D (Fg, uv3);
   }
   else if ((uv3.x >= BdrL) && (uv3.x <= BdrR) && (uv3.y >= BdrT) && (uv3.y <= BdrB)) {
      retval = float4 (Colour.rgb, 1.0);
   }
   else retval = kTransparentBlack;

   return retval;
}

DeclareEntryPoint (DVErepeats)
{
   // In the main shader we square the scale parameters to make size reduction
   // simpler.  This has the added benefit of making the area change linearly.
   // We also obtain the foreground aspect ratio for later use.

   float scaleX = MasterScale * MasterScale;
   float scaleY = max (1.0e-6, scaleX * YScale * YScale);
   float AspectRatio = abs (abs (_FgOrientation - 90) - 90)
                     ? _FgHeight / _FgWidth : _FgWidth / _FgHeight;

   scaleX = max (1.0e-6, scaleX * XScale * XScale);

   // Now adjust the Fg image position and store the result in xy1.  This 
   // corrects for any image rotation and size difference, and we can use
   // uv1 for addressing because the use of uv3 in the previous pass means
   // that the cropped image geometry matches the raw Fg image.  It is
   // then scaled and stored in xy2 so that we can rotate it.

   float2 xy1 = uv1 + fixPosition ();
   float2 xy2 = (xy1 - 0.5.xx) / float2 (scaleX, scaleY);

   // Square the geometry of xy2.y using the aspect ratio then rotate xy2
   // with the trig values obtained from sincos().  Put the result back in
   // xy1 and restore it to normalised (0 > 1) coordinates.

   xy2.y /= AspectRatio;

   float s, c;

   sincos (radians (Angle), s, c);

   xy1.x = (xy2.x * c) + (xy2.y * s);
   xy1.y = ((xy2.y * c) - (xy2.x * s)) * AspectRatio;

   xy1 += 0.5.xx;

   // If Repeats isn't zero (no repeats) we perform the required image duplication.

   if (Repeats) {
      xy2 = frac (xy1);       // xy2 is now wrapped to duplicate the image.

      if (Repeats != 1) {     // If Repeats = 1 mirroring isn't required.

         // If Repeats = 3 only horizontal mirroring is required, so skip this.

         if (Repeats != 3) xy2.x = 1.0 - abs (2.0 * (frac (xy1.x / 2.0) - 0.5));

         // If Repeats = 4 only vertical mirroring is required, otherwise do this.

         if (Repeats != 4) xy2.y = 1.0 - abs (2.0 * (frac (xy1.y / 2.0) - 0.5));
      }

      xy1 = xy2;
   }

   // The value in xy1 is now used to index into the foreground, which is cropped
   // to transparent black outside background bounds if required.  The background
   // is also recovered and faded if necessary.

   float4 Fgnd = Blanking && IsOutOfBounds (uv2) ? kTransparentBlack : ReadPixel (Crop, xy1);
   float4 Bgnd = lerp (kTransparentBlack, ReadPixel (Bg, uv2), Background);

   // The duplicated foreground is finally blended with the background.

   return lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
}

