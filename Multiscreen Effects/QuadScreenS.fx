// @Maintainer jwrl
// @Released 2023-05-16
// @Author schrauber
// @Created 2020-06-08

/**
 This is a single effect with 4 inputs.  It features:
 - Fast (low GPU load)
 - Easy handling if you only need a standardized layout without cropping etc.

 "Scale" changes the distance between the screens by scaling them, always keeping them
 fixed in their corners.  In this simple effect, this setting is designed for static
 purposes only. Slow keyframing would make 1-pixel jumps of the edges visible. For dynamic
 scaling I recommend the effect "Quad split screen, dynamic zoom", which uses a more
 sophisticated edge interpolation.

 The background color is adjustable. If Alpha is set to 0, the Background can be replaced
 in a subsequent effect (e.g. "Blend").  It should be possible to nest this effect to make
 larger arrays than 4x4.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadScreenS.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-25 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Simple quad split screen", "DVE", "Multiscreen Effects", "A fast, simple single effect with 4 inputs", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (a, b, c, d);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (BaseScale, "Scale", kNoGroup, kNoFlags, 0.495, 0.0, 0.5);

DeclareColourParam (Bg, "Background", kNoGroup, kNoFlags, 0.0, 0.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Common definitions, declarations, macros
//-----------------------------------------------------------------------------------------//

#define THUMBNAILS 4

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_fn, float2 xy)
{
   if (xy.x < 0.0 || xy.x > 1.0 || xy.y < 0.0 || xy.y > 1.0) return float2 (0.0,1.0).xxxy;

   return tex2D (s_fn, xy);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (s_Fg0)
{ return fn_tex2D (a, uv1); }

DeclarePass (s_Fg1)
{ return fn_tex2D (b, uv2); }

DeclarePass (s_Fg2)
{ return fn_tex2D (c, uv3); }

DeclarePass (s_Fg3)
{ return fn_tex2D (d, uv4); }

DeclareEntryPoint (QuadScreenS)
{ 
   int i; // loop counter

  // Zoom positions:

   float2 pos [THUMBNAILS] = { { 0.0, 0.0 }, { 1.0, 0.0 }, { 0.0, 1.0 }, { 1.0, 1.0 } };

  // Direction vectors and zoom

   float2 vPt [THUMBNAILS];  

   float zoom = 1.0 - (1.0 / max (1.0e-9, BaseScale));  // The zoom range from [0..1] is rescaled to [-1e-9 .. 0]   ( 0 = Dimensions 100%, -1 = Dimensions 50 %, -2 Dimensions 33.3 %, -1e-9 (approximately negative infinite) = size 0%)

   for (i = 0; i < THUMBNAILS; i++) { 
      vPt [i] = pos [i] - uv5;   // Direction vector of the set position to the currently calculated texel.
      vPt [i] = (vPt [i] * zoom) + uv5;
   }

   // ------ Four samplers:

   float4 input [THUMBNAILS];

   input [0] = ReadPixel (s_Fg0, vPt [0]);   // Thumbnail top left. 
   input [1] = ReadPixel (s_Fg1, vPt [1]);   // Thumbnail top right.
   input [2] = ReadPixel (s_Fg2, vPt [2]);   // Thumbnail bottom left.
   input [3] = ReadPixel (s_Fg3, vPt [3]);   // Thumbnail bottom right.

   // ------ Mix:

   float4 mix = max (input [0], input [1]);
          mix = max (mix, input [2]);
          mix = max (mix, input [3]);

   // ------ Mix Bg & Alpha:

   return lerp (Bg, mix, mix.a);
}

