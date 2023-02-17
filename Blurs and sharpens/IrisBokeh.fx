// @Maintainer jwrl
// @Released 2023-02-17
// @Author khaver
// @Created 2012-04-12

/**
 Iris Bokeh is the well-known bokeh effect, and provides control of the iris (5 to 8
 segments or round).  It also controls the size, rotation, threshold and pretty much
 anything else that you're likely to need to adjust.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect IrisBokeh.fx
// (c) 2012 - Gary Hango
//
// jwrl conversion notes:
// When updating this for the new library it took me almost two weeks to sort this out.
// A simple syntax conversion did not compile and ran out of the memory required for
// variables.  As a result one function has been removed, the other three have been
// changed beyond recognition, and the size of _bokeh array has been halved.  A new
// array, _bokehFix has been added to assist in the variable reduction.  The number of
// variables passed to the two major functions has also been reduced.
//
// All of this means that the inevitable problems are certainly going to be of my making
// and not khaver's.
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//
// Update 2023-01-23 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Iris bokeh", "Stylize", "Blurs and sharpens", "A bokeh effect with control of the iris (5 to 8 segments or round)", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Input, Depth);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (IrisShape, "Iris Shape", kNoGroup, 0, "Round|Eight|Seven|Six|Five");

DeclareFloatParam (Size, "Size", "Bokeh", kNoFlags, 50.0, 0.0, 100.0);
DeclareFloatParam (Rotation, "Bokeh Rotation", kNoGroup, kNoFlags, 0.0, 0.0, 360.0);
DeclareFloatParam (Threshold, "Bokeh Threshold", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Softness, "Bokeh Softness", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Gamma, "Bokeh Gamma", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);

DeclareIntParam (Alpha, "Mask Type", kNoGroup, 0, "None|Source Alpha|Source Luma|Mask Alpha|Mask Luma");

DeclareFloatParam (Brightness, "Mask Brightness", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Contrast, "Mask Contrast", kNoGroup, kNoFlags, 1.0, 0.0, 10.0);

DeclareBoolParam (Invert, "Invert Mask", kNoGroup, false);
DeclareBoolParam (Show, "Show Mask", kNoGroup, false);

DeclareFloatParam (Focus, "Source Focus", kNoGroup, kNoFlags, 50.0, 0.0, 100.0);
DeclareFloatParam (SourceMix, "Source Mix", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float2 _bokeh [60] = {
   // Round
   { 0.0, 1.0 }, { -0.2588, 0.9659 }, { -0.5, 0.866},
   { -0.7071, 0.7071 }, { -0.866, 0.5 }, { -0.9659, 0.2588 },
   { -1.0, 0.0 }, { -0.2588, -0.9659 }, { -0.5, -0.866 },
   { -0.7071, -0.7071 }, { -0.866, -0.5 }, { -0.9659, -0.2588 },
   // Eight
   { 0.0, 1.0 }, { -0.2242, 0.8747 }, { -0.4599, 0.777 },
   { -0.7071, 0.7071 }, { -0.777, 0.4599 }, { -0.8747, 0.2242 },
   { -1.0, 0.0 }, { -0.8747, -0.2242 }, { -0.777, -0.4599 },
   { -0.7071, -0.7071 }, { -0.4599, -0.777 }, { -0.2242, -0.8747 },
   // Seven
   { 0.0, 1.0 }, { -0.1905, 0.7286 }, { -0.4509, 0.6033 },
   { -0.7818, 0.6235 }, { -0.6973, 0.3935 }, { -0.6939, 0.1584 },
   { -0.799, -0.052 }, { -0.9749, -0.2225 }, { -0.668, -0.3479 },
   { -0.4878, -0.5738 }, { -0.4339, -0.901 }, { -0.2284, -0.7674 },
   // Six
   { 0.0, 1.0 }, { -0.1707, 0.7741 }, { -0.3464, 0.6 },
   { -0.585, 0.5349 }, { -0.866, 0.5 }, { -0.7557, 0.2392 },
   { -0.6928, 0.0 }, { -0.7557, -0.2392 }, { -0.866, -0.5 },
   { -0.585, -0.5349 }, { -0.3464, -0.6 }, { -0.1707, -0.7741 },
   // Five
   { 0.0, 1.0 }, { -0.1097, 0.8018 }, { -0.2957, 0.6218 },
   { -0.5, 0.4734 }, { -0.5, 0.4734 }, { -0.9511, 0.309 },
   { -0.7965, 0.1435 }, { -0.6827, -0.089 }, { -0.6047, -0.3293 },
   { -0.56, -0.5842 }, { -0.5878, -0.809 }, { -0.3045, -0.7061 }
};

float2 _bokehFix [5] = { { 0.0, -1.0 }, { 0.0, -1.0 }, { 0.0, -0.7118 },
                         { 0.0, -1.0 }, { -0.3045, -0.7061 } };

float2 _Kernel [13] = {
   {-6,0.002216}, {-5,0.008764}, {-4,0.026995}, {-3,0.064759}, {-2,0.120985}, {-1,0.176033},
   {0,0.199471}, {1,0.176033}, {2,0.120985}, {3,0.064759}, {4,0.026995}, {5,0.008764},
   {6,0.002216},
};

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_rotate (float2 pt, float2 rt)
{
   return (pt * rt.y) - (float2 (pt.y, -pt.x) * rt.x);
}

float4 BokehFn (sampler msk, sampler vid, float2 xy, float test)
{  
   float4 cOut = kTransparentBlack;

   float alpha = tex2D (msk, xy).a;
   float2 offs = Size * (1.0 - alpha) / (float2 (_OutputWidth, _OutputHeight) * test);
   float2 Bk, Rt;

   sincos (radians (Rotation), Rt.x, Rt.y);

   int tap = IrisShape * 12;

   for (int i = 0; i < 12; i++, tap++) {
      Bk = _bokeh [tap];
      cOut = max (tex2D (vid, xy + (offs * fn_rotate (Bk, Rt))), cOut);
      if (i == 0) Bk = _bokehFix [IrisShape];
      else Bk.x = -Bk.x;
      cOut = max (tex2D (vid, xy + (offs * fn_rotate (Bk, Rt))), cOut);
   }

   return float4 (cOut.rgb, alpha);
}

float4 BlurFn (sampler msk, sampler vid, float2 uv, float test)
{
   float4 cOut = kTransparentBlack;

   float alpha = tex2D (msk, uv).a;

   float2 offs = (1.0 - alpha) * Focus / test / float2 (_OutputWidth, _OutputHeight);
   float2 Bk;

   int tap = IrisShape * 12;

   for (int i = 0; i < 12; i++, tap++) {
      Bk = _bokeh [tap] * offs;
      cOut += tex2D (vid, uv + Bk);
      if (i == 0) Bk = _bokehFix [IrisShape] * offs;
      else Bk.x = -Bk.x;
      cOut += tex2D (vid, uv + Bk);
   }

   return float4 (cOut.rgb / 24.0, alpha);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These two passes map the input and depth timelines to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclarePass (Dpt)
{ return ReadPixel (Depth, uv2); }

DeclarePass (Bmask)
{
   float4 orig = ReadPixel (Inp, uv3);
   float4 aff  = ReadPixel (Dpt, uv3);

   float ac = (Alpha == 1) ? orig.a
            : (Alpha == 2) ? dot (orig.rgb, float3 (0.33, 0.34, 0.33))
            : (Alpha == 3) ? aff.a
            : (Alpha == 4) ? dot (aff.rgb, float3 (0.33, 0.34, 0.33)) : 0.0;

   ac *= Brightness;
   ac  = lerp (0.5, ac, Contrast);

   if (Invert) ac = 1.0 - ac;

   float4 color = kTransparentBlack;

   if (any (orig.rgb > Threshold)) color = pow (orig, 3.0 / Gamma);

   return float4 (color.rgb, ac);
}

DeclarePass (Bokeh1)
{ return BokehFn (Bmask, Bmask, uv3, 6.0); }

DeclarePass (Bokeh2)
{ return BokehFn (Bmask, Bokeh1, uv3, 5.0); }

DeclarePass (Bokeh3)
{ return BokehFn (Bmask, Bokeh2, uv3, 4.0); }

DeclarePass (Bokeh4)
{ return BokehFn (Bmask, Bokeh3, uv3, 3.0); }

DeclarePass (Bokeh5)
{ return BokehFn (Bmask, Bokeh4, uv3, 2.0); }

DeclarePass (Bokeh6)
{
   float2 coord = uv3;
   float2 offs = (Softness * 5.0) / _OutputWidth;

   float4 cOut = tex2D (Bokeh5, uv3);

   float alpha = cOut.a;

   for (int tap = 0; tap < 13; tap++) {
      coord.x = uv3.x + (offs * _Kernel [tap].x);
      cOut += tex2D (Bokeh5, coord) * _Kernel [tap].y;
   }

   return float4 (cOut.rgb / 2.0, alpha);
}

DeclarePass (Bokeh7)
{
   float2 coord = uv3;
   float2 offs = (Softness * 5.0) / _OutputHeight;

   float4 cOut = tex2D (Bokeh6, uv3);

   float alpha = cOut.a;

   for (int tap = 0; tap < 13; tap++) {
      coord.y = uv3.y + (offs * _Kernel [tap].x);
      cOut += tex2D (Bokeh6, coord) * _Kernel [tap].y;
   }

   return float4 (cOut.rgb / 2.0, alpha);
}

DeclarePass (Pass1)
{ return BlurFn (Bmask, Inp, uv3, 6.0); }

DeclarePass (Pass2)
{ return BlurFn (Bmask, Pass1, uv3, 5.0); }

DeclarePass (Pass3)
{ return BlurFn (Bmask, Pass2, uv3, 4.0); }

DeclarePass (Pass4)
{ return BlurFn (Bmask, Pass3, uv3, 3.0); }

DeclarePass (Pass5)
{ return BlurFn (Bmask, Pass4, uv3, 2.0); }

DeclareEntryPoint (IrisBokeh)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 orig = tex2D (Inp, uv3);
   float4 bokeh = tex2D (Bokeh7, uv3);
   float4 blurred = tex2D (Pass5, uv3);

   float ac = bokeh.a;
   float bomix = (SourceMix > 0.0) ? 1.0 : 1.0 + SourceMix;
   float blmix = (SourceMix < 0.0) ? 1.0 : 1.0 - SourceMix;

   if (Show) return ac.xxxx;

   float4 retval = (Focus > 0.0) || (Size > 0.0)
          ? 1.0 - ((1.0 - (bokeh * bomix)) * (1.0 - (blurred * blmix))) : orig;

   return lerp (orig, retval, tex2D (Mask, uv3).x);
}

