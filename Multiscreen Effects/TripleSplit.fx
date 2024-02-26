// @Maintainer jwrl
// @Released 2024-02-26
// @Author jwrl
// @Created 2024-02-26

/**
 This is an adjunct to the quad split effect that's designed to do three-way splits.
 There are the three split types avilable.  The first, "Left V1, upper R V2, lower
 R V3", produces a main panel from the V1 input, with two smaller panels on the right
 containing V2 and V3.  The second, "Upper L V1, lower L V2, right V3: is the reverse
 of that effect.

 "Left V1, middle V2, right V3" has three vertical panels that can be independently
 adjusted in height to mimic the common news interview effect.  "Horizontal bands"
 and "Vertical bands" produce strip views of the three video inputs.

 The overall panel size can be horizontally and vertically adjusted on the effects, and
 individual panels can be adjusted to a degree.  The size and position of the video in
 the panels automatically tracks the panels, but can be overriden.  A hard edged border
 is provided, which expands and contracts in size around the video edges.

 Finally background video is supported, and can be zoomed and positioned as desired.
 Unlike most Lightworks effects, no masking is provided.  It was hard to work out how
 it could be sensibly implemented.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TripleSplit.fx
//
// Version history:
//
// Built 2024-02-26 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Triple split", "DVE", "Multiscreen Effects", "A range of three way splits over a background", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (V1, V2, V3);

DeclareInput (Bg, Linear);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SplitType, "Split type", kNoGroup, 0, "Left V1, upper R V2, lower R V3|Upper L V1, lower L V2, right V3|Left V1, middle V2, right V3|Horizontal bands|Vertical bands");

DeclareFloatParam (Hsize, "H size", kNoGroup, "DisplayAsPercentage", 1.0, 0.25, 1.25);
DeclareFloatParam (Vsize, "V size", kNoGroup, "DisplayAsPercentage", 1.0, 0.25, 1.25);

DeclareFloatParam (Divider1, "Divider 1", kNoGroup, "DisplayAsLiteral", 0.5, 0.0, 1.0);
DeclareFloatParam (Divider2, "Divider 2", kNoGroup, "DisplayAsLiteral", 0.5, 0.0, 1.0);

DeclareFloatParam (PosX, "Position", kNoGroup, "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (PosY, "Position", kNoGroup, "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareFloatParam (Size1, "Size", "Video 1", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (Aspect1, "Aspect ratio", "Video 1", kNoFlags, 1.0, 0.25, 4.0);

DeclareFloatParam (Xpos1, "Position", "Video 1", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ypos1, "Position", "Video 1", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Size2, "Size", "Video 2", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (Aspect2, "Aspect ratio", "Video 2", kNoFlags, 1.0, 0.25, 4.0);

DeclareFloatParam (Xpos2, "Position", "Video 2", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ypos2, "Position", "Video 2", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Size3, "Size", "Video 3", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (Aspect3, "Aspect ratio", "Video 3", kNoFlags, 1.0, 0.25, 4.0);

DeclareFloatParam (Xpos3, "Position", "Video 3", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ypos3, "Position", "Video 3", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (BgSize, "Size", "Background", "DisplayAsPercentage", 1.0, 1.0, 10.0);
DeclareFloatParam (BgAspect, "Aspect ratio", "Background", kNoFlags, 1.0, 0.6, 1.7);

DeclareFloatParam (BgXpos, "Position", "Background", "SpecifiesPointX", 0.5, -5.0, 5.0);
DeclareFloatParam (BgYpos, "Position", "Background", "SpecifiesPointY", 0.5, -5.0, 5.0);

DeclareFloatParam (BorderWidth, "Width", "Border", kNoFlags, 0.1, 0.0, 1.0);

DeclareColourParam (BorderColour, "Colour", "Border", kNoFlags, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 triplex_0 (sampler S1, sampler S2, sampler S3, float2 uv)
{
   float Xwidth = BorderWidth * 0.05;
   float Ywidth = Xwidth;
   float x_1 = 0.1;
   float y_1 = 0.1;

   if (_OutputAspectRatio < 1.0) {
      Ywidth *= _OutputAspectRatio;
      y_1 *= _OutputAspectRatio;
   }
   else {
      Xwidth /= _OutputAspectRatio;
      x_1 /= _OutputAspectRatio;
   }

   float x_2 = lerp (0.475 - x_1, 0.933333 - x_1, Divider1); // lerp (x_1 + 0.066667, x_1 + 0.525, Divider1)
   float y_2 = lerp (0.85 - y_1, y_1 + 0.15, Divider2);

   float3 xx = ((float3 (x_1, x_2, 1.0 - x_1) - 0.5.xxx) * Hsize) + PosX.xxx;
   float3 yy = ((float3 (y_1, y_2, 1.0 - y_1) - 0.5.xxx) * Vsize) + (1.0 - PosY).xxx;

   float4 border = kTransparentBlack;
   float4 retval = kTransparentBlack;

   if ((uv.y > yy.x - Ywidth) && (uv.y < yy.z + Ywidth)) {
      if (((uv.x > xx.x - Xwidth) && (uv.x < xx.x + Xwidth)) ||
          ((uv.x > xx.y - Xwidth) && (uv.x < xx.y + Xwidth)) ||
          ((uv.x > xx.z - Xwidth) && (uv.x < xx.z + Xwidth))) {
          border = BorderColour;
          border.a = 1.0;
      }
   }

   if ((uv.x > xx.x) && (uv.x < xx.z)) {
      if (((uv.y > yy.x - Ywidth) && (uv.y < yy.x + Ywidth)) ||
          ((uv.y > yy.y - Ywidth) && (uv.y < yy.y + Ywidth) && (uv.x > xx.y)) ||
          ((uv.y > yy.z - Ywidth) && (uv.y < yy.z + Ywidth))) {
          border = BorderColour;
          border.a = 1.0;
      }
   }

   float2 xy1 = ((uv - (float2 (xx.x + xx.y, yy.x + yy.z) / 2.0)) / (yy.z - yy.x)) + 0.5.xx;
   float2 xy2 = ((uv - (float2 (xx.y + xx.z, yy.x + yy.y) / 2.0)) / (yy.y - yy.x)) + 0.5.xx;
   float2 xy3 = ((uv - (float2 (xx.y + xx.z, yy.y + yy.z) / 2.0)) / (yy.z - yy.y)) + 0.5.xx;

   if ((uv.x > xx.x) && (uv.x < xx.y) && (uv.y > yy.x) && (uv.y < yy.z)) {
      retval = ReadPixel (S1, xy1);
      retval.a = 1.0;
   }
   else if ((uv.x > xx.y) && (uv.x < xx.z) && (uv.y > yy.x) && (uv.y < yy.y)) {
      retval = ReadPixel (S2, xy2);
      retval.a = 1.0;
   }
   else if ((uv.x > xx.y) && (uv.x < xx.z) && (uv.y > yy.y) && (uv.y < yy.z)) {
      retval = ReadPixel (S3, xy3);
      retval.a = 1.0;
   }

   return lerp (retval, border, border.a);
}

float4 triplex_1 (sampler S1, sampler S2, sampler S3, float2 uv)
{
   float Xwidth = BorderWidth * 0.05;
   float Ywidth = Xwidth;
   float x_1 = 0.1;
   float y_1 = 0.1;

   if (_OutputAspectRatio < 1.0) {
      Ywidth *= _OutputAspectRatio;
      y_1 *= _OutputAspectRatio;
   }
   else {
      Xwidth /= _OutputAspectRatio;
      x_1 /= _OutputAspectRatio;
   }

   float x_2 = lerp (x_1 + 0.066667, x_1 + 0.525, Divider1);
   float y_2 = lerp (0.85 - y_1, y_1 + 0.15, Divider2);

   float3 xx = ((float3 (x_1, x_2, 1.0 - x_1) - 0.5.xxx) * Hsize) + PosX.xxx;
   float3 yy = ((float3 (y_1, y_2, 1.0 - y_1) - 0.5.xxx) * Vsize) + (1.0 - PosY).xxx;

   float4 border = kTransparentBlack;
   float4 retval = kTransparentBlack;

   if ((uv.y > yy.x - Ywidth) && (uv.y < yy.z + Ywidth)) {
      if (((uv.x > xx.x - Xwidth) && (uv.x < xx.x + Xwidth)) ||
          ((uv.x > xx.y - Xwidth) && (uv.x < xx.y + Xwidth)) ||
          ((uv.x > xx.z - Xwidth) && (uv.x < xx.z + Xwidth))) {
          border = BorderColour;
          border.a = 1.0;
      }
   }

   if ((uv.x > xx.x) && (uv.x < xx.z)) {
      if (((uv.y > yy.x - Ywidth) && (uv.y < yy.x + Ywidth)) ||
          ((uv.y > yy.y - Ywidth) && (uv.y < yy.y + Ywidth) && (uv.x < xx.y)) ||
          ((uv.y > yy.z - Ywidth) && (uv.y < yy.z + Ywidth))) {
          border = BorderColour;
          border.a = 1.0;
      }
   }

   float2 xy1 = ((uv - (float2 (xx.x + xx.y, yy.x + yy.y) / 2.0)) / (yy.y - yy.x)) + 0.5.xx;
   float2 xy2 = ((uv - (float2 (xx.x + xx.y, yy.y + yy.z) / 2.0)) / (yy.z - yy.y)) + 0.5.xx;
   float2 xy3 = ((uv - (float2 (xx.y + xx.z, yy.x + yy.z) / 2.0)) / (yy.z - yy.x)) + 0.5.xx;

   if ((uv.x > xx.x) && (uv.x < xx.y) && (uv.y > yy.x) && (uv.y < yy.y)) {
      retval = ReadPixel (S1, xy1);
      retval.a = 1.0;
   }
   else if ((uv.x > xx.x) && (uv.x < xx.y) && (uv.y > yy.y) && (uv.y < yy.z)) {
      retval = ReadPixel (S2, xy2);
      retval.a = 1.0;
   }
   else if ((uv.x > xx.y) && (uv.x < xx.z) && (uv.y > yy.x) && (uv.y < yy.z)) {
      retval = ReadPixel (S3, xy3);
      retval.a = 1.0;
   }

   return lerp (retval, border, border.a);
}

float4 triplex_2 (sampler S1, sampler S2, sampler S3, float2 uv)
{
   float Xwidth = BorderWidth * 0.05;
   float Ywidth = Xwidth;
   float x_1 = 0.1;
   float y_1 = 0.1;

   if (_OutputAspectRatio < 1.0) {
      Ywidth *= _OutputAspectRatio;
      y_1 *= _OutputAspectRatio;
   }
   else {
      Xwidth /= _OutputAspectRatio;
      x_1 /= _OutputAspectRatio;
   }

   float x_2 = lerp (x_1 + 0.1, 0.3625, Divider1);
   float y_2 = lerp (0.38, y_1, Divider2);

   float3 yy = ((float3 (y_1, y_2, 1.0 - y_1) - 0.5.xxx) * Vsize) + (1.0 - PosY).xxx;

   float4 xx = ((float4 (x_1, x_2, 1.0 - x_2, 1.0 - x_1) - 0.5.xxxx) * Hsize) + PosX.xxxx;
   float4 border = kTransparentBlack;
   float4 retval = kTransparentBlack;

   if ((uv.y > yy.y - Ywidth) && (uv.y < yy.z + Ywidth)) {
      if (((uv.x > xx.x - Xwidth) && (uv.x < xx.x + Xwidth)) ||
          ((uv.x > xx.w - Xwidth) && (uv.x < xx.w + Xwidth))) {
          border = BorderColour;
          border.a = 1.0;
      }
   }

   if ((uv.y > yy.x - Ywidth) && (uv.y < yy.z + Ywidth)) {
      if (((uv.x > xx.y - Xwidth) && (uv.x < xx.y + Xwidth)) ||
          ((uv.x > xx.z - Xwidth) && (uv.x < xx.z + Xwidth))) {
          border = BorderColour;
          border.a = 1.0;
      }
   }

   if ((uv.x > xx.y) && (uv.x < xx.z) && (uv.y > yy.x - Ywidth) && (uv.y < yy.x + Ywidth)) {
       border = BorderColour;
       border.a = 1.0;
   }

   if (((uv.x > xx.x) && (uv.x < xx.y)) || ((uv.x > xx.z) && (uv.x < xx.w))) {
      if ((uv.y > yy.y - Ywidth) && (uv.y < yy.y + Ywidth)) {
          border = BorderColour;
          border.a = 1.0;
      }
   }

   if ((uv.x > xx.x) && (uv.x < xx.w) && (uv.y > yy.z - Ywidth) && (uv.y < yy.z + Ywidth)) {
       border = BorderColour;
       border.a = 1.0;
   }

   float2 xy1 = ((uv - (float2 (xx.x + xx.y, yy.y + yy.z) / 2.0)) / (yy.z - yy.y)) + 0.5.xx;
   float2 xy2 = ((uv - (float2 (xx.y + xx.z, yy.x + yy.z) / 2.0)) / (yy.z - yy.x)) + 0.5.xx;
   float2 xy3 = ((uv - (float2 (xx.z + xx.w, yy.y + yy.z) / 2.0)) / (yy.z - yy.y)) + 0.5.xx;

   if ((uv.x > xx.x) && (uv.x < xx.y) && (uv.y > yy.y) && (uv.y < yy.z)) {
      retval = ReadPixel (S1, xy1);
      retval.a = 1.0;
   }
   else if ((uv.x > xx.y) && (uv.x < xx.z) && (uv.y > yy.x) && (uv.y < yy.z)) {
      retval = ReadPixel (S2, xy2);
      retval.a = 1.0;
   }
   else if ((uv.x > xx.z) && (uv.x < xx.w) && (uv.y > yy.y) && (uv.y < yy.z)) {
      retval = ReadPixel (S3, xy3);
      retval.a = 1.0;
   }

   return lerp (retval, border, border.a);
}

float4 triplex_3 (sampler S1, sampler S2, sampler S3, float2 uv)
{
   float Xwidth = BorderWidth * 0.05;
   float Ywidth = Xwidth;
   float y_1 = lerp (0.166666, -0.5, Divider1);
   float y_2 = lerp (0.5, -0.166666, Divider2);

   if (y_2 < y_1) { float t = y_2; y_2 = y_1; y_1 = t; }

   if (_OutputAspectRatio < 1.0) { Ywidth *= _OutputAspectRatio; }
   else Xwidth /= _OutputAspectRatio;

   float2 xx = (float2 (-0.5, 0.5) * Hsize) + PosX.xx;

   float4 yy = (float4 (-0.5, y_1, y_2, 0.5) * Vsize) + (1.0 - PosY).xxxx;
   float4 border = kTransparentBlack;
   float4 retval = kTransparentBlack;

   if ((uv.x > xx.x - Xwidth) && (uv.x < xx.y + Xwidth)) {
      if (((uv.y > yy.x - Ywidth) && (uv.y < yy.x + Ywidth)) ||
          ((uv.y > yy.y - Ywidth) && (uv.y < yy.y + Ywidth)) ||
          ((uv.y > yy.z - Ywidth) && (uv.y < yy.z + Ywidth)) ||
          ((uv.y > yy.w - Ywidth) && (uv.y < yy.w + Ywidth))) {
         border = BorderColour;
         border.a = 1.0;
      }
   }

   if ((uv.y > yy.x - Ywidth) && (uv.y < yy.w + Ywidth)) {
      if ((uv.x > xx.x - Xwidth) && (uv.x < xx.x + Xwidth) ||
          (uv.x > xx.y - Xwidth) && (uv.x < xx.y + Xwidth)) {
         border = BorderColour;
         border.a = 1.0;
      }
   }

   float x = xx.x + xx.y;
   float s = xx.y - xx.x;

   float2 xy1 = ((uv - (float2 (x, yy.x + yy.y) / 2.0)) / s) + 0.5.xx;
   float2 xy2 = ((uv - (float2 (x, yy.y + yy.z) / 2.0)) / s) + 0.5.xx;
   float2 xy3 = ((uv - (float2 (x, yy.z + yy.w) / 2.0)) / s) + 0.5.xx;

   if ((uv.x > xx.x) && (uv.x < xx.y)) {
      if ((uv.y > yy.x) && (uv.y < yy.y)) {
         retval = ReadPixel (S1, xy1);
         retval.a = 1.0;
      }
      else if ((uv.y > yy.y) && (uv.y < yy.z)) {
         retval = ReadPixel (S2, xy2);
         retval.a = 1.0;
      }
      else if ((uv.y > yy.z) && (uv.y < yy.w)) {
         retval = ReadPixel (S3, xy3);
         retval.a = 1.0;
      }
   }

   return lerp (retval, border, border.a);
}

float4 triplex_4 (sampler S1, sampler S2, sampler S3, float2 uv)
{
   float Xwidth = BorderWidth * 0.05;
   float Ywidth = Xwidth;
   float x_1 = lerp (-0.5, 0.166666, Divider1);
   float x_2 = lerp (-0.166666, 0.5, Divider2);

   if (x_2 < x_1) { float t = x_2; x_2 = x_1; x_1 = t; }

   if (_OutputAspectRatio < 1.0) { Ywidth *= _OutputAspectRatio; }
   else Xwidth /= _OutputAspectRatio;

   float2 yy = (float2 (-0.5, 0.5) * Vsize) + PosY.xx;

   float4 xx = (float4 (-0.5, x_1, x_2, 0.5) * Hsize) + (1.0 - PosX).xxxx;
   float4 border = kTransparentBlack;
   float4 retval = kTransparentBlack;

   if ((uv.x > xx.x - Xwidth) && (uv.x < xx.w + Xwidth)) {
      if ((uv.y > yy.x - Ywidth) && (uv.y < yy.x + Ywidth) ||
          (uv.y > yy.y - Ywidth) && (uv.y < yy.y + Ywidth)) {
         border = BorderColour;
         border.a = 1.0;
      }
   }

   if ((uv.y > yy.x - Ywidth) && (uv.y < yy.y + Ywidth)) {
      if (((uv.x > xx.x - Xwidth) && (uv.x < xx.x + Xwidth)) ||
          ((uv.x > xx.y - Xwidth) && (uv.x < xx.y + Xwidth)) ||
          ((uv.x > xx.z - Xwidth) && (uv.x < xx.z + Xwidth)) ||
          ((uv.x > xx.w - Xwidth) && (uv.x < xx.w + Xwidth))) {
         border = BorderColour;
         border.a = 1.0;
      }
   }

   float s = yy.y - yy.x;
   float y = yy.x + yy.y;

   float2 xy1 = ((uv - (float2 (xx.x + xx.y, y) / 2.0)) / s) + 0.5.xx;
   float2 xy2 = ((uv - (float2 (xx.y + xx.z, y) / 2.0)) / s) + 0.5.xx;
   float2 xy3 = ((uv - (float2 (xx.z + xx.w, y) / 2.0)) / s) + 0.5.xx;

   if ((uv.y > yy.x) && (uv.y < yy.y)) {
      if ((uv.x > xx.x) && (uv.x < xx.y)) {
         retval = ReadPixel (S1, xy1);
         retval.a = 1.0;
      }
      else if ((uv.x > xx.y) && (uv.x < xx.z)) {
         retval = ReadPixel (S2, xy2);
         retval.a = 1.0;
      }
      else if ((uv.x > xx.z) && (uv.x < xx.w)) {
         retval = ReadPixel (S3, xy3);
         retval.a = 1.0;
      }
   }

   return lerp (retval, border, border.a);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg1)
// We first map the foreground coordinates for each input to the sequence geometry and
// apply the scaling and positioning.
{
   // First set up the coordinates around zero and adjust the position.

   float2 xy = uv1 - float2 (Xpos1, 1.0 - Ypos1);

   // Now we apply the scale factor

   xy /= Size1;

   if (SplitType != 3) { xy.x *= Aspect1; }
   else xy.y /= Aspect1;

   xy += 0.5.xx;

   // And return the video mapped to sequence coordinates

   return ReadPixel (V1, xy);
}

DeclarePass (Fg2)
{
   float2 xy = uv2 - float2 (Xpos2, 1.0 - Ypos2);

   xy /= Size2;

   if (SplitType != 3) { xy.x *= Aspect2; }
   else xy.y /= Aspect2;

   xy += 0.5.xx;

   return ReadPixel (V2, xy);
}

DeclarePass (Fg3)
{
   float2 xy = uv3 - float2 (Xpos3, 1.0 - Ypos3);

   xy /= Size3;

   if (SplitType != 3) { xy.x *= Aspect3; }
   else xy.y /= Aspect3;

   xy += 0.5.xx;

   return ReadPixel (V3, xy);
}

DeclarePass (Bgd)
// We now map the background coordinates to the sequence geometry and apply the zoom.
{
   float2 xy = uv4 - float2 (BgXpos, 1.0 - BgYpos);

   xy /= BgSize;

   if (BgAspect < 1.0) { xy.x *= BgAspect; }
   else xy.y /= BgAspect;

   xy += 0.5.xx;

   return ReadPixel (Bg, xy);
}

DeclareEntryPoint (TripleSplit)
{
   float4 retval;

   if (SplitType == 0) { retval = triplex_0 (Fg1, Fg2, Fg3, uv5); }
   else if (SplitType == 1) { retval = triplex_1 (Fg1, Fg2, Fg3, uv5); }
   else if (SplitType == 2) { retval = triplex_2 (Fg1, Fg2, Fg3, uv5); }
   else if (SplitType == 3) { retval = triplex_3 (Fg1, Fg2, Fg3, uv5); }
   else retval = triplex_4 (Fg1, Fg2, Fg3, uv5);

   return lerp (tex2D (Bgd, uv5), retval, retval.a);
}

