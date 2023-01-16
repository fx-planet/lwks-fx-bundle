// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 Originally created as YAblur.fx, this was an accident that looked interesting, so it was
 given a name and further developed.  It is based on a radial anti-aliassing blur developed
 for another series of effects, further modulated by image content.  The result is a very
 soft ghostly blur.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GhostlyBlur.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Ghostly blur", "Stylize", "Blurs and sharpens", "The sort of effect that you get when looking through a fogged window", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Radius, "Radius", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Fog, "Fogginess", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LOOP_1   29
#define RADIUS_1 0.1
#define ANGLE_1  0.216662

#define LOOP_2   23
#define RADIUS_2 0.066667
#define ANGLE_2  0.273182

#define FOG_LIM  0.8
#define FOG_MIN  0.4
#define FOG_MAX  4.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (prelim)
{
   float4 Fgd = tex2D (Input, uv1);

   if IsOutOfBounds (uv1) return Fgd;

   float gamma = 3.0 / ((1.5 + Fog) * 2.0);

   float2 xy, radius = (Radius * Radius * RADIUS_1).xx;

   radius *= float2 ((1.0 - Fgd.b) / _OutputAspectRatio, Fgd.r + Fgd.g);

   float4 retval = kTransparentBlack;

   for (int i = 0; i < LOOP_1; i++) {
      sincos ((i * ANGLE_1), xy.x, xy.y);
      retval += pow (mirror2D (Input, uv1 + (xy * radius)), gamma);
   }

   retval /= LOOP_1;

   return retval;
}

DeclareEntryPoint (GhostlyBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgd = tex2D (Input, uv1);

   float gamma = 3.0 / ((1.5 + Fog) * 2.0);

   float4 retval = tex2D (prelim, uv1);

   float2 xy, radius = (Radius * Radius * RADIUS_2).xx;

   radius *= float2 ((retval.r + retval.b) / _OutputAspectRatio, 1.0 - retval.g);

   retval = kTransparentBlack;

   for (int i = 0; i < LOOP_2; i++) {
      sincos ((i * ANGLE_2), xy.x, xy.y);
      retval += pow (mirror2D (prelim, uv1 + (xy * radius)), gamma);
   }

   retval /= LOOP_2;

   retval.rgb += lerp (0.0.xxx, Fgd.rgb - (Fgd.rgb * retval.rgb), saturate (-Fog));

   return lerp (Fgd, saturate (retval), tex2D (Mask, uv1));
}

