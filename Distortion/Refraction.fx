// @Maintainer jwrl
// @Released 2023-01-24
// @Author windsturm
// @OriginalAuthor "Ian McEwan"
// @Created 2012-10-25

/**
 Simulates the distortion effect of an image seen through textured glass.  The rippling
 is derived for a random noise generator.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Refraction.fx
//
//-----------------------------------------------------------------------------------------//
// Description : Array and textureless GLSL 3D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110409 (stegu)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//
// https://github.com/ashima/webgl-noise
//-----------------------------------------------------------------------------------------//

 /**
  * FxRefraction.
  * Refraction effect.
  * 
  * @param <noisePhase>  noise animation parameter
  * @param <noiseSize> noise size
  * @param <strength> refraction rate
  * @param <noiseX> Noise X coordinate
  * @param <noiseY> noise Y coordinate
  * @param <AR> aspect ratio 1:x
  * @param <exportImage> switch the export image
  * @param <useExternalImage> external noise image
  * @forked Windsturm
  * @version 1.0.0
  */

//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-01-24 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Refraction", "Stylize", "Distortion", "Simulates the distortion effect of an image seen through textured glass", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Inp, Msk);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (noisePhase, "Phase", "Noise Parameter", kNoFlags, 0.0, 0.0, 100.0);
DeclareFloatParam (noiseSize, "Size", "Noise Parameter", kNoFlags, 10.0, 0.0, 200.0);
DeclareFloatParam (strength, "Strength", "Noise Parameter", kNoFlags, 0.1, 0.0, 2.0);

