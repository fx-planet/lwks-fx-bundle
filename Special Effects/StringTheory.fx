// @Maintainer jwrl
// @Released 2023-08-29
// @Author khaver
// @Created 2018-08-01
// @OriginalAuthor Martijn Steinrucken 2018

/**
 This effect is impossible to describe.  Try it to see what it does.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect StringTheory.fx
//
//-----------------------------------------------------------------------------------------//
// The Universe Within - by Martijn Steinrucken aka BigWings 2018
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// stringTheory.fx for Lightworks was adapted by user khaver 1 Aug 2018 for use with Lightworks
// version 14.5 and higher from original code by the above licensee taken from the Shadertoy
// website (https://www.shadertoy.com/view/lscczl).
//
// This adaptation retains the same Creative Commons license shown above.
// It cannot be used for commercial purposes.
//
// Version history:
//
// Updated 2023-08-29 jwrl.
// Optimised the code to resolve a Linux/Mac compatibility issue.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("String Theory", "Matte", "Special Effects", "You really have to try this to see what it does", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

// No inputs necessary.

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Brightness, "Brightness", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Glow, "Glow", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (fSparkle, "Sparkle", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (Negative, "Negative", kNoGroup, false);

DeclareIntParam (LayerInt, "Layers", kNoGroup, 5, "1|2|3|4|5|6|7|8");

DeclareFloatParam (Center_X, "Center", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Center_Y, "Center", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Rotation, "Rotation", kNoGroup, kNoFlags, 180.0, 0.0, 360.0);
DeclareFloatParam (Zoom, "Zoom", kNoGroup, kNoFlags, 1.0, 0.0, 100.0);
DeclareFloatParam (sSize, "Size", kNoGroup, kNoFlags, 15.0, 0.0, 50.0);
DeclareFloatParam (lSpeed, "Linear Speed", kNoGroup, kNoFlags, 0.0, -20.0, 20.0);
DeclareFloatParam (mSpeed, "Motion Speed", kNoGroup, kNoFlags, 5.0, 0.0, 100.0);
DeclareFloatParam (Density, "String Density", kNoGroup, kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (Irregularity, "Irregularity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define NUM_LAYERS 4

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// Dave Hoskins - https://www.shadertoy.com/view/4djSRW

float N21 (float2 p)
{
   float3 p3 = frac (p.xyx * float3 (443.897, 441.423, 437.195));

   p3 += dot (p3, p3.yzx + 19.19.xxx);

   return frac ((p3.x + p3.y) * p3.z);
}

float2 GetPos (float2 id, float2 offs, float t)
{
   float n = N21 (id + offs);
   float n1 = frac (n * 10.0);
   float n2 = frac (n * 100.0);
   float a = t + n;

   return offs + float2 (sin (a * n1), cos (a * n2)) * (Irregularity * 0.45);
}

float df_line (float2 a, float2 b, float2 p)
{
   float2 pa = p - a;
   float2 ba = b - a;

   float h = saturate (dot (pa, ba) / dot (ba, ba));

   return length (pa - ba * h);
}

float lines (float2 a, float2 b, float2 uv)
{
   float r1 = 0.03;
   float r2 = 0.001;

   float d = df_line (a, b, uv);
   float d2 = length (a - b);
   float fade = smoothstep (Density + 0.0001, 0.0, d2);

   fade += smoothstep (0.05, 0.001, abs (d2 - 0.75));

   return smoothstep (r1, r2, d) * fade;
}

float NetLayer (float2 st, float n, float t)
{
   float jumble = mSpeed + 0.001;

   float2 id = floor (st) + n;

   st = frac (st) - 0.5;

   float2 p[9];

   int i = 0;

   for (int y = -1; y <= 1; y++) {
      for (int x = -1; x <= 1; x++) {
         p[i++] = GetPos (id, float2 (x, y), t / float (LayerInt + 1));
      }
   }

   float m = 0.0;
   float sparkle = 0.0;

   for (int i = 0; i < 9; i++) {
      m += lines (p [4], p [i], st);

      float d = length (st - p [i]);
      float s = (0.005 / (d * d));

      s *= smoothstep (1.0, 0.7, d);

      float pulse = sin ((frac (p[i].x) + frac (p[i].y) + (t / jumble)) * 5.0) * 0.4 + 0.6;

      pulse = pow (pulse, 20.0);
      s *= pulse;
      sparkle += s;
   }

   m += lines (p[1], p[3], st);
   m += lines (p[1], p[5], st);
   m += lines (p[7], p[5], st);
   m += lines (p[7], p[3], st);
   m += sparkle * fSparkle;

   return m;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (StringTheory)
{
   float2 xy = (uv0 - 0.5.xx) * Zoom;
   float2 mm = (float2 (Center_X, 1.0 - Center_Y) * 10.0) - 5.0.xx;

   xy.x *= _OutputAspectRatio;

   float iTime = ((_Length * _Progress) + 20.0)
   float t = max (iTime * 0.1 * lSpeed, 1e-10);
   float jumble = max (mSpeed, 0.001);
   float layers = 1.0 + float (LayerInt);
   float s, c;

   sincos (radians (Rotation), s, c);

   float2x2 rot = float2x2 (c, -s, s, c);
   float2 st = mul (xy, rot);

   mm *= mul (rot, 2.0.xx);

   float m = 0.0;

   for (int i = 0; i < 8; i++) {
      if (i > LayerInt) break;

      float j = float (i) / 8.0;
      float z = frac (t + j);
      float size = lerp (sSize, 1.0, z);
      float fade = smoothstep (0.0, 0.6, z) * smoothstep (1.0, 0.8, z);

      m += fade * NetLayer ((st * size) - (mm * z), j, iTime * jumble);
   }

   float3 col = (m + Glow + Glow) * (1.0 - dot (xy, xy));

   col = saturate ((col + col) * Brightness);

   if (Negative) col = 1.0.xxx - col;

   return float4 (col, 1.0);
}

