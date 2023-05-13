// @Maintainer jwrl
// @Released 2023-05-13
// @Author jwrl
// @Created 2018-03-17

/**
 This effect does a twist of a text overlay over a standard ribbon with adjustable opacity.
 The direction of the twist can be set to wipe on or wipe off.  "Wipe on" gives a left to
 right transition on, and "Wipe off" gives a left to right transition off.  As a result
 when setting the transition range in "Wipe off" it's necessary to set the transition to
 zero, unlike the usual 100%.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdF.fx
//
// Version history:
//
// Updated 2023-05-13 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower third F", "Text", "Animated Lower 3rds", "Twists a text overlay to reveal it over a ribbon background", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Transition, "Transition", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (TransRange, "Transition range", "Set this so the effect just ends when Transition reaches 100%", kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (ArtAlpha, "Text type", "Text settings", 1, "Video/External image|Crawl/Roll/Title/Image key");

DeclareFloatParam (TxtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (TxtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareIntParam (SetTechnique, "Direction", "Twist settings", 0, "Wipe on|Wipe off");

DeclareFloatParam (TwistAmount, "Amount", "Twist settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (TwistSoft, "Softness", "Twist settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (RibbonWidth, "Width", "Ribbon settings", kNoFlags, 0.33333333, 0.0, 1.0);
DeclareFloatParam (RibbonL, "Crop left", "Ribbon settings", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (RibbonR, "Crop right", "Ribbon settings", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (RibbonY, "Vertical position", "Ribbon settings", kNoFlags, 0.15, 0.0, 1.0);

DeclareColourParam (RibbonColour, "Colour", "Ribbon settings", kNoFlags, 0.0, 0.0, 1.0, 1.0);

DeclareFloatParam (RibbonOpacity_TL, "Upper left", "Ribbon opacity", kNoFlags, 0.75, -1.0, 1.0);
DeclareFloatParam (RibbonOpacity_BL, "Lower left", "Ribbon opacity", kNoFlags, 0.5, -1.0, 1.0);
DeclareFloatParam (RibbonOpacity_TR, "Upper right", "Ribbon opacity", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (RibbonOpacity_BR, "Lower right", "Ribbon opacity", kNoFlags, -0.25, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define inRange(XY,MIN,MAX) (all (XY >= MIN) && all (XY <= MAX))

#define TWISTS   4.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define MODULATE 10.0

#define R_WIDTH  0.125
#define R_LIMIT  0.005

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input_1_0)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_0)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Text_0)
{
   float4 retval = tex2D (Input_1_0, uv3 - float2 (TxtPosX, -TxtPosY));

   if (ArtAlpha == 1) {
      retval.a = pow (retval.a, 0.5);
      retval.rgb *= retval.a;
   }

   return retval;
}

DeclareEntryPoint (Lower3rdF_WipeOn)
{
   float ribbon = 1.0 - RibbonY;
   float range  = max (0.0, TwistSoft * SOFTNESS) + OFFSET;
   float maxVis = (Transition * (range + 1.0) * TransRange) - uv3.x;
   float T_Axis = uv3.y - ribbon;

   float amount = saturate (maxVis / range);
   float modltn = max (0.0, MODULATE * (range - maxVis));
   float twists = cos (modltn * TwistAmount * TWISTS);

   float2 xy = float2 (uv3.x, ribbon + (T_Axis / twists));

   float4 Bgd = tex2D (Input_2_0, uv3);
   float4 Txt = lerp (kTransparentBlack, tex2D (Text_0, xy), amount);

   float width = max (RibbonWidth * R_WIDTH, R_LIMIT);

   float2 xy1 = float2 (RibbonL, ribbon - width);
   float2 xy2 = float2 (RibbonR, ribbon + width);

   if (inRange (uv3, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad_H = max (uv3.x - RibbonL, 0.0) / length;
      float grad_V = (uv3.y - xy1.y) / (width * 2.0);

      float alpha   = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad_H);
      float alpha_1 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad_H);

      alpha = max (0.0, lerp (alpha, alpha_1, grad_V));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      return lerp (Bgd, Fgd, Fgd.a * Opacity);
   }
   else return lerp (Bgd, Txt, Txt.a * Opacity);
}


DeclarePass (Input_1_1)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_1)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Text_1)
{
   float4 retval = tex2D (Input_1_1, uv3 - float2 (TxtPosX, -TxtPosY));

   if (ArtAlpha == 1) {
      retval.a = pow (retval.a, 0.5);
      retval.rgb *= retval.a;
   }

   return retval;
}

DeclareEntryPoint (Lower3rdF_WipeOff)
{
   float ribbon = 1.0 - RibbonY;
   float range  = max (0.0, TwistSoft * SOFTNESS) + OFFSET;
   float maxVis = uv3.x + range + ((Transition - 1.0) * (range + 1.0) * TransRange);
   float T_Axis = uv3.y - ribbon;

   float amount = saturate (maxVis / range);
   float modltn = max (0.0, MODULATE * (range - maxVis));
   float twists = cos (modltn * TwistAmount * TWISTS);

   float2 xy = float2 (uv3.x, ribbon + (T_Axis / twists));

   float4 Bgd = tex2D (Input_2_1, uv3);
   float4 Txt = lerp (kTransparentBlack, tex2D (Text_1, xy), amount);

   float width = max (RibbonWidth * R_WIDTH, R_LIMIT);

   float2 xy1 = float2 (RibbonL, ribbon - width);
   float2 xy2 = float2 (RibbonR, ribbon + width);

   if (inRange (uv3, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad_H = max (uv3.x - RibbonL, 0.0) / length;
      float grad_V = (uv3.y - xy1.y) / (width * 2.0);

      float alpha   = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad_H);
      float alpha_1 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad_H);

      alpha = max (0.0, lerp (alpha, alpha_1, grad_V));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      return lerp (Bgd, Fgd, Fgd.a * Opacity);
   }
   else return lerp (Bgd, Txt, Txt.a * Opacity);
}