DeclareFloatParam (noiseX, "Position X", "Noise Parameter", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (noiseY, "Position Y", "Noise Parameter", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (AR, "AspectRatio 1:x", "Noise Parameter", kNoFlags, 0.1, 0.01, 10.0);

DeclareIntParam (exportImage, "Export Image", kNoGroup, 0, "Result|Source|Noise");

DeclareBoolParam (useExternalImage, "Use External Image", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_OutputWidth);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 MirrorEdge (sampler S, float2 uv)
{
   float2 xy = 1.0.xx - abs (2.0 * (frac (uv / 2.0) - 0.5.xx));

   return tex2D (S, xy);
}

float4 permute (float4 x)
{
   return fmod ((((x * 34.0) + 1.0.xxxx) * x), 289.0);
}

float snoise (float3 v)
{
   const float2 C = float2 (1.0, 2.0) / 6.0;
   const float4 D = float4 (0.0, 0.5, 1.0, 2.0);

   // First corner

   float3 i  = floor (v + dot (v, C.yyy).xxx);
   float3 x0 = v - i + dot (i, C.xxx).xxx;

   // Other corners

   float3 g  = step (x0.yzx, x0.xyz);
   float3 l  = 1.0.xxx - g;
   float3 i1 = min (g.xyz, l.zxy);
   float3 i2 = max (g.xyz, l.zxy);

   float3 x1 = x0 - i1  + C.xxx;
   float3 x2 = x0 - i2  + 2.0 * C.xxx;
   float3 x3 = x0 - 1.0.xxx + 3.0 * C.xxx;

   // Permutations

   i = fmod (i, 289.0);

   float4 p = permute (permute (permute (i.z + float4 (0.0, i1.z, i2.z, 1.0))
                                       + i.y + float4 (0.0, i1.y, i2.y, 1.0))
                                       + i.x + float4 (0.0, i1.x, i2.x, 1.0));

   // Gradients
   // (N*N points uniformly over a square, mapped onto an octahedron.)

   float  n_ = 1.0 / 7.0;                                // N = 7
   float3 ns = n_ * D.wyz - D.xzx;

   float4 j  = p - 49.0 * floor (p * ns.z *ns.z);        //  mod (p, N * N)

   float4 x_ = floor (j * ns.z);
   float4 y_ = floor (j - 7.0 * x_);                     // mod (j, N)

   float4 x  = x_ * ns.x + ns.yyyy;
   float4 y  = y_ * ns.x + ns.yyyy;
   float4 h  = 1.0.xxxx - abs (x) - abs (y);

   float4 b0 = float4 (x.xy, y.xy);
   float4 b1 = float4 (x.zw, y.zw);

   float4 s0 = floor (b0) * 2.0 + 1.0.xxxx;
   float4 s1 = floor (b1) * 2.0 + 1.0.xxxx;
   float4 sh = -step (h, float4 ( 0.0, 0.0, 0.0, 0.0 ));

   float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
   float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

   float3 p0 = float3 (a0.xy, h.x);
   float3 p1 = float3 (a0.zw, h.y);
   float3 p2 = float3 (a1.xy, h.z);
   float3 p3 = float3 (a1.zw, h.w);

   // Normalise gradients

   float4 norm = float4 (1.79284291400159 - 0.85373472095314 * float4 (dot (p0, p0), dot (p1, p1), dot (p2, p2), dot (p3, p3)));

   p0 *= norm.x;
   p1 *= norm.y;
   p2 *= norm.z;
   p3 *= norm.w;

   // Mix final noise value

   float4 m = max (0.6 - float4 (dot (x0, x0), dot (x1, x1), dot (x2, x2), dot (x3, x3)), 0.0);

   m = m * m;

   return 42.0 * dot (m * m, float4 (dot (p0, x0), dot (p1, x1), dot (p2, x2), dot (p3, x3)));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These preamble passes mean that we handle rotated video correctly.

DeclarePass (Input)
{ return ReadPixel (Inp, uv1); }

DeclarePass (s_Mask)
{ return ReadPixel (Msk, uv2); }

DeclarePass (Noise)
{
   if (noiseSize <= 0.0) return float2 (0.0, 1.0).xxxy;

   float2 outputAspect = float2 (1.0, _OutputAspectRatio);
   float2 blueAspect   = float2 (1.0, 1.0 * AR);

   uv0 -= float2 (noiseX, 1.0 - noiseY);
   uv0 = uv0 / outputAspect / blueAspect;

   float3 coord = float3 ((uv0 * noiseSize), noisePhase * 0.1);

   float n = 0.7  * abs (snoise (coord));

   n += 0.25 * abs (snoise (coord * 2.0));

   return float4 (n.xxx, 1.0);
}

DeclarePass (Refract)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   if (exportImage == 1) return MirrorEdge (Input, uv3);

   if (exportImage == 2) {

      if (useExternalImage) return MirrorEdge (s_Mask,uv3);

      return MirrorEdge (Noise,uv3);
   }

   float4 Color;

   // Create NormalMap

   float2 shiftXY[4];

   shiftXY[0] = float2 (-1.0 / _OutputWidth, 0.0);
   shiftXY[1] = float2 (1.0 / _OutputWidth, 0.0);
   shiftXY[2] = float2 (0.0, -_OutputAspectRatio / _OutputWidth);
   shiftXY[3] = float2 (0.0, _OutputAspectRatio / _OutputWidth);

   float3 shiftColor[4];

   if (useExternalImage) {
      shiftColor[0] = 2.0 * MirrorEdge (s_Mask, uv3 + shiftXY[0]) - 1.0;
      shiftColor[1] = 2.0 * MirrorEdge (s_Mask, uv3 + shiftXY[1]) - 1.0;
      shiftColor[2] = 2.0 * MirrorEdge (s_Mask, uv3 + shiftXY[2]) - 1.0;
      shiftColor[3] = 2.0 * MirrorEdge (s_Mask, uv3 + shiftXY[3]) - 1.0;
   }
   else {
      shiftColor[0] = 2.0 * MirrorEdge (Noise, uv3 + shiftXY[0]) - 1.0;
      shiftColor[1] = 2.0 * MirrorEdge (Noise, uv3 + shiftXY[1]) - 1.0;
      shiftColor[2] = 2.0 * MirrorEdge (Noise, uv3 + shiftXY[2]) - 1.0;
      shiftColor[3] = 2.0 * MirrorEdge (Noise, uv3 + shiftXY[3]) - 1.0;
   }

   float3 u = float3 (1.0, 0.0, 0.5 * (shiftColor[1].x - shiftColor[0].x));
   float3 v = float3 (0.0, 1.0, 0.5 * (shiftColor[3].x - shiftColor[2].x));

   float4 nColor = float4 (0.5 * normalize (cross (u, v)) + 0.5, 1.0);

   float2 xy = uv3 + (cos (radians (nColor.r * 180.00)) * strength).xx;

   return MirrorEdge (Input, xy);
}

DeclareEntryPoint (Refraction)
{ return (tex2D (Input, uv3), tex2D (Refract, uv3), tex2D (Mask, uv3).x); }

