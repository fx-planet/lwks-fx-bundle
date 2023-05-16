// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2012-10-03

/**
 Glint Effect creates star filter-like highlights, with 4, 6 or 8 points selectable.  The
 glints/stars can be rotated and may be normal or rainbow coloured.  They may also be
 blurred, and the "Show Glint" checkbox will display the glints over a black background.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Glint.fx by Gary Hango (khaver)
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Glint", "Stylize", "Filters", "Creates rotatable star filter-like highlights, with 4, 6 or 8 points selectable", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Star Points", kNoGroup, 0, "4|6|8");

DeclareFloatParam (Threshold, "Threshold", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Brightness, "Brightness", kNoGroup, kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (Length, "Length", kNoGroup, kNoFlags, 5.0, 0.0, 20.0);
DeclareFloatParam (Rotation, "Rotation", kNoGroup, kNoFlags, 0.0, 0.0, 360.0);
DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (RainbowGlint, "Rainbow Glint", kNoGroup, false);
DeclareBoolParam (BlurGlint, "Blur Glint", kNoGroup, false);
DeclareBoolParam (ShowGlint, "Show Glint", kNoGroup, false);

DeclareFloatParam (_OutputWidth);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SPIN_000 0.0       // 0 degrees in radians
#define SPIN_030 0.5236    // 30 degrees
#define SPIN_045 0.7854    // 45 degrees
#define SPIN_090 1.5708    // 90 degrees
#define SPIN_135 2.35619   // 135 degrees
#define SPIN_150 2.61799   // 150 degrees
#define SPIN_180 3.14159   // 180 degrees
#define SPIN_210 3.66519   // 210 degrees
#define SPIN_225 3.92699   // 225 degrees
#define SPIN_270 4.71239   // 270 degrees
#define SPIN_315 5.49779   // 315 degrees
#define SPIN_330 5.75959   // 330 degrees

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 adjust (sampler S, float2 uv)
{
   float4 Color = ReadPixel (S, uv);

   float lum = (Color.r + Color.g + Color.b) / 3.0;
   float adjust = 1.0 - Threshold;

   return (adjust > lum) ? kTransparentBlack : RainbowGlint ? 1.0.xxxx : Color;
}

float4 stretch_1 (sampler S, float2 xy, float angle)
{
   float3 delt, ret = kTransparentBlack;
   float3 bow = float2 (1.0, 0.0).xxy;

   float2 offset;

   float bluramount = Length * 0.5 / _OutputWidth;
   float MapAngle = angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= bluramount;
   offset.y *= _OutputAspectRatio;

   for (int count = 0; count < 16; count++) {
      bow.g = count / 16.0;
      delt = tex2D (S, xy - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += (RainbowGlint) ? delt * bow : delt;
   }

   bow.g = 1.0;

   for (int count = 16; count < 22; count++) {
      bow.r = (21.0 - count) / 6.0;
      delt = tex2D (S, xy - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += (RainbowGlint) ? delt * bow : delt;
   }

   return float4 (ret, 1.0);
}

float4 stretch_2 (sampler S, sampler T, sampler U, float2 xy, float angle)
{
   float3 delt, ret = kTransparentBlack;
   float3 bow = float3 (0.0, 1.0.xx).xyy;

   float2 offset;

   float bluramount = Length * 0.5 / _OutputWidth;
   float MapAngle = angle + radians (Rotation);

   sincos (MapAngle, offset.y, offset.x);

   offset *= bluramount;
   offset.y *= _OutputAspectRatio;

   for (int count = 22; count < 36; count++) {
      bow.b = (36.0 - count) / 15.0;
      delt = tex2D (S, xy - (offset * count)).rgb;
      delt *= 1.0 - (count / 36.0);
      ret += RainbowGlint ? delt * bow : delt;
   }

   ret = (ret + tex2D (T, xy).rgb) / 36.0;

   return max (float4 (ret * Brightness, 1.0), tex2D (U, xy));
}

float4 Poisson (sampler S, float2 xy)
{
   float2 poisson [24] = { {  0.326212,  0.40581 },  {  0.840144,  0.07358 },  {  0.695914, -0.457137 },
                           {  0.203345, -0.620716 }, { -0.96234,   0.194983 }, { -0.473434,  0.480026 },
                           { -0.519456, -0.767022 }, { -0.185461,  0.893124 }, { -0.507431, -0.064425 },
                           { -0.89642,  -0.412458 }, {  0.32194,   0.932615 }, {  0.791559,  0.59771 },
                           { -0.326212, -0.40581 },  { -0.840144, -0.07358 },  { -0.695914,  0.457137 },
                           { -0.203345,  0.620716 }, {  0.96234,  -0.194983 }, {  0.473434, -0.480026 },
                           {  0.519456,  0.767022 }, {  0.185461, -0.893124 }, {  0.507431,  0.064425 },
                           {  0.89642,   0.412458 }, { -0.32194,  -0.932615 }, { -0.791559, -0.59771 } };

   float4 cOut = ReadPixel (S, xy);

   if (!BlurGlint) return cOut;

   float2 coord_1, coord_2, pixelSize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;

   pixelSize *= Length / 3.0;

   for (int tap = 0; tap < 24; tap++) {
      coord_1 = xy + (pixelSize * poisson [tap]);
      coord_2 = xy + (pixelSize * poisson [tap].yx);
      cOut += tex2D (S, coord_1);
      cOut += tex2D (S, coord_2);
   }

   cOut /= 49.0;

   return cOut;
}

float4 main (sampler S, float2 xy1, sampler T, float2 xy2)
{
   float4 blur = ReadPixel (T, xy2);

   if (ShowGlint) return blur;

   float4 source = ReadPixel (S, xy1);
   float4 comb = source + (blur * (1.0.xxxx - source));

   comb = lerp (source, comb, source.a * Strength);

   return lerp (source, comb, tex2D (Mask, xy1).x);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// 4 point glint

DeclarePass (Clip_4)
{ return adjust (Input, uv1); }

DeclarePass (A4_0)
{ return kTransparentBlack; }

DeclarePass (A4_1)
{ return stretch_1 (Clip_4, uv2, SPIN_045); }

DeclarePass (A4_2)
{ return stretch_2 (Clip_4, A4_1, A4_0, uv2, SPIN_045); }

DeclarePass (B4_1)
{ return stretch_1 (Clip_4, uv2, SPIN_135); }

DeclarePass (B4_2)
{ return stretch_2 (Clip_4, B4_1, A4_2, uv2, SPIN_135); }

DeclarePass (C4_1)
{ return stretch_1 (Clip_4, uv2, SPIN_225); }

DeclarePass (C4_2)
{ return stretch_2 (Clip_4, C4_1, B4_2, uv2, SPIN_225); }

DeclarePass (D4_1)
{ return stretch_1 (Clip_4, uv2, SPIN_315); }

DeclarePass (D4_2)
{ return stretch_2 (Clip_4, D4_1, C4_2, uv2, SPIN_315); }

DeclarePass (Star_4)
{ return Poisson (D4_2, uv2); }

DeclareEntryPoint (Glint_4)
{ return main (Input, uv1, Star_4, uv2); }

// 6 point glint

DeclarePass (Clip_6)
{ return adjust (Input, uv1); }

DeclarePass (A6_0)
{ return kTransparentBlack; }

DeclarePass (A6_1)
{ return stretch_1 (Clip_6, uv2, SPIN_030); }

DeclarePass (A6_2)
{ return stretch_2 (Clip_6, A6_1, A6_0, uv2, SPIN_030); }

DeclarePass (B6_1)
{ return stretch_1 (Clip_6, uv2, SPIN_090); }

DeclarePass (B6_2)
{ return stretch_2 (Clip_6, B6_1, A6_2, uv2, SPIN_090); }

DeclarePass (C6_1)
{ return stretch_1 (Clip_6, uv2, SPIN_150); }

DeclarePass (C6_2)
{ return stretch_2 (Clip_6, C6_1, B6_2, uv2, SPIN_150); }

DeclarePass (D6_1)
{ return stretch_1 (Clip_6, uv2, SPIN_210); }

DeclarePass (D6_2)
{ return stretch_2 (Clip_6, D6_1, C6_2, uv2, SPIN_210); }

DeclarePass (E6_1)
{ return stretch_1 (Clip_6, uv2, SPIN_270); }

DeclarePass (E6_2)
{ return stretch_2 (Clip_6, E6_1, D6_2, uv2, SPIN_270); }

DeclarePass (F6_1)
{ return stretch_1 (Clip_6, uv2, SPIN_330); }

DeclarePass (F6_2)
{ return stretch_2 (Clip_6, F6_1, E6_2, uv2, SPIN_330); }

DeclarePass (Star_6)
{ return Poisson (F6_2, uv2); }

DeclareEntryPoint (Glint_6)
{ return main (Input, uv1, Star_6, uv2); }

// 8 point glint

DeclarePass (Clip_8)
{ return adjust (Input, uv1); }

DeclarePass (A8_0)
{ return kTransparentBlack; }

DeclarePass (A8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_000); }

DeclarePass (A8_2)
{ return stretch_2 (Clip_8, A8_1, A8_0, uv2, SPIN_000); }

DeclarePass (B8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_045); }

DeclarePass (B8_2)
{ return stretch_2 (Clip_8, B8_1, A8_2, uv2, SPIN_045); }

DeclarePass (C8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_090); }

DeclarePass (C8_2)
{ return stretch_2 (Clip_8, C8_1, B8_2, uv2, SPIN_090); }

DeclarePass (D8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_135); }

DeclarePass (D8_2)
{ return stretch_2 (Clip_8, D8_1, C8_2, uv2, SPIN_135); }

DeclarePass (E8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_180); }

DeclarePass (E8_2)
{ return stretch_2 (Clip_8, E8_1, D8_2, uv2, SPIN_180); }

DeclarePass (F8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_225); }

DeclarePass (F8_2)
{ return stretch_2 (Clip_8, F8_1, E8_2, uv2, SPIN_225); }

DeclarePass (G8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_270); }

DeclarePass (G8_2)
{ return stretch_2 (Clip_8, G8_1, F8_2, uv2, SPIN_270); }

DeclarePass (H8_1)
{ return stretch_1 (Clip_8, uv2, SPIN_315); }

DeclarePass (H8_2)
{ return stretch_2 (Clip_8, H8_1, G8_2, uv2, SPIN_315); }

DeclarePass (Star_8)
{ return Poisson (H8_2, uv2); }

DeclareEntryPoint (Glint_8)
{ return main (Input, uv1, Star_8, uv2); }

