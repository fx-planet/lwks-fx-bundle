// @Maintainer jwrl
// @Released 2023-05-13
// @Author jwrl
// @Created 2018-03-15

/**
 This effect does a page turn type of text overlay over a standard ribbon with adjustable
 opacity.  The direction of the page turn can be set to wipe on or wipe off.  "Wipe on"
 gives a left > right transition, and "Wipe off" reverses it. 

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdE.fx
//
// Version history:
//
// Updated 2023-05-13 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower third E", "Text", "Animated Lower 3rds", "Page turns a text overlay over a ribbon background", "ScaleAware|HasMinOutputSize");

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

DeclareIntParam (ArtAlpha, "Text type", "Text settings", 0, "Video/External image|Crawl/Roll/Title/Image key");

DeclareFloatParam (TxtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (TxtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (TxtDistort, "Distortion", "Text settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (TxtRipple, "Ripple amount", "Text settings", kNoFlags, 0.4, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Effect direction", "Text settings", 0, "Wipe on|Wipe off");

DeclareFloatParam (RibbonWidth, "Width", "Ribbon settings", kNoFlags, 0.33333333, 0.0, 1.0);
DeclareFloatParam (RibbonL, "Crop left", "Ribbon settings", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (RibbonR, "Crop right", "Ribbon settings", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (RibbonY, "Vertical position", "Ribbon settings", kNoFlags, 0.15, 0.0, 1.0);

DeclareColourParam (RibbonColour, "Colour", "Ribbon settings", kNoFlags, 0.0, 0.0, 1.0, 0.0);

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

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input_1)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Text_0)
{
   float4 retval = tex2D (Input_1, uv3 - float2 (TxtPosX, -TxtPosY));

   if (ArtAlpha == 1) {
      retval.a = pow (retval.a, 0.5);
      retval.rgb *= retval.a;
   }

   return retval;
}

DeclareEntryPoint (Lower3rdE_WipeOn)
{
   float range  = max (0.0, TxtDistort * SOFTNESS) + OFFSET;
   float T_Axis = uv3.y - RibbonY;
   float maxVis = range + uv3.x - (TransRange * Transition * (1.0 + range));

   float amount = saturate (maxVis / range);
   float ripple = max (0.0, RIPPLES * maxVis);
   float width  = (0.01 + (RibbonWidth * 0.25));

   float modulate = pow (max (0.0, TxtRipple), 5.0) * ripple;

   float offset = sin (modulate) * ripple * width;
   float twists = cos (modulate * 4.0);

   float2 xy = float2 (uv3.x, RibbonY + (T_Axis / twists) - offset);

   float4 Txt = lerp (tex2D (Text_0, xy), kTransparentBlack, amount);
   float4 Bgd = tex2D (Input_2, uv3);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (inRange (uv3, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad   = max (uv3.x - RibbonL, 0.0) / length;

      float alpha_1 = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad);
      float alpha_2 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad);

      grad = (uv3.y - xy1.y) / width;

      float alpha = max (0.0, lerp (alpha_1, alpha_2, grad));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      Txt = Fgd;
   }

   return lerp (Bgd, Txt, Txt.a * Opacity);
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

DeclareEntryPoint (Lower3rdE_WipeOff)
{
   float range  = max (0.0, TxtDistort * SOFTNESS) + OFFSET;
   float minVis = TransRange * (1.0 - Transition) * (1.0 + range) - uv3.x;
   float T_Axis = uv3.y - RibbonY;
   float maxVis = range - minVis;

   float amount = saturate (maxVis / range);
   float ripple = max (0.0, RIPPLES * minVis);
   float width  = (0.01 + (RibbonWidth * 0.25));

   float modulate = pow (max (0.0, TxtRipple), 5.0) * ripple;

   float offset = sin (modulate) * ripple * width;
   float twists = cos (modulate * 4.0);

   float2 xy = float2 (uv3.x, RibbonY + (T_Axis / twists) - offset);

   float4 Txt = lerp (kTransparentBlack, tex2D (Text_1, xy), amount);
   float4 Bgd = tex2D (Input_2_1, uv3);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (inRange (uv3, xy1, xy2)) {
      float length = max (0.0, RibbonR - RibbonL);
      float grad   = max (uv3.x - RibbonL, 0.0) / length;

      float alpha_1 = lerp (RibbonOpacity_TL, RibbonOpacity_TR, grad);
      float alpha_2 = lerp (RibbonOpacity_BL, RibbonOpacity_BR, grad);

      grad = (uv3.y - xy1.y) / width;

      float alpha = max (0.0, lerp (alpha_1, alpha_2, grad));

      float4 Fgd = lerp (float4 (RibbonColour.rgb, alpha), Txt, Txt.a);

      Txt = Fgd;
   }

   return lerp (Bgd, Txt, Txt.a * Opacity);
}

