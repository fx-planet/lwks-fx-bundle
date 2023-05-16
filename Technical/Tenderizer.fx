// @Maintainer jwrl
// @Released 2023-05-16
// @Author khaver
// @Created 2016-06-03

/**
 This effect converts 8 bit video to 10 bit video by adding intermediate colors and luminance
 values using spline interpolation.  Set project to 10 bit or better and set source width and
 height for best results.  The alpha channel is unaltered, but there may be a slight image
 softening.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Tenderizer.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tenderizer", "User", "Technical", "Converts 8 bit video to 10 bit video by adding intermediate levels using spline interpolation", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (V);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (ReX, "Source Horizontal Resolution", kNoGroup, 0, "Project|720|1280|1440|1920|2048|3840|4096");
DeclareIntParam (ReY, "Source Vertical Resolution", kNoGroup, 0, "Project|480|576|720|1080|2160");

DeclareBoolParam (Luma, "Tenderize Luma", kNoGroup, true);
DeclareBoolParam (Chroma, "Tenderize Chroma", kNoGroup, true);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float _idxX[8] = { 0.0, 720.0, 1280.0, 1440.0, 1920.0, 2048.0, 3840.0, 4096.0 };
float _idxY[6] = { 0.0, 480.0, 576.0, 720.0, 1080.0, 2160.0 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 Hermite (float t, float4 A, float4 B, float4 C, float4 D)
{
   float t2 = t * t;

   float4 retval = ((((3.0 * (B - C)) - A + D) * t2) + (C - A)) * t;

   retval += ((2.0 * A) - (5.0 * B) + (4.0 * C) - D) * t2;

   return (retval / 2.0) + B;
}

float4 colorsep (sampler samp, float2 xy, float2 pix)
{
   float4 color = tex2D (samp, xy + pix);

   float Cmin = min (color.r, min (color.g, color.b));

   color.rgb -= Cmin.xxx;
   color.a  = Cmin;

   return color;
}

float closest (float test, float orig, float bit)
{
   float t = abs (test - orig);

   return (t < (bit * 0.3333)) ? orig : (t < (bit * 0.6667)) ? test : (test + orig) / 2.0;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (VSampler)
{ return ReadPixel (V, uv1); }

DeclareEntryPoint (Tenderizer)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float2 pixel;

   pixel.x = (ReX == 0) ? _OutputWidth : _idxX [ReX];
   pixel.y = (ReY == 0) ? _OutputHeight : _idxY [ReY];

   pixel = 1.0 / max (1.0e-6, pixel);

   float4 seporg = colorsep (VSampler, uv2, 0.0.xx);
   float4 samp2, samp3, samp4, samp5, samp6, samp7, samp8;

   float4 samp00 = colorsep (VSampler, uv2, float2 (pixel.x * -2.0, 0.0));
   float4 samp01 = colorsep (VSampler, uv2, float2 (-pixel.x, 0.0));
   float4 samp02 = colorsep (VSampler, uv2, float2 (pixel.x, 0.0));
   float4 samp03 = colorsep (VSampler, uv2, float2 (pixel.x * 2.0, 0.0));
   float4 samp1  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, uv2, float2 ((pixel.x * -2.0), -pixel.y));
   samp01 = (colorsep (VSampler, uv2, float2 (-pixel.x, 0)) + colorsep (VSampler, uv2, float2 (-pixel.x, -pixel.y))) / 2.0;
   samp02 = (colorsep (VSampler, uv2, float2 (pixel.x, 0)) + colorsep (VSampler, uv2, float2 (pixel.x, pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, uv2, float2 (pixel.x * 2.0, pixel.y));
   samp2  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, uv2, float2 (pixel.x * -2.0, pixel.y * -2.0));
   samp01 = colorsep (VSampler, uv2, float2 (-pixel.x, -pixel.y));
   samp02 = colorsep (VSampler, uv2, float2 (pixel.x, pixel.y));
   samp03 = colorsep (VSampler, uv2, float2 (pixel.x * 2.0, pixel.y * 2.0));
   samp3  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, uv2, float2 (-pixel.x, pixel.y * -2.0));
   samp01 = (colorsep (VSampler, uv2, float2 (-pixel.x, -pixel.y)) + colorsep (VSampler, uv2, float2(0, -pixel.y))) / 2.0;
   samp02 = (colorsep(VSampler, uv2, float2 (0.0, pixel.y)) + colorsep (VSampler, uv2, float2 (pixel.x, pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, uv2, float2 (pixel.x, pixel.y * 2.0));
   samp4  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, uv2, float2 (0.0, pixel.y * -2.0));
   samp01 = colorsep (VSampler, uv2, float2 (0.0, -pixel.y));
   samp02 = colorsep (VSampler, uv2, float2 (0.0, pixel.y));
   samp03 = colorsep (VSampler, uv2, float2 (0.0, pixel.y * 2.0));
   samp5  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, uv2, float2 (pixel.x, pixel.y * -2.0));
   samp01 = (colorsep (VSampler, uv2, float2 (pixel.x, -pixel.y)) + colorsep (VSampler, uv2, float2 (0.0, -pixel.y))) / 2.0;
   samp02 = (colorsep (VSampler, uv2, float2 (0.0, pixel.y)) + colorsep (VSampler, uv2, float2 (-pixel.x, pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, uv2, float2 (-pixel.x, pixel.y * 2.0));
   samp6  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, uv2, float2 (pixel.x * 2.0, pixel.y * -2.0));
   samp01 = colorsep (VSampler, uv2, float2 (pixel.x, -pixel.y));
   samp02 = colorsep (VSampler, uv2, float2 (-pixel.x, pixel.y));
   samp03 = colorsep (VSampler, uv2, float2 (pixel.x * -2.0, pixel.y * 2.0));
   samp7  = Hermite (0.5, samp00, samp01, samp02, samp03);

   samp00 = colorsep (VSampler, uv2, float2 (pixel.x * -2.0, pixel.y));
   samp01 = (colorsep (VSampler, uv2, float2 (-pixel.x, 0.0)) + colorsep (VSampler, uv2, float2 (-pixel.x, pixel.y))) / 2.0;
   samp02 = (colorsep (VSampler, uv2, float2 (pixel.x, 0.0)) + colorsep (VSampler, uv2, float2 (pixel.x, -pixel.y))) / 2.0;
   samp03 = colorsep (VSampler, uv2, float2 (pixel.x * 2.0, -pixel.y));
   samp8  = Hermite (0.5, samp00, samp01, samp02, samp03);

   float cbit = 1.0 / 256.0;
   float R, G, B, L;

   if (Chroma) {
      R = (samp1.r + samp2.r + samp3.r + samp4.r + samp5.r + samp6.r + samp7.r + samp8.r) / 8.0;
      G = (samp1.g + samp2.g + samp3.g + samp4.g + samp5.g + samp6.g + samp7.g + samp8.g) / 8.0;
      B = (samp1.b + samp2.b + samp3.b + samp4.b + samp5.b + samp6.b + samp7.b + samp8.b) / 8.0;
      R = closest (R, seporg.r, cbit);
      G = closest (G, seporg.g, cbit);
      B = closest (B, seporg.b, cbit);
   }
   else {
      R = seporg.r;
      G = seporg.g;
      B = seporg.b;
   }
      
   if (Luma) {
      L = (samp1.a + samp2.a + samp3.a + samp4.a + samp5.a + samp6.a + samp7.a + samp8.a) / 8.0;
      L = closest (L, seporg.a, cbit);
   }
   else L = seporg.a;

   return float4 (R + L, G + L, B + L, tex2D (VSampler, uv2).a);
}

