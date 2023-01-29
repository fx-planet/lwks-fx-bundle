// @Maintainer jwrl
// @Released 2023-01-29
// @Author jwrl
// @Created 2023-01-29

/**
 This effect starts off by building blocks from the outgoing image for the first third of
 the effect, then dissolves to the new image for the next third, then loses the blocks
 over the remainder of the effect.

 The original block component of the effect has been rewritten, because when mixing between
 clips with differing aspect ratios the earlier version gave unpredictable results.  The
 rewrite has had the side effect of making that part of the process simpler.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Block_Dx.fx
//
// Version history:
//
// Built 2023-01-29 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Block dissolve", "Mix", "Geometric transitions", "Builds the outgoing image into larger and larger blocks as it fades to the incoming", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (blockSize, "Block size", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
//  Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Mixed)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float dissolve = saturate ((Amount * 3.0) - 1.0);

   return lerp (Fgnd, Bgnd, dissolve);
}

DeclareEntryPoint (Block_Dx)
{
   float2 xy = uv3;

   if (blockSize > 0.0) {
      float Xsize = max (1e-6, blockSize * sin (Amount * PI) * 0.1);
      float Ysize = Xsize * _OutputAspectRatio;

      xy.x = (floor ((xy.x - 0.5) / Xsize) * Xsize) + 0.5;
      xy.y = (floor ((xy.y - 0.5) / Ysize) * Ysize) + 0.5;
   }

   return tex2D (Mixed, xy);
}

