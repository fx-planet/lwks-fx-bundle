// @Maintainer jwrl
// @Released 2023-01-10
// @Author brdloush
// @Created 2013-02-08

/**
 Nice effect that can be used for getting rid of heavy fish-eye distortion when shooting
 with extreme wide angle lenses.  This effect will break resolution independence.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CubicLensDistortion.fx 
//
// Ported & ripped by Brdloush, based on ft-CubicLensDistortion effect by François Tarlier
//
// Following settings worked nicely:
// - Comp Size - X: 100%
// - Comp Size - Y: 100%
// - Scale: 0.88
// - Distortion: -18%
// - Cubic Distortion: 5.75%
//
// Feel free to share/modify or implement all the functions of original
// "ft-CubicLensDistortion".
//
// Pixel Bender shader written by François Tarlier
// http://www.francois-tarlier.com/blog/index.php/2010/03/update-cubic-lens-distortion-pixel-bender-shader-for-ae-with-scale-chroamtic-aberration/
//     
// Original Lens Distortion Algorithm from SSontech (Syntheyes)
// http://www.ssontech.com/content/lensalg.htm
//     r2 = image_aspect*image_aspect*u*u + v*v
//     f = 1 + r2*(k + kcube*sqrt(r2))
//     u' = f*u
//     v' = f*v
//
// Copyright (c) 2010 François Tarlier
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in the
// Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the
// following conditions:
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
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-01-10 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Cubic lens distortion", "Stylize", "Repair tools", "Can be used for reducing fish-eye distortion with wide angle lenses", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (scale, "Scale", kNoGroup, kNoFlags, 1.0,  0.25, 4.0);
DeclareFloatParam (distortion, "Distortion", kNoGroup, kNoFlags, 0.0,  -1.0, 1.0);
DeclareFloatParam (cubicDistortion, "Cubic Distortion", kNoGroup, kNoFlags, 0.0,  -1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (CubicLensDistortion)
{
   float2 uv = (uv1 - 0.5.xx) * 2.0;

   float scaleFactor = 1.0 / scale;
   float r2 = dot (uv, float2 (_OutputAspectRatio * _OutputAspectRatio * uv.x, uv.y));
   float f = cubicDistortion == 0.0 ? 1.0 + (r2 * distortion)
                                    : 1.0 + (r2 * (distortion + cubicDistortion * sqrt (r2)));

   uv = (uv * f * scaleFactor * 0.5) + (0.5).xx;

   return IsOutOfBounds (uv1) ? kTransparentBlack : ReadPixel (Input, uv);
}

