// @Maintainer jwrl
// @Released 2023-05-16
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
DeclareFloatParam (Sparkle, "Sparkle", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (negate, "Negative", kNoGroup, false);

DeclareIntParam (Layers, "Layers", kNoGroup, 5, "1|2|3|4|5|6|7|8");

DeclareFloatParam (CENTERX, "Center", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CENTERY, "Center", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Rotation, "Rotation", kNoGroup, kNoFlags, 180.0, 0.0, 360.0);
DeclareFloatParam (Size, "Zoom", kNoGroup, kNoFlags, 1.0, 0.0, 100.0);
DeclareFloatParam (Zoom, "Size", kNoGroup, kNoFlags, 15.0, 0.0, 50.0);
DeclareFloatParam (Speed, "Linear Speed", kNoGroup, kNoFlags, 0.0, -20.0, 20.0);
DeclareFloatParam (Jumble, "Motion Speed", kNoGroup, kNoFlags, 5.0, 0.0, 100.0);
DeclareFloatParam (Thinness, "String Density", kNoGroup, kNoFlags, 1.0, 0.0, 5.0);
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

float3 baseCol = 1.0.xxx;

#define iTime (_Length * _Progress + 20.0)

#define NUM_LAYERS 4

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float N21 (float2 p)	// Dave Hoskins - https://www.shadertoy.com/view/4djSRW
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
   float fade = smoothstep (Thinness + 0.0001, 0.0, d2);

   fade += smoothstep (0.05, 0.001, abs (d2 - 0.75));

   return smoothstep (r1, r2, d) * fade;
}

float NetLayer (float2 st, float n, float t)
{
   float jumble = Jumble + 0.001;

   float2 id = floor (st) + n;

   st = frac (st) - 0.5;

   float2 p[9];

   int i = 0;

   for (int y = -1; y <= 1; y++) {
      for (int x = -1; x <= 1; x++) {
         p[i++] = GetPos (id, float2 (x, y), t / float (Layers + 1));
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
   m += sparkle * Sparkle;

   return m;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (StringTheory)
{
   float2 xy = (uv0 - 0.5.xx) * Size;
   float2 M = float2 (CENTERX, 1.0 - CENTERY) * 10.0 - 5.0.xx;

   xy.x *= _OutputAspectRatio;

   float t = (iTime * 0.1 * Speed) + 1e-10;
   float jumble = Jumble + 0.001;
   float layers = 1.0 + float (Layers);
   float s, c;

   sincos (radians (Rotation), s, c);

   float2x2 rot = float2x2 (c, -s, s, c);
   float2 st = mul (xy, rot);

   M = mul (M, mul (rot, 2.0));

   float m = 0.0;

   for (int i = 0.0; i < 8.0; i++) {
      if (i > Layers) break;

      float j = float (i) / 8.0;
      float z = frac (t + j);
      float size = lerp (Zoom, 1.0, z);
      float fade = smoothstep (0.0, 0.6, z) * smoothstep (1.0, 0.8, z);

      m += fade * NetLayer (st * size - M * z, j, iTime * jumble);
   }

   float3 col = baseCol * (m + Glow + Glow) * (1.0 - dot (xy, xy));

   col = saturate ((col + col) * Brightness);

   if (negate) col = 1.0.xxx - col;

   return float4 (col, 1.0);
}

