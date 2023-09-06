// @Maintainer jwrl
// @Released 2023-09-06
// @Author Evan Wallace (evanw/glfx.js https://github.com/evanw/glfx.js)
// @Created 2012-07-30

/**
 ORIGINAL AUTHOR'S DESCRIPTION
 Simulates the shallow depth of field normally encountered in close-up photography,
 which makes the scene seem much smaller than it actually is. This filter assumes the
 scene is relatively planar, in which case the part of the scene that is completely
 in focus can be described by a line (the intersection of the focal plane and the
 scene). An example of a planar scene might be looking at a road from above at a
 downward angle. The image is then blurred with a blur radius that starts at zero
 on the line and increases further from the line.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiltShift.fx
//
// Ported by windsturm
//
// ORIGINAL AUTHOR'S PERMISSION:
// Copyright (C) 2011 by Evan Wallace
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Version history:
//
// Updated 2023-09-06 jwrl.
// Optimised the code to resolve a Linux/Mac compatibility issue.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tilt shift", "Stylize", "Blurs and sharpens", "Simulates the shallow depth of field normally encountered in close-up photography", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (startX, "start", kNoGroup, "SpecifiesPointX", 0.2, 0.0, 1.0);
DeclareFloatParam (startY, "start", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam (endX, "end", kNoGroup, "SpecifiesPointX", 0.8, 0.0, 1.0);
DeclareFloatParam (endY, "end", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam (blurRadius, "Blur Radius", kNoGroup, kNoFlags, 15.0, 0.0, 50.0);
DeclareFloatParam (gradientRadius, "Gradient Radius", kNoGroup, kNoFlags, 200.0, 0.0, 500.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function will mirror once on all edges, which is all that we need for a blur.
// It's range limited so that anything that exceeds legality in the wanted pixel's
// original address will cause a null value to be returned.

float4 tex2D_mirror (sampler s, float2 xy, float2 limit)
{
   float2 lim = abs (limit - 0.5.xx);

   if ((lim.x > 0.5) || (lim.y > 0.5)) return 0.0.xxxx;

   return tex2D (s, saturate (1.0.xx - abs (1.0.xx - abs (xy))));
}

float preamble (out float2 Isize, out float2 start, out float2 end, out float2 delta)
{
   Isize = float2 (_OutputWidth, _OutputHeight);
   start = Isize * float2 (startX, 1.0 - startY);
   end   = Isize * float2 (endX,   1.0 - endY);
   delta = end - start;

   return length (delta);
}

float4 tiltShift (sampler tS, float2 start, float2 end, float2 delta, float2 scale, float2 xy)
{
   // Randomize the lookup values to hide the fixed number of samples

   float2 normal = normalize (float2 (start.y - end.y, end.x - start.x));
/*
   float radius = smoothstep (0.0, 1.0, abs (dot (xy * scale - start, normal)) / gradientRadius) * blurRadius;
*/
   float radius = saturate (abs (dot (xy * scale - start, normal)) / gradientRadius) * blurRadius;
   float total  = 0.0;
   float offset = 1.0;

   float4 retval = 0.0.xxxx;

   for (float t = -30.0; t <= 30.0; t++) {
      float percent = (t + offset - 0.5) / 30.0;
      float weight = 1.0 - abs (percent);

      float4 sample = tex2D_mirror (tS, xy + ((delta / scale) * percent * radius), xy);

      // Switch to pre-multiplied alpha to correctly blur transparent images

      sample.rgb *= sample.a;

      retval += sample * weight;
      total += weight;
   }

   retval /= total;

   // Switch back from pre-multiplied alpha

   retval.rgb /= max (retval.a, 0.00001);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Pass1)
{
   float2 texSize, start, end, dxy;

   float d = preamble (texSize, start, end, dxy);

   return tiltShift (Inp, start, end, dxy / d, texSize, uv1);
}

DeclareEntryPoint (TiltShift)
{
   float2 texSize, start, end, dxy;

   float d = preamble (texSize, start, end, dxy);

   float4 video  = ReadPixel (Inp, uv1);
   float4 retval = tiltShift (Pass1, start, end, float2 (-dxy.y, dxy.x) / d, texSize, uv2);

   return lerp (video, retval, tex2D (Mask, uv1).x);
}

