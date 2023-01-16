// @Maintainer jwrl
// @Released 2023-01-16
// @Author khaver
// @Author Eduardo Castineyra
// @Created 2018-06-01
// @see https://www.lwks.com/media/kunena/attachments/6375/PageRoll_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/PageRoll.mp4

/**
 This is the classic page turn transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PageRoll_Dx.fx
//
//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// Eduardo Castineyra (casty) (2015-08-30) https://www.shadertoy.com/view/MtBSzR
//
// Creative Commons Attribution 4.0 International License
//-----------------------------------------------------------------------------------------//
// This effect was adapted for Lightworks by user khaver 1 June 2018 from original code
// by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/MtBSzR
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// Note: code comments are from the original author(s).
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-01-16 jwrl.
// Updated to provide LW 2022 revised cross platform support.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Page Roll", "Mix", "Special Fx transitions", "Page Roll Transition", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (radius, "Page Radius", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareBoolParam (BACK, "Image on backside", kNoGroup, true);

DeclareIntParam (Direction, "Direction", kNoGroup, 0, "Top left to bottom right|Bottom left to top right|Top right to bottom left|Bottom right to top left|Left to right|Right to left|Top to bottom|Bottom to top");

DeclareBoolParam (REVERSE, "Reverse", kNoGroup, false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.141592
#define PX 5.712389  // PI * 1.5 + 1
#define DIST 2

static float3 _cyl = 0.0.xxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

/// 1D function x: _cylFun (t); y: normal at that point.

float2 curlFun (float t, float maxt, float rad)
{
   float2 ret = float2 (t, 1.0);

   if (t < _cyl [DIST] - rad) return ret;       // Before the curl

   if (t > _cyl [DIST] + rad) return -1.0.xx;   // After the curl

   // Inside the curl

   float a = asin ((t - _cyl [DIST]) / rad);
   float ca = -a + PI;

   ret.x = _cyl [DIST] + ca * rad;
   ret.y = cos (ca);

   if (ret.x < maxt) return ret;                // We see the back face

   if (t < _cyl [DIST]) return float2 (t, 1.0); // Front face before the curve starts

   ret.y = cos (a);
   ret.x = _cyl [DIST] + (a * rad);

   return ret.x < maxt ? ret : -1.0.xx;         // Front face curve
}

float2 setXY (float2 uv)
{
   return (Direction == 2) || (Direction == 6) ? float2 (uv.x, 1.0 - uv.y)
        : (Direction == 1) || (Direction == 4) ? float2 (1.0 - uv.x, uv.y)
        : (Direction == 0) ? 1.0.xx - uv : uv;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Vid_1)
{
   float2 uv = setXY (uv3);

   return ReadPixel (Fgd, uv);
}

DeclarePass (Vid_2)
{
   float2 uv = setXY (uv3);

   return ReadPixel (Bgd, uv);
}

DeclareEntryPoint (PageRoll)
{
   float rad = radius;

   if (Direction > 3) rad *= 0.8;

   float start = (rad * 0.5);
   float prog = REVERSE ? 1.0 - Amount : Amount;

   prog = min (1.0, prog + ((1.0 - prog) * start));

   float2 xy1 = setXY (uv3);
   float2 ur = 1.0.xx;
   float2 mouse = (1.0 - prog).xx;

   if (Direction > 3) {
      mouse.y = 0.0;
      if (Direction == 6) mouse = mouse.yx;
   }

   float d = length (mouse * (1.0 + (4.0 * rad))) - (2.0 * rad);

   _cyl = float3 (normalize (mouse), d);
   d = dot (xy1, _cyl.xy);

   float2 end = abs ((ur - xy1) / _cyl.xy);
   float maxt = d + min (end.x, end.y);
   float2 cf = curlFun (d, maxt, rad);
   float2 tuv = xy1 + _cyl.xy * (cf.x - d);

   float shadow = 1.0 - smoothstep (0.0, rad * 2.0, _cyl [DIST] - d);

   shadow *= smoothstep (-rad, rad, (maxt - (cf.x + (PX * rad))));

   float4 curr, next;

   if (REVERSE) {
      curr = tex2D (Vid_2, tuv);
      next = tex2D (Vid_1, xy1);
   }
   else {
      curr = tex2D (Vid_1, tuv);
      next = tex2D (Vid_2, xy1);
   }

   if (BACK) curr = cf.y > 0.0 ? curr * cf.y  * (1.0 - shadow): (curr * 0.25 + 0.75) * (-cf.y);
   else curr = cf.y > 0.0 ? curr * cf.y  * (1.0 - shadow): -cf.y;

   shadow = smoothstep (0.0, rad * 2.0, (d - _cyl [DIST]));

   if (prog == 1.0) return float4 (next.rgb, 1.0);

   next *= shadow;

   float4 fragColor = cf.x > 0.0 ? curr : next;

   return float4 (fragColor.rgb,1.0);
}

