// @Maintainer jwrl
// @Released 2022-12-28
// @Author jwrl
// @Created 2022-12-28

/**
 This effect opens a text ribbon in a lower third position to reveal the lower third text.
 That's all there is to it really.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdC.fx
//
// Version history:
//
// Built 2022-12-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower third C", "Text", "Animated Lower 3rds", "Opens a text ribbon to reveal the lower third text", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Transition, "Transition", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (ArtAlpha, "Text type", "Text settings", 1, "Video/External image|Crawl/Roll/Title/Image key");

DeclareBoolParam (SetupText, "Setup text position", "Text settings", true);

DeclareFloatParam (ArtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (ArtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (RibbonWidth, "Width", "Ribbon setting", kNoFlags, 0.3, 0.0, 1.0);
DeclareFloatParam (RibbonLength, "Length", "Ribbon setting", kNoFlags, 0.8, 0.0, 1.0);

DeclareColourParam (RibbonColourA, "Left colour", "Ribbon setting", kNoFlags, 0.0, 0.0, 1.0, 1.0);
DeclareColourParam (RibbonColourB, "Right colour", "Ribbon setting", kNoFlags, 0.0, 1.0, 1.0, 1.0);

DeclareFloatParam (Ribbon_X, "Position", "Ribbon setting", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (Ribbon_Y, "Position", "Ribbon setting", "SpecifiesPointY", 0.15, 0.0, 1.0);

DeclareFloatParam (LineWidth, "Width", "Line setting", kNoFlags, 0.1 , 0.0, 1.0);

DeclareColourParam (LineColourA, "Left colour", "Line setting", kNoFlags, 0.07, 0.07, 0.49, 1.0);
DeclareColourParam (LineColourB, "Right colour", "Line setting", kNoFlags, 0.0, 0.27, 0.47, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input_1)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2)
{ return ReadPixel (In_2, uv2); }

DeclareEntryPoint (Lower3rdC)
{
   float lWidth  = LineWidth * 0.0625;
   float rWidth = max (0.0, lerp (-lWidth, (RibbonWidth + 0.02) * 0.25, Transition));

   lWidth = max (0.0, lWidth + min (0.0, rWidth));

   float2 xy1 = uv3 - float2 (ArtPosX, -ArtPosY);
   float2 xy2 = float2 (Ribbon_X, 1.0 - Ribbon_Y - (rWidth * 0.5));
   float2 xy3 = xy2 + float2 (RibbonLength, rWidth);

   float colour_grad = max (uv3.x - Ribbon_X, 0.0) / RibbonLength;

   float4 lColour = lerp (LineColourA, LineColourB, colour_grad);
   float4 retval  = lerp (RibbonColourA, RibbonColourB, colour_grad);
   float4 artwork = tex2D (Input_1, xy1);

   if (ArtAlpha == 1) {
      artwork.a = pow (artwork.a, 0.5);
      artwork.rgb *= artwork.a;
   }

   retval = (uv3.y < xy2.y) || (uv3.y > xy3.y) ? kTransparentBlack : lerp (retval, artwork, artwork.a);

   xy1 = float2 (xy2.y - lWidth, xy3.y + lWidth);

   if (((uv3.y >= xy1.x) && (uv3.y <= xy2.y)) || ((uv3.y >= xy3.y) && (uv3.y <= xy1.y)))
      retval = lColour;

   if ((uv3.x < xy2.x) || (uv3.x > xy3.x)) retval = kTransparentBlack;

   if (SetupText) retval = lerp (retval, artwork, artwork.a);

   return lerp (tex2D (Input_2, uv3), retval, retval.a * Opacity);
}

