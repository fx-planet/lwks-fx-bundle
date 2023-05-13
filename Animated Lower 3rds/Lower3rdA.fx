// @Maintainer jwrl
// @Released 2023-05-13
// @Author jwrl
// @Created 2018-03-15

/**
 The previous version of this effect moved a coloured bar on from one side of the screen
 then lowered or raised it to reveal an alpha image connected to the input In_1.  This
 version can still do that, but has been enhanced so that the bar can just move vertically
 to reveal the image, or just move horizontally to reveal it.  This makes it possible to
 wipe on text above the line as the bar moves in, then reveal further text by lowering the
 bar.  The combination moves are all done with one operation using the Transition.

 Bar length, width, colour and start and end positions are all adjustable, as is the
 opacity of the combined effect to allow fading on and off if desired.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdA.fx
//
// Version history:
//
// Updated 2023-05-13 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower third A", "Text", "Animated Lower 3rds", "Moves a coloured bar from the edge of screen and lowers or raises it to reveal text", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Transition, "Transition", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Direction", "Text settings", 0, "Visible above bar|Visible below bar"); 
DeclareIntParam (ArtAlpha, "Text type", "Text settings", 1, "Video/External image|Crawl/Roll/Title/Image key");

DeclareBoolParam (SetupText, "Setup text position", "Text settings", true);

DeclareFloatParam (TxtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (TxtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (BarWidth, "Width", "Line settings", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (BarLength, "Length", "Line settings", kNoFlags, 0.8, 0.0, 1.0);

DeclareFloatParam (Bar_X, "Position", "Line settings", "SpecifiesPointX", 0.05, 0.0, 1.0);
DeclareFloatParam (Bar_Y, "Position", "Line settings", "SpecifiesPointY", 0.2, 0.0, 1.0);

DeclareColourParam (BarColour, "Colour", "Line settings", kNoFlags, 1.0, 0.0, 0.0, 1.0);

DeclareFloatParam (BarPosX, "Displacement", "Line start position", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (BarPosY, "Displacement", "Line start position", "SpecifiesPointY", 0.0, -1.0, 1.0);

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

float4 fn_bar (float2 uv)
{
   float _width = 0.005 + (BarWidth * 0.1);

   float2 xy1 = float2 (Bar_X, 1.0 - Bar_Y - (_width * 0.5));
   float2 xy2 = xy1 + float2 (BarLength, _width);

   return inRange (uv, xy1, xy2) ? BarColour : kTransparentBlack;
}

float2 fn_bar_move (float2 uv)
{
   float PosXfix = abs (BarPosX);
   float PosYfix = abs (BarPosY * _OutputAspectRatio);

   float bar_range = (PosXfix + PosYfix) * 1.05;
   float transRate = saturate (Transition);
   float PosXoffs  = bar_range > 0.0 ? PosXfix / bar_range : 0.0;

   PosXfix = PosXfix > 0.0 ? bar_range / PosXfix : 0.0;
   PosYfix = PosYfix > 0.0 ? bar_range / PosYfix : 0.0;

   float2 xy;

   xy.x = uv.x * saturate ((PosXoffs - transRate) * PosXfix);
   xy.y = uv.y * saturate ((1.0 - transRate) * PosYfix);

   return xy;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Visible above bar

DeclarePass (Input_1_0)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_0)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Bar_0)
{ return fn_bar (uv0); }

DeclareEntryPoint (Lower3rdA_AboveBar)
{
   float2 xy1 = fn_bar_move (float2 (BarPosX, -BarPosY));
   float2 xy2 = float2 (TxtPosX, -TxtPosY);

   float x = xy1.x + Bar_X;
   float y = 1.0 - Bar_Y + xy1.y;

   bool vis = BarPosX < 0.0 ? uv3.x <= x + BarLength : uv3.x >= x;

   xy1 = uv3 - xy1;

   float4 bar = tex2D (Bar_0, xy1);
   float4 Fgd = (uv3.y >= y) && !SetupText ? kTransparentBlack : tex2D (Input_1_0, uv3 - xy2);

   if (!(vis || SetupText)) Fgd = kTransparentBlack;

   if (ArtAlpha == 1) {
      Fgd.a = pow (Fgd.a, 0.5);
      Fgd.rgb *= Fgd.a;
   }

   Fgd = lerp (Fgd, bar, bar.a);

   return lerp (tex2D (Input_2_0, uv3), Fgd, Fgd.a * Opacity);
}

// Visible below bar 

DeclarePass (Input_1_1)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2_1)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Bar_1)
{ return fn_bar (uv0); }

DeclareEntryPoint (Lower3rdA_BelowBar)
{
   float2 xy1 = fn_bar_move (float2 (BarPosX, -BarPosY));
   float2 xy2 = float2 (TxtPosX, -TxtPosY);

   float x = xy1.x + Bar_X;
   float y = 1.0 - Bar_Y + xy1.y;

   bool vis = BarPosX < 0.0 ? uv3.x <= x + BarLength : uv3.x >= x;

   xy1 = uv3 - xy1;

   float4 bar = tex2D (Bar_1, xy1);
   float4 Fgd = (uv3.y <= y) && !SetupText ? kTransparentBlack : tex2D (Input_1_1, uv3 - xy2);

   if (!(vis || SetupText)) Fgd = kTransparentBlack;

   if (ArtAlpha == 1) {
      Fgd.a = pow (Fgd.a, 0.5);
      Fgd.rgb *= Fgd.a;
   }

   Fgd = lerp (Fgd, bar, bar.a);

   return lerp (tex2D (Input_2_1, uv3), Fgd, Fgd.a * Opacity);
}

