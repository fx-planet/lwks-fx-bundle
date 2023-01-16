// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect dissolves through a user-selected colour field from one clip to another.
 The colour percentage can be adjusted from 0% when the effect perform as a standard
 dissolve, to 100% which fades to the colour field then to the second video stream.
 Values between 100% and 0% will make the colour more or less opaque, giving quite
 subtle colour blends through the transition.  Transition centering can also be adjusted.

 The colour field can be set up to be a single flat colour or a wide range of gradients.
 In the gradients that blend to the centre, the centre point is also fully adjustable.
 Asymmetrical colour transitions can be created by changing keyframing of the effect
 centre, opacity, transition curve, gradient centre and colour values.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Colour_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dissolve thru colour", "Mix", "Colour transitions", "Dissolves through a user-selected colour field from one clip to another", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (FxCentre, "Transition centre", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (cAmount, "Opacity", "Colour setup", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (cCurve, "Trans. curve", "Colour setup", kNoFlags, 0.0, 0.0, 1.0);

DeclareIntParam (cGradient, "Gradient", "Colour setup", 5, "Flat (uses only the top left colour)|Horizontal blend (top left > top right)|Horizontal blend to centre (TL > TR > TL)|Vertical blend (top left > bottom left)|Vertical blend to centre (TL > BL > TL)|Four way gradient|Four way gradient to centre|Four way gradient to centre (horizontal)|Four way gradient to centre (vertical)|Radial (TL outer > TR centre)");

DeclareFloatParam (OffsX, "Grad. midpoint", "Colour setup", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (OffsY, "Grad. midpoint", "Colour setup", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareColourParam (topLeft, "Top left", "Colour setup", kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareColourParam (topRight, "Top right", "Colour setup", kNoFlags, 0.5, 0.0, 0.8, 1.0);
DeclareColourParam (botLeft, "Bottom left", "Colour setup", kNoFlags, 0.0, 0.0, 1.0, 1.0);
DeclareColourParam (botRight, "Bottom right", "Colour setup", kNoFlags, 0.0, 0.8, 0.5, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Gradient)
{
   if (cGradient == 0) return topLeft;

   float4 retval;

   float buff_1, buff_2, horiz, vert = 1.0 - OffsY;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   if ((cGradient == 2) || (cGradient == 6) || (cGradient == 8) || (cGradient == 9)) horiz = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      horiz = lerp (buff_1, buff_2, buff_0);
   }

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   if ((cGradient == 4) || (cGradient == 6) || (cGradient == 7) || (cGradient == 9)) vert = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      vert = lerp (buff_1, buff_2, buff_0);
   }

   if ((cGradient == 3) || (cGradient == 4)) { retval = lerp (topLeft, botLeft, vert); }
   else {
      retval = lerp (topLeft, topRight, horiz);
   
      if (cGradient == 9) retval = lerp (topLeft, retval, vert);
      else if (cGradient > 4) {
         float4 botRow = lerp (botLeft, botRight, horiz);
         retval = lerp (retval, botRow, vert);
      }
   }

   return retval;
}

DeclareEntryPoint (Colour_Dx)
{
   float Mix = (FxCentre + 1.0) / 2;

   Mix = (Mix <= 0.0) ? (Amount / 2.0) + 0.5 :
         (Mix >= 1.0) ? Amount / 2.0 :
         (Mix > Amount) ? Amount / (2.0 * Mix) : ((Amount - Mix) / (2.0 * (1.0 - Mix))) + 0.5;

   float4 Fgnd   = ReadPixel (Fg, uv1);
   float4 Bgnd   = ReadPixel (Bg, uv2);
   float4 colour = ReadPixel (Gradient, uv0);
   float4 rawDx  = lerp (Fgnd, Bgnd, Mix);
   float4 colDx;

   float nonLin = sin (Mix * PI);

   Mix *= 2.0;

   if (Mix > 1.0) {
      Mix = lerp ((2.0 - Mix), nonLin, cCurve);
      colDx = lerp (Bgnd, colour, Mix);
   }
   else {
      Mix = lerp (Mix, nonLin, cCurve);
      colDx = lerp (Fgnd, colour, Mix);
   }

   return lerp (rawDx, colDx, cAmount);
}

