// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2013-02-14

/**
 Pixel Fixer is designed to repair dead pixels.  Add a clip to be corrected to a sequence
 and add the Pixel Fixer effect to the clip.  It will show a magnified area of the frame
 with a green target pixel in the middle.  It defaults to a single pixel but you can select
 a pixel pattern of up to 4 pixels in a group.  The green pixels will change as you select
 the different patterns.

 Using the on-screen cross-hairs, move the magnified area to the dead pixels and use the X
 Adjust and Y Adjust to fine tune the target over the dead pixel(s).  Check the "Fix" box
 to hide the dead pixel(s), then un-check "Magnify".

 Note that because of the nature of the repair work this is designed for, this effect will
 break resolution independence.  What leaves the effect is video the size and aspect ratio
 of the sequence that it's used in.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PixelFixer.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Pixel Fixer", "Stylize", "Repair tools", "Pixel Fixer repairs dead pixels based on adjacent pixel content", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Glass, "Magnify", kNoGroup, true);

DeclareFloatParam (mag, "Magnification", kNoGroup, kNoFlags, 2.0, 1.0, 10.0);

DeclareBoolParam (Proc, "Fix", kNoGroup, false);

DeclareIntParam (SetTechnique, "Pixel Pattern", kNoGroup, 0, "1|2H|2V|2DF|2DB|3A|3B|3C|3D|4");

DeclareFloatParam (c1x, "Pixel", kNoGroup, "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (c1y, "Pixel", kNoGroup, "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (fineX, "X Adjust", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (fineY, "Y Adjust", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);
DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float4 _red = float4 (0.0, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_main (sampler S, float2 uv, float2 xy1)
{
   float2 Center = float2 (c1x, 1.0 - c1y);
   float2 xy = uv;

   float Radius = 50.0 / _OutputWidth * mag;
   float Magnification = mag * 10.0;

   if (Glass) {
      float2 centerToPixel = uv - Center;
      float dist = length (centerToPixel / float2 (1, _OutputAspectRatio));

      if (dist < Radius) { xy = Center + centerToPixel / Magnification; }
   }

   return IsOutOfBounds (xy1) ? kTransparentBlack : tex2D (S, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Technique 1

DeclarePass (Bars1)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2 + B0 + B1 + B2) / 8.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_1)
{ return fn_main (Bars1, uv2, uv1); }

// Technique 2H

DeclarePass (Bars2H)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + A0 + B0 + B1) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixA2l.x && uv1.x <= pixA2r.x && uv1.y <= pixA2l.y && uv1.y >= pixA2r.y) {
      pixels = (Proc) ? (a2 + a3 + A3 + B2 + B3) / 5.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_2H)
{ return fn_main (Bars2H, uv2, uv1); }

// Technique 2V

DeclarePass (Bars2V)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB1l.x && uv1.x <= pixB1r.x && uv1.y <= pixB1l.y && uv1.y >= pixB1r.y) {
      pixels = (Proc) ? (B0 + B2 + b0 + b1 + b2) / 5.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_2V)
{ return fn_main (Bars2V, uv2, uv1); }

// Technique 2DF

DeclarePass (Bars2DF)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A1 = tex2D (Input, float2 (C1X, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA2l.x && uv1.x <= pixA2r.x && uv1.y <= pixA2l.y && uv1.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A1 + A3 + B2 + B3) / 7.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB1l.x && uv1.x <= pixB1r.x && uv1.y <= pixB1l.y && uv1.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + A1 + B0 + B2 + b0 + b1 + b2) / 7.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_2DF)
{ return fn_main (Bars2DF, uv2, uv1); }

// Technique 2DB

DeclarePass (Bars2DB)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2 + B0 + B1) / 7.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB2l.x && uv1.x <= pixB2r.x && uv1.y <= pixB2l.y && uv1.y >= pixB2r.y) {
      pixels = (Proc) ? (A2 + A3 + B1 + B3 + b1 + b2 + b3) / 7.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_2DB)
{ return fn_main (Bars2DB, uv2, uv1); }

// Technique 3A

DeclarePass (Bars3A)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + B0 + B1) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixA2l.x && uv1.x <= pixA2r.x && uv1.y <= pixA2l.y && uv1.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A3 + B1 + B3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB2l.x && uv1.x <= pixB2r.x && uv1.y <= pixB2l.y && uv1.y >= pixB2r.y) {
      pixels = (Proc) ? (A3 + B1 + B3 + b1 + b2 + b3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_3A)
{ return fn_main (Bars3A, uv2, uv1); }

// Technique 3B

DeclarePass (Bars3B)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A1 = tex2D (Input, float2 (C1X, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA2l.x && uv1.x <= pixA2r.x && uv1.y <= pixA2l.y && uv1.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A1 + A3 + B3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB1l.x && uv1.x <= pixB1r.x && uv1.y <= pixB1l.y && uv1.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + A1 + B0 + b0 + b1 + b2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB2l.x && uv1.x <= pixB2r.x && uv1.y <= pixB2l.y && uv1.y >= pixB2r.y) {
      pixels = (Proc) ? (A1 + A3 + B3 + b1 + b2 + b3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_3B)
{ return fn_main (Bars3B, uv2, uv1); }

// Technique 3C

DeclarePass (Bars3C)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + A2 + B0) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB1l.x && uv1.x <= pixB1r.x && uv1.y <= pixB1l.y && uv1.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + A2 + B0 + b0 + b1 + b2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB2l.x && uv1.x <= pixB2r.x && uv1.y <= pixB2l.y && uv1.y >= pixB2r.y) {
      pixels = (Proc) ? (A2 + A3 + B3 + b1 + b2 + b3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_3C)
{ return fn_main (Bars3C, uv2, uv1); }

// Technique 3D

DeclarePass (Bars3D)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + B0 + B2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixA2l.x && uv1.x <= pixA2r.x && uv1.y <= pixA2l.y && uv1.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A3 + B2 + B3) / 6.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB1l.x && uv1.x <= pixB1r.x && uv1.y <= pixB1l.y && uv1.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + B0 + B2 + b0 + b1 + b2) / 6.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_3D)
{ return fn_main (Bars3D, uv2, uv1); }

// Technique 4

DeclarePass (Bars4)
{
   float4 pixels = ReadPixel (Input, uv1);

   float pixX = 1.0 / _OutputWidth;
   float pixY = pixX * _OutputAspectRatio;

   float C1X = c1x + (fineX / 100.0);
   float C1Y = c1y + (fineY / 100.0);

   float2 pixA1l = float2 (C1X, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA1r = float2 (C1X, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixA2l = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (-pixX, pixY) * 0.5);
   float2 pixA2r = float2 (C1X + pixX, 1.0 - C1Y) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB1l = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB1r = float2 (C1X, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);
   float2 pixB2l = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (-pixX, pixY) * 0.5);
   float2 pixB2r = float2 (C1X + pixX, 1.0 - C1Y + pixY) + (float2 (pixX, -pixY) * 0.5);

   float4 a0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y - pixY));
   float4 a1 = tex2D (Input, float2 (C1X, 1.0 - C1Y - pixY));
   float4 a2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y - pixY));
   float4 a3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y - pixY));
   float4 A0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y));
   float4 A3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y));
   float4 B0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY));
   float4 B3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY));
   float4 b0 = tex2D (Input, float2 (C1X - pixX, 1.0 - C1Y + pixY + pixY));
   float4 b1 = tex2D (Input, float2 (C1X, 1.0 - C1Y + pixY + pixY));
   float4 b2 = tex2D (Input, float2 (C1X + pixX, 1.0 - C1Y + pixY + pixY));
   float4 b3 = tex2D (Input, float2 (C1X + pixX + pixX, 1.0 - C1Y + pixY + pixY));

   pixels.a = 0.0;

   if (uv1.x >= pixA1l.x && uv1.x <= pixA1r.x && uv1.y <= pixA1l.y && uv1.y >= pixA1r.y) {
      pixels = (Proc) ? (a0 + a1 + a2 + A0 + B0) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixA2l.x && uv1.x <= pixA2r.x && uv1.y <= pixA2l.y && uv1.y >= pixA2r.y) {
      pixels = (Proc) ? (a1 + a2 + a3 + A3 + B3) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB1l.x && uv1.x <= pixB1r.x && uv1.y <= pixB1l.y && uv1.y >= pixB1r.y) {
      pixels = (Proc) ? (A0 + B0 + b0 + b1 + b2) / 5.0 : _red;
      pixels.a = 1.0;
   }

   if (uv1.x >= pixB2l.x && uv1.x <= pixB2r.x && uv1.y <= pixB2l.y && uv1.y >= pixB2r.y) {
      pixels = (Proc) ? (A3 + B3 + b1 + b2 + b3) / 5.0 : _red;
      pixels.a = 1.0;
   }

   return IsOutOfBounds (uv1) ? kTransparentBlack : pixels;
}

DeclareEntryPoint (PixelFixer_4)
{ return fn_main (Bars4, uv2, uv1); }

