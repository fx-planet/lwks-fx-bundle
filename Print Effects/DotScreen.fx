// @Maintainer jwrl
// @Released 2023-01-24
// @Author windsturm
// @Created 2012-06-16
// @OriginalAuthor "Evan Wallace"

/**
 This effect is a version of the dot pattern of a black and white half-tone print image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DotScreen.fx
//
// Original effect "FxDotScreen" (FxDotScreen.fx) by windsturm.
//-----------------------------------------------------------------------------------------//

/*
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
// Updated 2023-01-24 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dot screen", "Stylize", "Print Effects", "This effect is a version of the dot pattern of a black and white half-tone print image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (skipGS, "Greyscale derived from:", kNoGroup, 0, "Luminance|RGB average");

DeclareFloatParam (centerX, "Center Position", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (centerY, "Center Position", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (angle, "Angle", kNoGroup, kNoFlags, 15.0, 0.0, 90.0);
DeclareFloatParam (dotSize, "Size", kNoGroup, kNoFlags, 3.0, 3.0, 1000.0);
DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 4.0, 0.0, 200.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI 3.14159265358979323846264

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (s0)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (DotScreen)
{
   float4 color = tex2D (s0, uv2);
   float4 source = color;

   float2 center = float2 (centerX, 1.0 - centerY);
    
   float luma = (skipGS == 1) ? (color.r + color.g + color.b) / 3.0
                               : dot (color.rgb, float3 (0.299, 0.587, 0.114));
   float s, c;

   sincos (radians (angle), s, c);

   float2 xy1 = (uv2 - center) * float2 (1.0, 1.0 / _OutputAspectRatio) * _OutputWidth;
   float2 xy2 = (xy1 * c - float2 (xy1.y, -xy1.x) * s) * PI / max (3.0, dotSize);

   float pattern = sin (xy2.x) * sin (xy2.y) * Strength;

   color.rgb = ((luma * 10.0) + pattern - 5.0).xxx;

   if (IsOutOfBounds (uv2)) color = kTransparentBlack;

   return lerp (source, color, tex2D (Mask, uv2).x);
}

