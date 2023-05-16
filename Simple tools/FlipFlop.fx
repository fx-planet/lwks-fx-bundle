// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2018-03-14

/**
 This emulates a similar effect in other NLEs.  The resemblance to Lightworks' flip and
 flop routines is obvious.  However because the maths operations to achieve the result
 have been more than halved it uses less than the GPU resources needed by either a flip
 or flop effect.  That means that using this instead of those two effects together
 requires less than half the processing.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FlipFlop.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-25 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flip flop", "DVE", "Simple tools", "Rotates video by 180 degrees.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Vid)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (FlipFlop)
{
   float2 xy = 1.0.xx - uv2;

   float4 source = tex2D (Vid, uv2);
   float4 retval = tex2D (Vid, xy);

   return lerp (source, retval, tex2D (Mask, uv2).x);
}

