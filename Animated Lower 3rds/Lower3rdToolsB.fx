// @Maintainer jwrl
// @Released 2023-05-13
// @Author jwrl
// @Created 2018-03-15

/**
 This is a three input effect which is a general purpose toolkit designed to build lower
 thirds.  It uses In1 for an optional logo or other graphical component, In2 for optional
 text and Bgd as a background-only layer.  It's designed to create an edged, coloured
 ribbon gradient with an overlaid floating bordered flat colour box.  Any component can
 be completely hidden if required and all are fully adjustable.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdToolsB.fx
//
// Version history:
//
// Updated 2023-05-13 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower 3rd toolkit B", "Text", "Animated Lower 3rds", "A general purpose toolkit designed to help build custom lower thirds", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2, Bgd);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Text source", "Text settings", 0, "Before / Using In_1 for logo and In_2 for text|Before / Using In_1 for text and In_2 for background|After / Using In_1 for logo and In_2 for background|After this effect - use In_1 as only source");

DeclareIntParam (TxtAlpha, "Text type", "Text settings", 0, "Video/External image|Crawl/Roll/Title/Image key");

DeclareFloatParam (TxtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (TxtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);
DeclareFloatParam (LogoSize, "Scale", "Logo settings", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (LogoPosX, "Position", "Logo settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (LogoPosY, "Position", "Logo settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (RibbonWidth, "Width", "Ribbon", kNoFlags, 0.33333333, 0.0, 1.0);
DeclareFloatParam (RibbonL, "Crop left", "Ribbon", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (RibbonR, "Crop right", "Ribbon", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (RibbonY, "Vertical position", "Ribbon", kNoFlags, 0.15, 0.0, 1.0);

DeclareColourParam (RibbonColourA, "Left colour", "Ribbon", kNoFlags, 0.0, 0.0, 1.0, 1.0);
DeclareColourParam (RibbonColourB, "Right colour", "Ribbon", kNoFlags, 0.0, 1.0, 1.0, 0.0);

DeclareFloatParam (TbarWidth, "Width", "Upper line", kNoFlags, 0.33333333, 0.0, 1.0);
DeclareFloatParam (TbarL, "Crop left", "Upper line", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (TbarR, "Crop right", "Upper line", kNoFlags, 1.0, 0.0, 1.0);

DeclareColourParam (TbarColour, "Colour", "Upper line", kNoFlags, 0.11, 0.11, 0.52, 1.0);

DeclareFloatParam (BbarWidth, "Width", "Lower line", kNoFlags, 0.33333333, 0.0, 1.0);
DeclareFloatParam (BbarL, "Crop left", "Lower line", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (BbarR, "Crop right", "Lower line", kNoFlags, 1.0, 0.0, 1.0);

DeclareColourParam (BbarColour, "Colour", "Lower line", kNoFlags, 0.07, 0.33, 0.33, 1.0);

DeclareBoolParam (BarGrad, "Use line colours as gradients for both lines", "Lower line", false);

DeclareFloatParam (BoxWidth, "Width", "Inset box", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (BoxHeight, "Height", "Inset box", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (BoxLine, "Border width", "Inset box", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Box_X, "Position", "Inset box", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (Box_Y, "Position", "Inset box", "SpecifiesPointY", 0.2, 0.0, 1.0);

DeclareColourParam (BoxColourA, "Line colour", "Inset box", kNoFlags, 1.0, 0.0, 0.0, 1.0);
DeclareColourParam (BoxColourB, "Fill colour", "Inset box", kNoFlags, 1.0, 1.0, 0.0, 1.0);

DeclareFloatParam (MasterScale, "Scale", "Master size and position", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Master_X, "Position", "Master size and position", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (Master_Y, "Position", "Master size and position", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define inRange(XY,MIN,MAX) (all (XY >= MIN) && all (XY <= MAX))

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_ribbon (float2 uv)
{
   float4 retval = kTransparentBlack;

   float colour_grad, length;
   float width  = 0.01 + (RibbonWidth * 0.25);

   float2 xy1 = float2 (RibbonL, 1.0 - RibbonY - (width * 0.5));
   float2 xy2 = float2 (RibbonR, xy1.y + width);

   if (inRange (uv, xy1, xy2)) {
      length = max (0.0, RibbonR - RibbonL);
      colour_grad = max (uv.x - RibbonL, 0.0) / length;
      retval = lerp (RibbonColourA, RibbonColourB, colour_grad);
   }

   float y = xy1.y - (TbarWidth * 0.02);

   if (inRange (uv, float2 (TbarL, y), float2 (TbarR, xy1.y))) {
      if (BarGrad) {
         length = max (0.0, TbarR - TbarL);
         colour_grad = max (uv.x - TbarL, 0.0) / length;
         retval = lerp (TbarColour, BbarColour, colour_grad);
      }
      else retval = TbarColour;
   }

   y = xy2.y + (BbarWidth * 0.02);

   if (inRange (uv, float2 (BbarL, xy2.y), float2 (BbarR, y))) {
      if (BarGrad) {
         length = max (0.0, BbarR - BbarL);
         colour_grad = max (uv.x - BbarL, 0.0) / length;
         retval = lerp (TbarColour, BbarColour, colour_grad);
      }
      else retval = BbarColour;
   }

   float2 xy3 = float2 (BoxWidth, BoxHeight * _OutputAspectRatio) * 0.1;

   xy2  = float2 (Box_X, 1.0 - Box_Y);
   xy1  = xy2 - xy3;
   xy2 += xy3;

   if (inRange (uv, xy1, xy2)) retval = BoxColourA;

   xy3  = float2 (1.0, _OutputAspectRatio) * BoxLine * 0.012;
   xy1 += xy3;
   xy2 -= xy3;

   if (inRange (uv, xy1, xy2)) retval = BoxColourB;

   return retval;
}

float4 fn_main (sampler C, sampler I, float2 uv)
{
   float2 xy = (uv - 0.5.xx) / max (0.000001, MasterScale * 2.0);

   xy += float2 (0.5 - Master_X, 0.5 + Master_Y);

   float4 Fgnd = tex2D (C, xy);

   return lerp (tex2D (I, uv), Fgnd, Fgnd.a * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Before / Using In_1 for logo and In_2 for text

DeclarePass (Inp_1_0)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Inp_2_0)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Inp_3_0)
{ return ReadPixel (Bgd, uv3); }

DeclarePass (Ribbon_0)
{ return fn_ribbon (uv0); }

DeclarePass (Comp_0)
{
   float2 xy = ((uv4 - 0.5.xx) / max (0.00001, LogoSize)) - float2 (LogoPosX, -LogoPosY) + 0.5.xx;

   float4 Logo = tex2D (Inp_1_0, xy);
   float4 Text = tex2D (Inp_2_0, uv4 - float2 (TxtPosX, -TxtPosY));

   if (TxtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   float4 Fgnd = lerp (tex2D (Ribbon_0, uv4), Text, Text.a);

   return lerp (Fgnd, Logo, Logo.a);
}

DeclareEntryPoint (Lower3rdToolsB_0)
{
   float2 xy = (uv4 - 0.5.xx) / max (0.000001, MasterScale * 2.0);

   float4 Fgnd = tex2D (Comp_0, xy + float2 (0.5 - Master_X, 0.5 + Master_Y));

   return lerp (tex2D (Inp_3_0, uv4), Fgnd, Fgnd.a * Opacity);
}


// Before / Using In_1 for text and In_2 for background

DeclarePass (Inp_1_1)
{ return tex2D (In_1, uv1); }

DeclarePass (Inp_2_1)
{ return tex2D (In_2, uv2); }

DeclarePass (Ribbon_1)
{ return fn_ribbon (uv0); }

DeclarePass (Comp_1)
{
   float4 Text = tex2D (Inp_1_1, uv4 - float2 (TxtPosX, -TxtPosY));

   if (TxtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   return lerp (tex2D (Ribbon_1, uv4), Text, Text.a);
}

DeclareEntryPoint (Lower3rdToolsB_1)
{ return fn_main (Comp_1, Inp_2_1, uv4); }


// After / Using In_1 for logo and In_2 for background

DeclarePass (Inp_1_2)
{ return tex2D (In_1, uv1); }

DeclarePass (Inp_2_2)
{ return tex2D (In_2, uv2); }

DeclarePass (Ribbon_2)
{ return fn_ribbon (uv0); }

DeclarePass (Comp_2)
{
   float2 xy = ((uv4 - 0.5.xx) / max (0.001, LogoSize)) - float2 (LogoPosX, -LogoPosY) + 0.5.xx;

   float4 Logo = tex2D (Inp_1_2, xy);

   return lerp (tex2D (Ribbon_2, uv4), Logo, Logo.a);
}

DeclareEntryPoint (Lower3rdToolsB_2)
{ return fn_main (Comp_2, Inp_2_2, uv4); }


// After this effect - use In_1 as only source

DeclarePass (Inp_1_3)
{ return tex2D (In_1, uv1); }

DeclarePass (Ribbon_3)
{ return fn_ribbon (uv0); }

DeclareEntryPoint (Lower3rdToolsB_3)
{
   float2 xy = (uv4 - 0.5.xx) / max (0.000001, MasterScale * 2.0);

   float4 Fgnd = tex2D (Ribbon_3, xy + float2 (0.5 - Master_X, 0.5 + Master_Y));

   return lerp (tex2D (Inp_1_3, uv4), Fgnd, Fgnd.a * Opacity);
}

