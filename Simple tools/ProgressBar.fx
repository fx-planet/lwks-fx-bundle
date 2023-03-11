// @Maintainer jwrl
// @Released 2023-03-11
// @Author jwrl
// @Created 2023-03-11

/**
 This is a quick simple progress bar generator.  The bar can be positioned at will, can
 be bordered and set vertically and horizontally.  It can be set up to have a background
 colour that changes as the bar progresses, or to grow as the bar progresses.  In the
 latter mode it can also produce a colour gradient between start and end points.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ProgressBar.fx
//
// Version history:
//
// Built 2023-03-11 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Progress bar", "Matte", "Simple tools", "A simple progress bar generator", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Progress", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Bar mode", kNoGroup, 0, "Bar grows vertically|Bar grows horizontally|Static vertical bar|Static horizontal bar");

DeclareFloatParam (Width, "Width", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Length, "Length", kNoGroup, kNoFlags, 0.9, 0.0, 1.0);

DeclareFloatParam (PosX, "Position", kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (PosY, "Position", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareBoolParam (ColourGrad, "Colour gradient", "Bar colour", false);

DeclareColourParam (StartColour, "Start", "Bar colour", kNoFlags, 0.8, 0.6, 0.0, 1.0);
DeclareColourParam (EndColour, "End", "Bar colour", kNoFlags, 1.0, 0.2, 0.0, 1.0);

DeclareFloatParam (Border, "Thickness", "Border", kNoFlags, 0.1, 0.0, 1.0);
DeclareColourParam (BorderColour, "Colour", "Border", kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Bar grows vertically

DeclareEntryPoint (VertGrow)
{
   float2 brdrEdge = (Border * 0.05).xx;

   brdrEdge.y *= _OutputAspectRatio;

   float Ypos = 1.0 - PosY;
   float Xpos = PosX;
   float width  = Width / 10.0;
   float c_ramp = saturate ((Ypos - uv1.y) / Length);

   float2 cropTL = float2 (Xpos - width, Ypos - Length);
   float2 cropBR = float2 (Xpos + width, Ypos);

   cropTL.y = lerp (cropBR.y, cropTL.y, Amount);

   float2 bordTL = saturate (cropTL - brdrEdge);
   float2 bordBR = saturate (cropBR + brdrEdge);

   float4 barC = ColourGrad ? lerp (StartColour, EndColour, c_ramp) : StartColour;
   float4 Fgnd = ReadPixel (Inp, uv1);

   if (all (uv1 > cropTL) && all (uv1 < cropBR)) { Fgnd = lerp (Fgnd, barC, barC.a); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR)) { Fgnd = BorderColour; }

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//

// technique Bar grows horizontally

DeclareEntryPoint (HorizGrow)
{
   float2 brdrEdge = (Border * 0.05).xx;

   brdrEdge.y *= _OutputAspectRatio;

   float Ypos = 1.0 - PosY;
   float Xpos = PosX;
   float height = Width / 10.0;
   float c_ramp = saturate ((uv1.x - Xpos) / Length);

   float2 cropTL = float2 (Xpos, Ypos - height);
   float2 cropBR = float2 (Xpos + Length, Ypos + height);

   cropBR.x = lerp (cropTL.x, cropBR.x, Amount);

   float2 bordTL = saturate (cropTL - brdrEdge);
   float2 bordBR = saturate (cropBR + brdrEdge);

   float4 barC = ColourGrad ? lerp (StartColour, EndColour, c_ramp) : StartColour;
   float4 Fgnd = ReadPixel (Inp, uv1);

   if (all (uv1 > cropTL) && all (uv1 < cropBR)) { Fgnd = lerp (Fgnd, barC, barC.a); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR)) { Fgnd = BorderColour; }

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//

// technique Static vertical bar

DeclareEntryPoint (VertStatic)
{
   float2 brdrEdge = (Border * 0.05).xx;

   brdrEdge.y *= _OutputAspectRatio;

   float Ypos = 1.0 - PosY;
   float Xpos = PosX;
   float width  = Width / 10.0;
   float c_ramp = saturate ((Ypos - uv1.y) / Length);

   float2 cropTL = float2 (Xpos - width, Ypos - Length);
   float2 cropBR = float2 (Xpos + width, Ypos);
   float2 bar_TL = float2 (cropTL.x, lerp (cropBR.y, cropTL.y, Amount));

   float2 bordTL = saturate (cropTL - brdrEdge);
   float2 bordBR = saturate (cropBR + brdrEdge);

   float4 Fgnd = ReadPixel (Inp, uv1);
   float4 barC, fillC;

   if (ColourGrad) {
      barC = lerp (StartColour, EndColour, c_ramp);
      fillC = float4 (saturate (0.8.xxx - BorderColour.rgb), barC.a);
   }
   else {
      barC = StartColour;
      fillC = EndColour;
   }

   if (all (uv1 > bar_TL) && all (uv1 < cropBR)) { Fgnd = lerp (Fgnd, barC, barC.a); }
   else if (all (uv1 > cropTL) && all (uv1 < cropBR)) { Fgnd = lerp (Fgnd, fillC, fillC.a); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR)) { Fgnd = BorderColour; }

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//

// technique Static horizontal bar

DeclareEntryPoint (HorizStatic)
{
   float2 brdrEdge = (Border * 0.05).xx;

   brdrEdge.y *= _OutputAspectRatio;

   float Ypos = 1.0 - PosY;
   float Xpos = PosX;
   float height = Width / 10.0;
   float c_ramp = saturate ((uv1.x - Xpos) / Length);

   float2 cropTL = float2 (Xpos, Ypos - height);
   float2 cropBR = float2 (Xpos + Length, Ypos + height);
   float2 bar_BR = float2 (lerp (cropTL.x, cropBR.x, Amount), cropBR.y);

   float2 bordTL = saturate (cropTL - brdrEdge);
   float2 bordBR = saturate (cropBR + brdrEdge);

   float4 Fgnd = ReadPixel (Inp, uv1);
   float4 barC, fillC;

   if (ColourGrad) {
      barC = lerp (StartColour, EndColour, c_ramp);
      fillC = float4 (saturate (0.8.xxx - BorderColour.rgb), barC.a);
   }
   else {
      barC = StartColour;
      fillC = EndColour;
   }

   if (all (uv1 > cropTL) && all (uv1 < bar_BR)) { Fgnd = lerp (Fgnd, barC, barC.a); }
   else if (all (uv1 > cropTL) && all (uv1 < cropBR)) { Fgnd = lerp (Fgnd, fillC, fillC.a); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR)) { Fgnd = BorderColour; }

   return Fgnd;
}

