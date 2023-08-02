// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2018-03-15

/**
 This is a general purpose toolkit designed to build lower thirds.  It can optionally be
 fed with a graphics layer or other external image or effect.  It's designed to produce
 a flat coloured ribbon with two overlaid floating flat colour boxes.  They can be used
 to generate borders, other graphical components, or even be completely hidden.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdToolsA.fx
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

DeclareLightworksEffect ("Lower 3rd toolkit A", "Text", "Animated Lower 3rds", "A general purpose toolkit designed to help build custom lower thirds", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (InpMode, "Text source", "Text settings", 0, "Before - uses In_1 for text / In_2 as background|After - uses In_1 as background with external text");
DeclareIntParam (TxtAlpha, "Text type", "Text settings", 0, "Video, image key or title|Image key/Title pre LW 2023.2");

DeclareFloatParam (TxtPosX, "Position", "Text settings", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (TxtPosY, "Position", "Text settings", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (RibbonWidth, "Width", "Ribbon", kNoFlags, 0.33333333, 0.0, 1.0);
DeclareFloatParam (RibbonL, "Crop left", "Ribbon", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (RibbonR, "Crop right", "Ribbon", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Ribbon_Y, "Vertical position", "Ribbon", kNoFlags, 0.15, 0.0, 1.0);

DeclareColourParam (RibbonColour, "Left colour", "Ribbon", kNoFlags, 0.0, 0.0, 1.0, 1.0);

DeclareFloatParam (BoxA_Width, "Width", "Box A", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (BoxA_L, "Crop left", "Box A", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (BoxA_R, "Crop right", "Box A", kNoFlags, 0.4, 0.0, 1.0);

DeclareFloatParam (BoxA_Y, "Vertical position", "Box A", kNoFlags, 0.212, 0.0, 1.0);

DeclareColourParam (BoxAcolour, "Colour", "Box A", kNoFlags, 1.0, 1.0, 0.0, 1.0);

DeclareFloatParam (BoxB_Width, "Width", "Box B", kNoFlags, 0.15, 0.0, 1.0);
DeclareFloatParam (BoxB_L, "Crop left", "Box B", kNoFlags, 0.35, 0.0, 1.0);
DeclareFloatParam (BoxB_R, "Crop right", "Box B", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (BoxB_Y, "Vertical position", "Box B", kNoFlags, 0.085, 0.0, 1.0);

DeclareColourParam (BoxBcolour, "Colour", "Box B", kNoFlags, 1.0, 0.0, 0.0, 1.0);

DeclareFloatParam (MasterScale, "Scale", "Master size and position", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Master_X, "Position", "Master size and position", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (Master_Y, "Position", "Master size and position", "SpecifiesPointY", 0.0, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define inRange(XY,MIN,MAX) !(any (XY < MIN) || any (XY > MAX))

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Video)
{ return (InpMode == 1) ? ReadPixel (In_1, uv1) : ReadPixel (In_2, uv2); }

DeclarePass (Ribbon)
{
   float y0 = max (RibbonWidth, 0.000001) * 0.142;
   float y1 = 1.0 - Ribbon_Y;

   float2 xy1 = float2 (RibbonL, y1 - y0);
   float2 xy2 = float2 (RibbonR, y1 + y0);

   float4 retval = inRange (uv0, xy1, xy2) ? RibbonColour : kTransparentBlack;

   y0  = max (BoxA_Width, 0.000001) * 0.142;
   y1  = 1.0 - BoxA_Y;
   xy1 = float2 (BoxA_L, y1 - y0);
   xy2 = float2 (BoxA_R, y1 + y0);

   if (inRange (uv0, xy1, xy2)) retval = BoxAcolour;

   y0  = max (BoxB_Width, 0.000001) * 0.142;
   y1  = 1.0 - BoxB_Y;
   xy1 = float2 (BoxB_L, y1 - y0);
   xy2 = float2 (BoxB_R, y1 + y0);

   if (inRange (uv0, xy1, xy2)) retval = BoxBcolour;

   if (!InpMode) {
      float2 pos = uv1 + float2 (0.5 - TxtPosX, TxtPosY - 0.5);

      float4 Fgnd = tex2D (In_1, pos);

      if (TxtAlpha == 1) {
         Fgnd.a = pow (Fgnd.a, 0.5);
         Fgnd.rgb /= Fgnd.a;
      }

      retval = lerp (retval, Fgnd, Fgnd.a);
   }

   return retval;
}

DeclareEntryPoint (Lower3rdToolsA)
{
   float2 xy = (uv3 - float2 (0.5, 0.5)) / max (0.000001, MasterScale * 2.0);

   xy += float2 (0.5 - Master_X, 0.5 + Master_Y);

   float4 Fgnd = ReadPixel (Ribbon, xy);

   return lerp (ReadPixel (Video, uv3), Fgnd, Fgnd.a * Opacity);
}

