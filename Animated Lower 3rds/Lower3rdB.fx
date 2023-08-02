// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2018-03-15

/**
 This effect consists of a line with an attached bar.  The bar can be locked at either end
 of the line or made to move from right to left or left to right as the transition is
 adjusted.  It can also be locked to either end of the line.

 External text can be input to In_1, and can wipe on or off in sync with, or against the
 moving block.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdB.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded text type selection for 2023.2 settings.
//
// Updated 2023-05-13 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower third B", "Text", "Animated Lower 3rds", "Moves a bar along a coloured line to reveal the text", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define inRange(XY,MIN,MAX) (all (XY >= MIN) && all (XY <= MAX))

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Transition, "Transition", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (ArtWipe, "Visibility", "Text settings", 1, "Always visible|Wipe at left edge of block|Wipe at right edge of block");
DeclareIntParam (ArtAlpha, "Text type", "Text settings", 0, "Video, image key or title|Image key/Title pre LW 2023.2");

DeclareBoolParam (SetupText, "Setup text position", "Text settings", true);

DeclareFloatParam (ArtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (ArtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (LineWidth, "Width", "Line setting", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (LineLength, "Length", "Line setting", kNoFlags, 0.8, 0.0, 1.0);

DeclareFloatParam (Line_X, "Position", "Line setting", "SpecifiesPointX", 0.05, -1.0, 1.0);
DeclareFloatParam (Line_Y, "Position", "Line setting", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareColourParam (LineColour, "Colour", "Line setting", kNoFlags, 1.0, 0.0, 0.0, 1.0);

DeclareIntParam (BlockMode, "Movement", "Block setting", 0, "Move from left to right|Move from right to left|Anchor to left end of line|Anchor to right end of line");

DeclareFloatParam (BlockWidth, "Width", "Block setting", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (BlockLength, "Length", "Block setting", kNoFlags, 0.2, 0.0, 1.0);

DeclareColourParam (BlockColour, "Colour", "Block setting", kNoFlags, 1.0, 0.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input_1)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Ribbon)
{
   float lWidth  = 0.005 + (LineWidth * 0.01);
   float bLength = BlockLength * LineLength;
   float bWidth  = BlockWidth * 0.2;
   float bTrans  = BlockMode == 0 ? Transition : BlockMode == 1
                                  ? 1.0 - Transition : BlockMode == 2
                                  ? 0.0 : 1.0;
   float bOffset = (LineLength - bLength) * bTrans;

   float2 xy1 = float2 (Line_X, 1.0 - Line_Y - (lWidth * 0.5));
   float2 xy2 = xy1 + float2 (LineLength, lWidth);
   float2 xy3 = float2 (xy1.x + bOffset, xy2.y);
   float2 xy4 = xy3 + float2 (bLength, bWidth);

   float4 retval = inRange (uv3, xy1, xy2) ? LineColour : kTransparentBlack;

   if (inRange (uv3, xy3, xy4)) retval = BlockColour;

   return retval;
}

DeclareEntryPoint (Lower3rdB)
{
   float aTrans = ArtWipe == 0 ? LineLength : LineLength * (1.0 - BlockLength);

   float2 xy = uv3 - float2 (ArtPosX, -ArtPosY);

   float4 Fgnd = tex2D (Ribbon, uv3);
   float4 Text = tex2D (Input_1, xy);

   if (ArtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   if ((ArtWipe >= 1) && !SetupText) {
      if (BlockMode == 0) {
         aTrans *= Transition;
         aTrans += ArtWipe == 1 ? Line_X : LineLength * BlockLength + Line_X;

         if (uv3.x > aTrans) Text = kTransparentBlack;
      }
      else if (BlockMode == 1) {
         aTrans *= 1.0 - Transition;
         aTrans += ArtWipe == 1 ? Line_X : LineLength * BlockLength + Line_X;

         if (uv3.x < aTrans) Text = kTransparentBlack;
      }
   }

   Text = lerp (Fgnd, Text, Text.a);

   return lerp (tex2D (Input_2, uv3), Text, Text.a * Opacity);
}

