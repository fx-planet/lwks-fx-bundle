// @Maintainer jwrl
// @Released 2023-06-19
// @Author windsturm
// @Created 2012-05-12

/**
 This effect tiles an image and rotates those tiles to create abstract backgrounds.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiledImages.fx
//
//------------------------------- Original author's header --------------------------------//
//
// FxTile.
// Tiling and Rotation effect.
// 
// @param <threshold> The granularity of the tiling parameters
// @param <angle> Rotation parameters of the screen
// @author Windsturm
// @version 1.0
// @see <a href="http://kuramo.ch/webgl/videoeffects/">WebGL Video Effects Demo</a>
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2023-06-19 jwrl.
// Changed subcategory from "DVE Extras" to "Transform plus".
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Tiled images", "DVE", "Transform plus", "Creates tile patterns from the image, which can be rotated", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Threshold, "Threshold", kNoGroup, kNoFlags, 0.5, -1.0, 1.0);
DeclareFloatParam (Angle, "Angle", kNoGroup, kNoFlags, 0.0, 0.0, 360.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (RotateTiles)
{
   float Tcos, Tsin;

   if (Threshold >= 1.0) return float2 (0.5, 1.0).xxxy;

   float2 xy = uv2 - 0.5.xx;

   // rotation

   float2 angXY = float2 (xy.x, xy.y / _OutputAspectRatio);

   sincos (radians (Angle), Tsin, Tcos);

   float temp = (angXY.x * Tcos - angXY.y * Tsin) + 0.5;

   angXY.y = ((angXY.x * Tsin + angXY.y * Tcos) * _OutputAspectRatio ) + 0.5;
   angXY.x = temp;

   // tiling

   return tex2D (Inp, frac ((angXY - 0.5.xx) / (1.0 - Threshold) + 0.5.xx));
}

