// @Maintainer jwrl
// @Released 2023-05-16
// @Author windsturm
// @Created 2012-08-02

/**
 This does exactly what it says - generates both monochrome and colour video noise.
 Because this effect needs to be able to precisely manage pixel weight no matter what
 the original clip size or aspect ratio is it has not been possible to make it truly
 resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VideoNoise.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Video noise", "Stylize", "Textures", "Generates either monochrome or colour video noise", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Color Type", kNoGroup, 0, "Monochrome|Color");

DeclareFloatParam (Size, "Size", kNoGroup, kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Alpha, "Alpha", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Seed, "Random Seed", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float rand (float2 uv, float seed)
{
   return frac (sin (dot (uv, float2 (12.9898,78.233)) + seed) * (43758.5453));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (VideoNoiseMono)
{
   float2 xy;

   if (Size != 0.0) {
      float xSize = Size / 50.0;
      float ySize = xSize * _OutputAspectRatio;

      xy = float2 (round ((uv1.x - 0.5) / xSize) * xSize, round ((uv1.y - 0.5) / ySize) * ySize);
   }
   else xy = uv1;

   float c = rand (xy, rand (xy, Seed + _Progress));

   float4 ret = ReadPixel (Inp, uv1);

   ret = lerp (ret, float4 (c.xxx, 1.0), ret.a * Opacity);

   return float4 (ret.rgb, ret.a * Alpha);
}

DeclareEntryPoint (VideoNoiseColor)
{
   float2 xy;

   if (Size != 0.0) {
      float xSize = Size / 50.0;
      float ySize = xSize * _OutputAspectRatio;

      xy = float2 (round ((uv1.x - 0.5) / xSize) * xSize, round ((uv1.y - 0.5) / ySize) * ySize);
   }
   else xy = uv1;

   float s = Seed + _Progress;
   float t = s + 1.0;
   float u = s + 2.0;

   float3 c = float3 (rand (xy, rand (xy, s)), rand (xy, rand (xy, t)), rand (xy, rand (xy, u)));

   float4 ret = ReadPixel (Inp, uv1);

   ret = lerp (ret, float4 (c, 1.0), ret.a * Opacity);

   return float4 (ret.rgb, ret.a * Alpha);
}

