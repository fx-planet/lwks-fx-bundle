// @Maintainer jwrl
// @Released 2023-11-06
// @Author jwrl
// @Author windsturm
// @Author Evan Wallace
// @Created 2023-11-06

/**
 This effect warps a 2D image in 3D space to give it perspective.  To set this up just
 drag the corners of the image or alternatively manually adjust the corner pin settings.
 If necessary the distorted image can also be masked to fit it into a defined area of
 a much larger image.  It's similar to the Perspective effect, but is much simpler to
 set up.

 It also includes the ability to blend the distorted image over the background media.
 It provides a small group of blend modes chosen to help manage highlights and shadows.
 In those modes the mix amount increases to 100% of the blended image at the 50% amount
 setting, then dissolves to a standard overlay at the 100% point.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FastPerspective.fx
//
// Fast perspective is based on Perspective, forked by Windsturm from evanw/glfx.js.
// Original is https://github.com/evanw/glfx.js, copyright (c) 2011 by Evan Wallace.
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
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Created 2023-11-06 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Fast perspective", "DVE", "Simple tools", "Performs a perspective transformation of the foreground image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);

DeclareIntParam (BlendMode, "Blend mode", kNoGroup, 0, "Normal|Screen|Add|Darken|Multiply");

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define NORMAL   0
#define SCREEN   1
#define ADD      2
#define DARKEN   3

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (FastPerspective)
{
   if (ShowInp) return tex2D (Fgd, uv3);

   float2 xy1 = float2 (TRx - BLx, BLy - TRy);
   float2 xy2 = float2 (BRx - BLx, BLy - BRy);
   float2 xy3 = float2 (TLx - TRx, TRy - TLy);
   float2 xy4 = xy3 - xy2;

   float den = (xy1.x * xy2.y) - (xy2.x * xy1.y);
   float top = ((xy4.x * xy2.y) - (xy2.x * xy4.y)) / den;
   float bot = ((xy1.x * xy4.y) - (xy4.x * xy1.y)) / den;
   float bt1 = bot + 1.0;

   float3 a = float3 ((top * TRx) - xy3.x, (top * (1.0 - TRy)) - xy3.y, top);
   float3 b = float3 ((BRx * bt1) - TLx, TLy + bot - (BRy * bt1), bot);
   float3 c = float3 (TLx, 1.0 - TLy, 1.0);

   float x = (b.y * c.z) - (b.z * c.y);
   float y = (b.z * c.x) - (b.x * c.z);
   float z = (b.x * c.y) - (b.y * c.x);

   float3x3 v = float3x3 (x, (a.y * c.z) - (a.z * c.y), (a.y * b.z) - (a.z * b.y),
                          y, (a.z * c.x) - (a.x * c.z), (a.z * b.x) - (a.x * b.z),
                          z, (a.x * c.y) - (a.y * c.x), (a.x * b.y) - (a.y * b.x)) / ((a.x * x) + (a.y * y) + (a.z * z));
   float3x3 r = float3x3 (v [0].x + v [0].y, v [0].y, v [0].z + (v [0].y * 2.0),
                          v [1].x + v [1].y, v [1].y, v [1].z + (v [1].y * 2.0),
                          v [2].x + v [2].y, v [2].y, v [2].z + (v [2].y * 2.0));

   float3 xyz = mul (float3 (uv3, 1.0), r);

   float2 xy = xyz.xy / xyz.z;

   float4 Fgnd = any (xy - frac (xy)) ? kTransparentBlack : tex2D (Fgd, xy);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   float blend = saturate (Opacity);

   if (BlendMode == NORMAL) { retval = lerp (Bgnd, retval, blend); }
   else {
      float4 Fmix = float4 (retval.rgb, Fgnd.a);

      if (BlendMode == SCREEN) { Fmix.rgb += Bgnd.rgb * (1.0.xxx - Fmix.rgb); }
      else if (BlendMode == ADD) { Fmix.rgb = min (Fmix.rgb + Bgnd.rgb, 1.0.xxx); }
      else if (BlendMode == DARKEN) { Fmix.rgb = min (Bgnd.rgb, Fmix.rgb); }
      else Fmix.rgb *= Bgnd.rgb;    // Multiply

      Fmix = lerp (Bgnd, Fmix, Fmix.a * blend);
      retval = lerp (Fmix, retval, saturate (Opacity - 1.0));
   }

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

