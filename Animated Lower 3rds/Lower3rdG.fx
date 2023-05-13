// @Maintainer jwrl
// @Released 2023-05-13
// @Author jwrl
// @Created 2018-03-19

/**
 This uses a clock wipe to wipe on a box around text.  The box can wipe on clockwise or
 anticlockwise, and start from the top or the bottom.  Once the box is almost complete a
 fill colour dissolves in, along with the text.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Lower3rdG.fx
//
// Version history:
//
// Updated 2023-05-13 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lower third G", "Text", "Animated Lower 3rds", "This uses a clock wipe to wipe on a box which then reveals the text", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In_1, In_2);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Transition, "Transition", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Direction, "Transition direction", kNoGroup, 0, "Clockwise top|Anticlockwise top|Clockwise bottom|Anticlockwise bottom");

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (ArtAlpha, "Text type", "Text settings", 1, "Video/External image|Crawl/Roll/Title/Image key");

DeclareBoolParam (SetupText, "Setup text position", "Text settings", true);

DeclareFloatParam (ArtPosX, "Position", "Text settings", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (ArtPosY, "Position", "Text settings", "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (BoxWidth, "Width", "Surround", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (BoxHeight, "Height", "Surround", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (LineWidth, "Line weight", "Surround", kNoFlags, 0.2, 0.0, 1.0);

DeclareFloatParam (CentreX, "Origin", "Surround", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (CentreY, "Origin", "Surround", "SpecifiesPointY", 0.0, -1.0, 1.0);
DeclareFloatParam (CentreZ, "Origin", "Surround", "SpecifiesPointZ", 0.0, -1.0, 1.0);

DeclareColourParam (LineColour, "Line colour", "Surround", kNoFlags, 1.0, 1.0, 1.0, 1.0);
DeclareColourParam (FillColour, "Fill colour", "Surround", kNoFlags, 0.0, 0.2, 0.8, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define TWO_PI  6.2831853072
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input_1)
{ return ReadPixel (In_1, uv1); }

DeclarePass (Input_2)
{ return ReadPixel (In_2, uv2); }

DeclarePass (Wipe)
{
   float2 xy = (uv0 - 0.5.xx);
   float2 az = abs (xy);
   float2 cz = float2 (BoxWidth, BoxHeight) * 0.5;

   float trans = max ((Transition - 0.75) * 4.0, 0.0);

   float4 out_ln = (cz.x < az.x) || (cz.y < az.y) ? LineColour : kTransparentBlack;
   float4 retval = (az.x < cz.x) && (az.y < cz.y) ? lerp (kTransparentBlack, FillColour, trans) : kTransparentBlack;

   cz += float2 (1.0, _OutputAspectRatio) * LineWidth * 0.025;

   if ((az.x > cz.x) || (az.y > cz.y)) out_ln = kTransparentBlack;

   float x, y;
   float scale = distance (xy, 0.0);

   trans = sin ((1.0 - min (Transition * 1.25, 1.0)) * HALF_PI);
   sincos (trans * TWO_PI, x, y);

   xy  = float2 (x, y) * scale;
   xy += 0.5.xx;

   if (trans < 0.25) {
      if ((uv0.x > 0.5) && (uv0.x < xy.x) && (uv0.y < xy.y)) out_ln = kTransparentBlack;
   }
   else if (trans < 0.5) {
      if ((uv0.x > 0.5) && (uv0.y < 0.5)) out_ln = kTransparentBlack;
      if ((uv0.x > xy.x) && (uv0.y > xy.y)) out_ln = kTransparentBlack;
   }
   else if (trans < 0.75) {
      if ((uv0.x > 0.5) || ((uv0.x > xy.x) && (uv0.y > xy.y))) out_ln = kTransparentBlack;
   }
   else if ((uv0.x > 0.5) || (uv0.y > 0.5) || ((uv0.x < xy.x) && (uv0.y < xy.y))) out_ln = kTransparentBlack;

   return lerp (retval, out_ln, out_ln.a);
}

DeclareEntryPoint (Lower3rdG)
{
   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);
   float trans = max ((Transition - 0.75) * 4.0, 0.0);

   float4 Text = tex2D (Input_1, uv3 - float2 (ArtPosX, -ArtPosY));
   float4 Bgnd = tex2D (Input_2, uv3);

   if (ArtAlpha == 1) {
      Text.a = pow (Text.a, 0.5);
      Text.rgb *= Text.a;
   }

   float2 xy, pos;

   if (Direction < 2) {
      xy = uv3 - 0.5.xx;
      pos = float2 (-CentreX, CentreY);
   }
   else {
      xy = 0.5.xx - uv3;
      pos = float2 (CentreX, -CentreY);
   }

   if ((Direction == 0) || (Direction == 2)) {
      xy.x = -xy.x;
      pos.x = -pos.x;
   }

   xy = (xy / scale) + pos + 0.5.xx;

   float4 Mask = lerp (tex2D (Wipe, xy), Text, Text.a * trans);

   return lerp (Bgnd, Mask, Mask.a * Opacity);
}

