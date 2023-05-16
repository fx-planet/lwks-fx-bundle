// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2016-05-09

/**
 A two pass rotary anti-alias tool that samples first at 6 degree intervals then at 7.5
 degree intervals using different radii for each pass.  This is done to give a very smooth
 result.  The radii can be scaled and the antialias blur can be faded.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Antialias.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Antialias", "User", "Technical", "A two pass rotary anti-alias tool that gives a very smooth result", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Radius, "Radius", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Opacity, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LOOP_1    30
#define DIVISOR_1 LOOP_1*2.0
#define RADIUS_1  0.00125
#define ANGLE_1   0.10472

#define LOOP_2    24
#define DIVISOR_2 LOOP_2*2.0
#define RADIUS_2  0.001
#define ANGLE_2   0.1309

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
{
   float2 uv = (0.5 - abs (abs (frac (xy / 2.0)) - 0.5.xx)) * 2.0;

   return tex2D (S, uv);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input)
{ return ReadPixel (Inp, uv1); }

DeclarePass (preBlur)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgd = tex2D (Input, uv2);

   if ((Opacity == 0.0) || (Radius == 0.0)) return Fgd;

   float4 retval = 0.0.xxxx;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * pow (Radius, 2.0) * RADIUS_1;
   float angle = 0.0;

   for (int i = 0; i < LOOP_1; i++) {
      sincos (angle, xy.x, xy.y);
      xy *= radius;
      retval += mirror2D (Input, uv2 + xy);
      retval += mirror2D (Input, uv2 - xy);
      angle  += ANGLE_1;
   }

   retval /= DIVISOR_1;

   return retval;
}

DeclareEntryPoint (Antialias)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Fgd = tex2D (Input, uv2);

   if ((Opacity == 0.0) || (Radius == 0.0)) return Fgd;

   float4 retval = 0.0.xxxx;
   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * pow (Radius, 2.0) * RADIUS_2;
   float angle = 0.0;

   for (int i = 0; i < LOOP_2; i++) {
      sincos (angle, xy.x, xy.y);
      xy *= radius;
      retval += mirror2D (preBlur, uv2 + xy);
      retval += mirror2D (preBlur, uv2 - xy);
      angle  += ANGLE_2;
   }

   retval /= DIVISOR_2;

   return lerp (Fgd, retval, tex2D (Mask, uv2) * Opacity);
}

