// @Maintainer jwrl
// @Released 2023-01-06
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
// Updated 2023-01-06 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tilt shift", "Stylize", "Blurs and Sharpens", "Simulates the shallow depth of field normally encountered in close-up photography", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (StartX, "Start", kNoGroup, "SpecifiesPointX", 0.2, 0.0, 1.0);
DeclareFloatParam (StartY, "Start", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam (EndX, "End", kNoGroup, "SpecifiesPointX", 0.2, 0.0, 1.0);
DeclareFloatParam (EndY, "End", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);
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

float4 fn_TiltShift (sampler tS, float2 uv, uniform int mode) : COLOR
{
   float2 start = float2 (_OutputWidth * StartX, (_OutputHeight) * (1.0 - StartY));
   float2 end   = float2 (_OutputWidth * EndX,   (_OutputHeight) * (1.0 - EndY));

   float dx = end.x - start.x;
   float dy = end.y - start.y;
   float d  = sqrt (dx * dx + dy * dy);
   float total = 0.0;

   float2 texSize = float2 (_OutputWidth, _OutputHeight);
   float2 delta = mode == 0 ? float2 (dx, dy) / d : float2 (-dy, dx) / d;

   float4 retval = kTransparentBlack;
   float4 color = kTransparentBlack;

   /* randomize the lookup values to hide the fixed number of samples */

   float2 normal = normalize (float2 (start.y - end.y, end.x - start.x));

   float offset = 1.0;
   float radius = smoothstep (0.0, 1.0, abs (dot (uv * texSize - start, normal)) / gradientRadius) * blurRadius;

   for (int t = -30; t <= 30; t++) {
      float percent = (t + offset - 0.5) / 30.0;
      float weight = 1.0 - abs (percent);

      float4 sample = tex2D (tS, uv + delta / texSize * percent * radius);

      /* switch to pre-multiplied alpha to correctly blur transparent images */

      sample.rgb *= sample.a;

      color += sample * weight;
      total += weight;
   }

   retval = color / total;

   /* switch back from pre-multiplied alpha */

   retval.rgb /= retval.a + 0.00001;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Pass1)
{ return IsOutOfBounds (uv1) ? kTransparentBlack : fn_TiltShift (Inp, uv1, 0); }

DeclareEntryPoint (TiltShift)
{ return IsOutOfBounds (uv1) ? kTransparentBlack : fn_TiltShift (Pass1, uv1, 1); }

