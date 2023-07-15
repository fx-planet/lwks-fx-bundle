// @Maintainer jwrl
// @Released 2023-07-15
// @Author windsturm
// @Author jwrl
// @OriginalAuthor "Evan Wallace"
// @Created 2023-07-15

/**
 This effect warps a 2D image to a 3D area to give it perspective.  It does this by
 either dragging the corners of the image or by manually adjusting the settings.  If
 necessary the distorted image can also be masked to fit it into a defined area of
 a much larger image.

 With current resolution independence, the image wrap display will only wrap to the edges
 of the undistorted image.  If the aspect ratio of the input video is such that it doesn't
 fill the frame, neither will the wrapped image.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PerspectiveOvl.fx
//-----------------------------------------------------------------------------------------//
//
// Based on Perspective copyright (C) 2011 by Evan Wallace
// Forked by windsturm 2012-08-14.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Created 2023-07-15 by jwrl from windsturm's original effect.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Perspective overlay", "DVE", "Distortion", "Uses a 3D transform to give perspective to a 2D shape", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (TLx, "Top left", "Corner pins", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (TLy, "Top left", "Corner pins", "SpecifiesPointY", 0.9, 0.0, 1.0);

DeclareFloatParam (TRx, "Top right", "Corner pins", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (TRy, "Top right", "Corner pins", "SpecifiesPointY", 0.9, 0.0, 1.0);

DeclareFloatParam (BLx, "Bottom left", "Corner pins", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (BLy, "Bottom left", "Corner pins", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (BRx, "Bottom right", "Corner pins", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (BRy, "Bottom right", "Corner pins", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareBoolParam (ShowInp, "View source", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 map3D (float3x3 m, float2 xy)
{
   float a = m [0].x, b = m [0].y, c = m [0].z;
   float d = m [1].x, e = m [1].y, f = m [1].z;
   float g = m [2].x, h = m [2].y, i = m [2].z;

   float x = (e * i) - (f * h), y = (f * g) - (d * i), z = (d * h) - (e * g);
   float det = (a * x) + (b * y) + (c * z);

   float3x3 v = float3x3 (x, (c * h) - (b * i), (b * f) - (c * e),
                          y, (a * i) - (c * g), (c * d) - (a * f),
                          z, (b * g) - (a * h), (a * e) - (b * d)) / det;
   float3x3 r = float3x3 (v [0].x - v [0].y, -v [0].y, v [0].z - (v [0].y * 2.0),
                          v [1].x - v [1].y, -v [1].y, v [1].z - (v [1].y * 2.0),
                          v [2].x - v [2].y, -v [2].y, v [2].z - (v [2].y * 2.0));

   float3 xyz = mul (float3 (xy, 1.0), r);

   return xyz.xy / xyz.z;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These preamble passes means that we handle rotated video correctly.

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Perspective3D)
{
   if (ShowInp) return tex2D (Fgd, uv3);

   float2 xy1 = float2 (TRx - BLx, BLy - TRy);
   float2 xy2 = float2 (BRx - BLx, BLy - BRy);
   float2 xy3 = float2 (TLx - TRx, TRy - TLy);
   float2 xy4 = xy3 - xy2;

   float det = (xy1.x * xy2.y) - (xy2.x * xy1.y);
   float top = ((xy4.x * xy2.y) - (xy2.x * xy4.y)) / det;
   float bot = ((xy1.x * xy4.y) - (xy4.x * xy1.y)) / det;

   det = bot + 1.0;

   float3x3 coord3D = float3x3 (
      (top * TRx) - xy3.x, (top * (1.0 - TRy)) - xy3.y, top,
      (BRx * det) - TLx, TLy + bot - (BRy * det), bot,
      TLx, 1.0 - TLy, 1.0);

   float2 xy = map3D (coord3D, uv3);

   float4 Fgnd = any (xy - frac (xy)) ? kTransparentBlack : tex2D (Fgd, xy);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval = lerp (kTransparentBlack, Fgnd, tex2D (Mask, uv3).x);

   return lerp (Bgnd, retval, retval.a * Amount);
}

