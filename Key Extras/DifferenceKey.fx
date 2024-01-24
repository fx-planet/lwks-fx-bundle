// @Maintainer jwrl
// @Released 2024-01-24
// @Author jwrl
// @Created 2024-01-24

/**
 This is a difference keyer that has only six parameters, the opacity, key clip, key
 gain, feathering controls and the invert key switch.  Finally, so that the difference
 key result can be better visualised a seventh parameter, key mask, can be selcted.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DifferenceKey.fx
//
// Version history:
//
// Created 2024-01-24 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Difference key", "Key", "Key Extras", "A deltakeyer which keys foregrounds over backgrounds using a reference image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg, Ref);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Clip, "Key clip", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Gain, "Key gain", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Size, "Feather", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (InvertKey, "Invert key", kNoGroup, false);
DeclareBoolParam (ShowKey, "Show key", kNoGroup, false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define BdrPixel(SHADER,XY) (IsOutOfBounds(XY) ? BLACK : tex2D(SHADER, XY))

#define LUMACONV float3(0.2989, 0.5866, 0.1145)

#define LOOP   12
#define DIVIDE 24

#define RADIUS 0.002
#define ANGLE  0.2617993878

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Delta)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 dRef = ReadPixel (Ref, uv3);

   float cDiff = distance (dRef.r, Fgnd.r);

   cDiff = max (cDiff, distance (dRef.g, Fgnd.g));
   cDiff = max (cDiff, distance (dRef.b, Fgnd.b));

   float alpha = smoothstep (Clip, Clip + Gain, cDiff);

   if (InvertKey) alpha = 1.0 - alpha;

   return float4 (alpha.xxx, Fgnd.a);
}

DeclareEntryPoint (DifferenceKey)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ShowKey ? float4 (0.0.xxx, 1.0) : ReadPixel (Bg, uv2);
   float4 _msk = ReadPixel (Mask, uv4);
   float4 retval;

   if (IsOutOfBounds (uv1)) { retval = Bgnd; }
   else {
      float alpha = tex2D (Delta, uv4).x;

      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;

      for (int i = 0; i < LOOP; i++) {
         sincos ((i * ANGLE), xy.x, xy.y);
         xy *= radius;
         alpha += tex2D (Delta, uv4 + xy).x;
         alpha += tex2D (Delta, uv4 - xy).x;
         xy += xy;
         alpha += tex2D (Delta, uv4 + xy).x;
         alpha += tex2D (Delta, uv4 - xy).x;
      }

      alpha = saturate ((alpha / DIVIDE) - 1.0);
      Fgnd.a = min (Fgnd.a, alpha);

      retval = ShowKey ? float4 (alpha.xxx, 1.0) : lerp (Bgnd, Fgnd, alpha * Amount);
   }

   return lerp (Bgnd, retval, retval.a * _msk.x);
}

