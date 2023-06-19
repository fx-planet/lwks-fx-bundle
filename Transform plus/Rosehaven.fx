// @Maintainer jwrl
// @Released 2023-06-19
// @Author jwrl
// @Created 2020-05-08

/**
 Rosehaven creates mirrored halves of the frame for title sequences and similar uses.
 The mirroring can be vertical or horizontal, and the mirror point/wipe centre can be
 moved to vary the effect.  The image can also be scaled, positioned, flipped and
 rotated to control the area mirrored.  There is a simpler version of this effect
 called Mirrors available, which lacks the ability to flip and rotate the image.

 Any black areas visible outside the active picture area are transparent, and can be
 blended with other effects to add complexity.

 The name of this effect comes from an Australian television series about a small town
 called Rosehaven.  An effect similar to this was used in its opening title sequence.
 Well, I had to call it something!

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rosehaven.fx
//
// This started life as a very simple effect called Mirrors.fx with just three lines of
// active code.  Adding the ability to rotate and flip the image changed that though!
//
// Version history:
//
// Updated 2023-06-19 jwrl.
// Changed subcategory from "DVE Extras" to "Transform plus".
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rosehaven", "DVE", "Transform plus", "Creates mirrored top/bottom or left/right images.", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Mode, "Orientation", "Mirror settings", 1, "Horizontal|Vertical");
DeclareFloatParam (Centre, "Axis position", "Mirror settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Orientation, "Orientation", "Input image", 0, "Normal|Flipped|Flopped|Flip-flopped|Rotated|Flip / rotate|Flop / rotate|Flip-flop / rotate");

DeclareFloatParam (Scale, "Scale", "Input image", "DisplayAsPercentage", 1.0, 0.25, 4.0);
DeclareFloatParam (PosX, "Position", "Input image", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (PosY, "Position", "Input image", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareIntParam (_FgOrientation);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg)
{
   float Rotate = Orientation > 3 ? Orientation - 4 : Orientation;

   float2 xy = Rotate == 0 ? uv1
             : Rotate == 1 ? float2 (uv1.x, 1.0 - uv1.y)
             : Rotate == 2 ? float2 (1.0 - uv1.x, uv1.y) : 1.0.xx - uv1;

   return ReadPixel (Inp, xy);
}

DeclarePass (Mirrored)
{
   float4 retval;

   float2 xy;

   if (Orientation < 4) {
      xy = float2 (uv2.x - PosX, uv2.y + PosY);

      if (Mode) {
         xy = float2 (xy.x - 0.5, xy.y) / max (0.25, Scale);
         xy.x += 0.5;
      }
      else {
         xy = float2 (xy.x, xy.y - 0.5) / max (0.25, Scale);
         xy.y += 0.5;
      }
   }
   else {
      if (Mode) {
         xy = float2 (1.0 - uv2.x + PosX, uv2.y - PosY);
         xy = float2 ((xy.x - 0.5) * _OutputAspectRatio, xy.y / _OutputAspectRatio);
         xy = xy / max (0.25, Scale);
         xy = float2 (xy.y, xy.x + 0.5);
      }
      else {
         xy = float2 (uv2.x + PosX, 1.0 - uv2.y - PosY);
         xy = float2 (xy.x * _OutputAspectRatio, (xy.y - 0.5) / _OutputAspectRatio);
         xy = xy / max (0.25, Scale);
         xy = float2 (xy.y + 0.5, xy.x);
      }
   }

   return ReadPixel (Fg, xy);
}

DeclareEntryPoint (Rosehaven)
{
   float2 xy = Mode ? float2 (0.0, 1.0 - Centre) : float2 (Centre, 0.0);

   return ReadPixel (Mirrored, abs (uv2 - xy));
}

