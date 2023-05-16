// @Maintainer jwrl
// @Released 2023-01-26
// @Author hugly
// @Author flyingrub https://www.shadertoy.com/view/wsBXWW
// @Created 2019-09-07

/**
 This effect adds an adjustable pseudo-random shake to the screen.  So that the edges of the
 frame aren't seen the image is zoomed in slightly.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Screenshake.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-26 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Screen shake", "Stylize", "Video artefacts", "Random screen shake, slightly zoomed in, no motion blur", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (strength, "Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (speed, "Speed", kNoGroup, kNoFlags, 1.0, 0.4, 2.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define iTime (_Length * _Progress) 

#define SIXTH_3 0.1666667.xxx
#define THIRD_3 0.3333333.xxx
#define HALF_3  0.5.xxx
#define ONE_3   1.0.xxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 random3 (float3 c)
{
   float j = 4096.0 * sin (dot (c, float3 (17.0, 59.4, 15.0)));

   return frac (float3 (512.0, 64.0, 8.0) * j);
}

float simplex3d (float3 p)
{    
   float3 s = floor (p + dot (p, THIRD_3).xxx);
   float3 x = p - s + dot (s, SIXTH_3).xxx;

   float3 e  = step (0.0.xxx, x - x.yzx);
   float3 i1 = e * (ONE_3 - e.zxy);
   float3 i2 = ONE_3 - e.zxy * (ONE_3 - e);

   float3 x1 = x - i1 + SIXTH_3;
   float3 x2 = x - i2 + THIRD_3;
   float3 x3 = x - HALF_3;

   float4 w = float4 (dot (x, x), dot (x1, x1), dot (x2, x2), dot (x3, x3));

   w  = pow (max (0.6.xxxx - w, 0.0.xxxx), 4.0);
   w *= float4 (dot (random3 (s) - HALF_3, x), dot (random3 (s + i1) - HALF_3, x1),
                dot (random3 (s + i2) - HALF_3, x2), dot (random3 (s + ONE_3) - HALF_3, x3));

   return dot (w, 52.0.xxxx);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Screenshake)
{    
   float2 xy = ((uv1 - 0.5.xx) / 1.04) + 0.5.xx;   //** zoom

   float3 p3 = float3 (0.0.xx, frac (iTime / 13.0) * speed * 104.0) + 200.0.xxx;

   xy += float2 (simplex3d (p3), simplex3d (p3 + 10.0.xxx)) * strength / 30.0;

   return IsOutOfBounds (uv1) ? kTransparentBlack
                              : lerp (kTransparentBlack, tex2D (Fg, xy), tex2D (Mask, uv1).x);
}

