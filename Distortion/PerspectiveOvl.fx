// @Maintainer jwrl
// @Released 2023-07-17
// @Author windsturm
// @Author jwrl
// @OriginalAuthor "Evan Wallace"
// @Created 2023-07-15

/**
 This effect warps a 2D image to a 3D area to give it perspective.  It does this by
 either dragging the corners of the image or by manually adjusting the settings.  If
 necessary the distorted image can also be masked to fit it into a defined area of
 a much larger image.  It's similar to the Perspective effect, but is much simpler
 to set up.

 It also includes the ability to blend the distorted image over the background media.
 It provides a small group of blend modes chosen to help manage highlights and shadows.
 In those modes the mix amount increases to 100% of the blended image at the 50% amount
 setting, then dissolves to a standard overlay at the 100% point.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PerspectiveOvl.fx
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
// This modified version history:
//
// Updated 2023-07-17 jwrl.
// Added blend modes.
//
// Created 2023-07-15 by jwrl from windsturm's original effect.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Perspective overlay", "DVE", "Distortion", "Uses a 3D transform to give a blended perspective to a 2D shape", CanSize);

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

DeclareIntParam (BlendMode, "Blend mode", kNoGroup, 0, "Normal|____________________|Screen|Add|Darken|Multiply");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SCREEN   2
#define DARKEN   4
#define MULTIPLY 5

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These preamble passes means that we handle rotated video correctly.

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (PerspectiveOvl)
{
   if (ShowInp) return tex2D (Fgd, uv3);

   float2 xy1 = float2 (TRx - BLx, BLy - TRy);
   float2 xy2 = float2 (BRx - BLx, BLy - BRy);
   float2 xy3 = float2 (TLx - TRx, TRy - TLy);
   float2 xy0 = xy3 - xy2;

   float den = (xy1.x * xy2.y) - (xy2.x * xy1.y);
   float top = ((xy0.x * xy2.y) - (xy2.x * xy0.y)) / den;
   float bot = ((xy1.x * xy0.y) - (xy0.x * xy1.y)) / den;
   float bt1 = bot + 1.0;

   float3x3 coord3D = float3x3 (
      (top * TRx) - xy3.x, (top * (1.0 - TRy)) - xy3.y, top,
      (BRx * bt1) - TLx, TLy + bot - (BRy * bt1), bot,
      TLx, 1.0 - TLy, 1.0);

   float a = coord3D [0].x, b = coord3D [0].y, c = coord3D [0].z;
   float d = coord3D [1].x, e = coord3D [1].y, f = coord3D [1].z;
   float g = coord3D [2].x, h = coord3D [2].y, i = coord3D [2].z;
   float x = (e * i) - (f * h), y = (f * g) - (d * i), z = (d * h) - (e * g);

   den = (a * x) + (b * y) + (c * z);

   float3x3 v = float3x3 (x, (c * h) - (b * i), (b * f) - (c * e),
                          y, (a * i) - (c * g), (c * d) - (a * f),
                          z, (b * g) - (a * h), (a * e) - (b * d)) / den;
   float3x3 r = float3x3 (v [0].x - v [0].y, -v [0].y, v [0].z - (v [0].y * 2.0),
                          v [1].x - v [1].y, -v [1].y, v [1].z - (v [1].y * 2.0),
                          v [2].x - v [2].y, -v [2].y, v [2].z - (v [2].y * 2.0));

   float3 xyz = mul (float3 (uv3, 1.0), r);

   xy0 = xyz.xy / xyz.z;

   float4 Fgnd = any (xy0 - frac (xy0)) ? kTransparentBlack : tex2D (Fgd, xy0);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   if (BlendMode < SCREEN) { retval = lerp (Bgnd, retval, Amount); }
   else {
      float4 Fmix = float4 (retval.rgb, Fgnd.a);

      if (BlendMode == SCREEN) { Fmix.rgb += Bgnd.rgb * (1.0.xxx - Fmix.rgb); }
      else if (BlendMode == DARKEN) { Fmix.rgb = min (Bgnd.rgb, Fmix.rgb); }
      else if (BlendMode == MULTIPLY) { Fmix.rgb *= Bgnd.rgb; }
      else Fmix.rgb = min (Fmix.rgb + Bgnd.rgb, 1.0.xxx);      // Add blend mode

      float blend = Amount * 2.0;

      Fmix = lerp (Bgnd, Fmix, Fmix.a * saturate (blend));
      retval = lerp (Fmix, retval, saturate (blend - 1.0));
   }

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

