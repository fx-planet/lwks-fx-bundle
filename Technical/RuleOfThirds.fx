// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2022-08-28

/**
 This is just a simple rule of thirds grid generator.  That's it.  It will handle both
 portrait and landscape format media at any resolution supported by Lightworks.

 It is suitable for LW version 2022.2 and above, and is unlikely to compile on older
 versions.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RuleOfThirds.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-25 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rule of thirds", "User", "Technical", "A simple rule of thirds grid generator", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (GridWeight, "Line weight", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareIntParam (BlendGrid, "Grid display", kNoGroup, 0, "Add|Subtract|Difference");

DeclareFloatParam (_OutputAspectRatio);

DeclareIntParam (_InputOrientation);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SUBTRACT   1       // Subtract value used by BlendGrid
#define DIFFRNCE   2       // Difference value used by BlendGrid

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ThirdsRule)
{
   float4 Bgnd = ReadPixel (Input, uv1);

   // Quit if the opacity is zero and we don't need to show the rule of thirds pattern.

   if (Opacity == 0.0) return Bgnd;

   // Now we calculate the X and Y grid overlay line weights.  The scale factor is arbitrary.

   float x = ((GridWeight * 5.0) + 1.0) * 0.001;
   float y = x;

   // Correct x or y for aspect ratio based on the input video orientation.

   if ((_InputOrientation == 0) || (_InputOrientation == 180)) { x /= _OutputAspectRatio; }
   else y /= _OutputAspectRatio;

   float2 xy;

   // Initialise the grid to off, then turn it on inside the loop if it's needed.

   bool grid = false;

   for (float f = 0.0; f <= 3.0; f++) {
      xy = abs (uv1 - (f.xx / 3.0));

      grid = (xy.x < x) || (xy.y < y) || grid;
   }

   // The opacity setting is used to generate the grid at this point with alpha set to zero
   // so that we can blend the grid with the input video without affecting transparency.

   float4 retval = grid ? float4 (Opacity.xxx, 0.0) : kTransparentBlack;

   // Exit with the background blended with the grid, using difference, subtract or add.

   return BlendGrid == DIFFRNCE ? abs (Bgnd - retval) :
          BlendGrid == SUBTRACT ? saturate (Bgnd - retval) : saturate (Bgnd + retval);
}

