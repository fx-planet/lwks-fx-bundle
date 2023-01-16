// @Maintainer jwrl
// @Released 2023-01-11
// @Author jwrl
// @Created 2023-01-11

/**
 This effect creates the classic binocular mask shape.  It can be adjusted from a simple
 circular or telescope-style effect, to separated circular masks.  The edge softness can
 be adjusted, and colour fringing can be applied to the edges as well.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BinocularMask.fx
//
// Version history:
//
// Built 2023-01-11 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Binocular mask", "DVE", "Special Effects", "Creates the classic binocular effect", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Size, "Size", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Offset, "L / R offset", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Softness, "Edge softness", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Fringing, "Edge fringing", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define WHITE   1.0.xxxx

#define FEATHER 0.05
#define CIRCLE  0.25
#define RADIUS  1.6666666667

#define CENTRE  0.5.xx

#define SIZE    3.25

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (PovMask)
{
   float2 range = float2 (0.5 - uv0.x - (Offset * 0.2), 0.5 - uv0.y);

   float soft   = max (0.02, Softness) * FEATHER;
   float edge   = CIRCLE - soft;
   float radius = length (float2 (range.x, range.y / _OutputAspectRatio)) * RADIUS;

   soft += soft;

   return lerp (WHITE, kTransparentBlack, saturate ((radius - edge) / soft));
}

DeclareEntryPoint (BinocularMask)
{
   float2 uv  = uv0 + (0.5 / float2 (_OutputWidth, _OutputHeight));
   float2 xy1 = (uv - CENTRE) / (Size * SIZE);
   float2 xy2 = float2 (0.5 - uv.x, uv.y - 0.5) / (Size * SIZE);

   xy1 += CENTRE;
   xy2 += CENTRE;

   float Mgrn = 1.0 - tex2D (PovMask, xy1).x;
   float Mred = 1.0 - tex2D (PovMask, xy2).x;
   float Mdif = 1.0 - (Mgrn * Mred);

   Mdif = lerp (1.0 - min (Mgrn, Mred), Mdif, saturate (Offset * 4.0));

   Mgrn = (1.0 + sin ((Mdif - 0.5) * PI)) * 0.5;
   Mred = lerp (Mdif, Mgrn, Fringing);
   Mgrn = 1.0 - cos (Mgrn * HALF_PI);

   float4 retval = ReadPixel (Inp, uv1);

   retval.r  *= Mred;
   retval.g  *= lerp (Mdif, Mgrn, Fringing);
   retval.ba *= Mdif;

   return retval;
}

