// @Maintainer jwrl
// @Released 2023-01-23
// @Author jwrl
// @Created 2023-01-23

/**
 First, there is no such thing as the perfect edge sharpening effect.  They all have
 artefacts of one sort or another.  This one attempts to be very clean by sampling
 the current pixel at a small offset in both X and Y directions and deriving an edge
 signal directly from that.  The offset amount is adjustable, and the edge component
 derived from this process can be clamped to control its visibility.  While this is
 similar in operation to a standard unsharp mask it can often give much finer edges.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect YAsharpen.fx
//
// Built 2023-01-23 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Yet another sharpen", "Stylize", "Blurs and sharpens", "A sharpen utility that can give extremely clean results", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Offset, "Sample offset", "Parameters", kNoFlags, 2.0, 0.0, 6.0);
DeclareFloatParam (EdgeClamp, "Edge clamp", "Parameters", kNoFlags, 0.125, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA float3(0.897, 1.761, 0.342)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (YAsharpen)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float2 sampleX = float2 (Offset / _OutputWidth, 0.0);
   float2 sampleY = float2 (0.0, Offset / _OutputHeight);

   float clamp = max (1.0e-6, EdgeClamp);

   float4 luma_val = float4 (LUMA * Amount / clamp, 0.5);
   float4 Input = ReadPixel (Inp, uv1);
   float4 edges = tex2D (Inp, uv1 + sampleY);
   float4 retval = Input;

   edges += tex2D (Inp, uv1 - sampleX);
   edges += tex2D (Inp, uv1 + sampleX);
   edges += tex2D (Inp, uv1 - sampleY);
   edges = retval - (edges / 4.0);
   edges.a = 1.0;

   retval.rgb += ((saturate (dot (edges, luma_val)) * clamp * 2.0) - clamp).xxx;

   return lerp (Input, retval, tex2D (Mask, uv1).x);
}

