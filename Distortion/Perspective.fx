// @Maintainer jwrl
// @Released 2023-01-08
// @Author windsturm
// @OriginalAuthor "Evan Wallace"
// @Created 2017-05-03

/**
 This effect warps one rectanglur area to another with a perspective transform.  It can be
 used to make a 2D image look 3D or to flatten a 2D image captured in a 3D environment.

 With current resolution independence, the image wrap display will only wrap to the edges
 of the undistorted image.  If the aspect ratio of the input video is such that it doesn't
 fill the frame, neither will the wrapped image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Perspective.fx
//-----------------------------------------------------------------------------------------//
/**
  * Perspective.
  * @description  Warps one quadrangle to another with a perspective transform. This can be used to
  *               make a 2D image look 3D or to recover a 2D image captured in a 3D environment.
  * 
  * @forked Windsturm
  * @version 1.0.0

forked from evanw/glfx.js https://github.com/evanw/glfx.js

Copyright (C) 2011 by Evan Wallace

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-01-08 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Perspective", "DVE", "Distortion", "Warps one rectangle to another using a perspective transform", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (viewSsource, "View source", kNoGroup, false);

DeclareBoolParam (modeWrap, "Image Wrap", kNoGroup, false);

DeclareFloatParam (bTLX, "Top Left", "Before", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (bTLY, "Top Left", "Before", "SpecifiesPointY", 0.9, 0.0, 1.0);

DeclareFloatParam (bTRX, "Top Right", "Before", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (bTRY, "Top Right", "Before", "SpecifiesPointY", 0.9, 0.0, 1.0);

DeclareFloatParam (bBLX, "Bottom Left", "Before", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (bBLY, "Bottom Left", "Before", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (bBRX, "Bottom Right", "Before", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (bBRY, "Bottom Right", "Before", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (aTLX, "Top Left", "After", "SpecifiesPointX", 0.2, 0.0, 1.0);
DeclareFloatParam (aTLY, "Top Left", "After", "SpecifiesPointY", 0.8, 0.0, 1.0);

DeclareFloatParam (aTRX, "Top Right", "After", "SpecifiesPointX", 0.8, 0.0, 1.0);
DeclareFloatParam (aTRY, "Top Right", "After", "SpecifiesPointY", 0.8, 0.0, 1.0);

DeclareFloatParam (aBLX, "Bottom Left", "After", "SpecifiesPointX", 0.2, 0.0, 1.0);
DeclareFloatParam (aBLY, "Bottom Left", "After", "SpecifiesPointY", 0.2, 0.0, 1.0);

DeclareFloatParam (aBRX, "Bottom Right", "After", "SpecifiesPointX", 0.8, 0.0, 1.0);
DeclareFloatParam (aBRY, "Bottom Right", "After", "SpecifiesPointY", 0.2, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3x3 getSquareToQuad (float x0, float y0, float x1, float y1,
                          float x2, float y2, float x3, float y3)
{
   float dx1 = x1 - x2;
   float dy1 = y1 - y2;
   float dx2 = x3 - x2;
   float dy2 = y3 - y2;
   float dx3 = x0 - x1 + x2 - x3;
   float dy3 = y0 - y1 + y2 - y3;
   float det = dx1*dy2 - dx2*dy1;
   float a = (dx3*dy2 - dx2*dy3) / det;
   float b = (dx1*dy3 - dx3*dy1) / det;

   return float3x3(
      x1 - x0 + a*x1, y1 - y0 + a*y1, a,
      x3 - x0 + b*x3, y3 - y0 + b*y3, b,
      x0, y0, 1
   );
}

float3x3 getInverse (float3x3 m)
{
   float a = m[0].x, b = m[0].y, c = m[0].z;
   float d = m[1].x, e = m[1].y, f = m[1].z;
   float g = m[2].x, h = m[2].y, i = m[2].z;
   float det = a*e*i - a*f*h - b*d*i + b*f*g + c*d*h - c*e*g;

   return float3x3(
      (e*i - f*h) / det, (c*h - b*i) / det, (b*f - c*e) / det,
      (f*g - d*i) / det, (a*i - c*g) / det, (c*d - a*f) / det,
      (d*h - e*g) / det, (b*g - a*h) / det, (a*e - b*d) / det
   );
}

float3x3 multiply (float3x3 a, float3x3 b)
{
   return float3x3(
      a[0].x*b[0].x + a[0].y*b[1].x + a[0].z*b[2].x,
      a[0].x*b[0].y + a[0].y*b[1].y + a[0].z*b[2].y,
      a[0].x*b[0].z + a[0].y*b[1].z + a[0].z*b[2].z,
      a[1].x*b[0].x + a[1].y*b[1].x + a[1].z*b[2].x,
      a[1].x*b[0].y + a[1].y*b[1].y + a[1].z*b[2].y,
      a[1].x*b[0].z + a[1].y*b[1].z + a[1].z*b[2].z,
      a[2].x*b[0].x + a[2].y*b[1].x + a[2].z*b[2].x,
      a[2].x*b[0].y + a[2].y*b[1].y + a[2].z*b[2].y,
      a[2].x*b[0].z + a[2].y*b[1].z + a[2].z*b[2].z
   );
}

float2 matrixWarp (float3x3 m, float2 coord)
{
   float3 warp = mul (float3 (coord, 1.0), m);

   return warp.xy / warp.z;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (PerspectiveFx)
{
   if (viewSsource) return ReadPixel (Inp, uv2);

   float3x3 a = getSquareToQuad (aTLX, 1-aTLY, aTRX, 1-aTRY, aBLX, 1-aBLY, aBRX, 1-aBRY);    // after
   float3x3 b = getSquareToQuad (bTLX, 1-bTLY, bTRX, 1-bTRY, bBLX, 1-bBLY, bBRX, 1-bBRY);    // before
   float3x3 c = multiply (getInverse (a), b);

   float2 xy = matrixWarp (c, uv2);
   float2 coord = frac (xy);

   // return Wrap or Border mode - Border mode simulated by blanking coord overflow

   return modeWrap ? tex2D (Inp, coord) : any (xy - coord) ? kTransparentBlack : tex2D (Inp, xy);
}

