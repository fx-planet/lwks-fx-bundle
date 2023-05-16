// @Maintainer jwrl
// @Released 2023-05-16
// @Author baopao
// @Author nouanda
// @Created 2013-06-10

/**
 Kaleido produces the classic kaleidoscope effect.  The number of sides, the centering,
 scaling and zoom factor are all adjustable.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Kaleido.fx
//
// This effect is a rewrite of Kaleido by baopao (http://www.alessandrodallafontana.com)
// which was based on http://pixelshaders.com/ and corrected for Cg by Lightworks user
// nouanda.
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Kaleido", "Stylize", "Special Effects", "The number of sides in this kaleidoscope, the centering, scaling and zoom factor are all adjustable", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Sides, "Sides", kNoGroup, kNoFlags, 5.0, 0.0, 50.0);
DeclareFloatParam (Scale, "Scale", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Zoom, "Zoom", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);

DeclareFloatParam (PanX, "Pan", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (PanY, "Pan", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define TWO_PI  6.2831853072

#define MINIMUM 0.0000000001

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Kaleido)
{
   float2 PosXY = float2 (PanX, 1.0 - PanY);
   float2 xy = uv1 - PosXY;

   float zoom  = max (MINIMUM, Zoom);

   if (Sides <= 0.0) {
      xy = (xy / zoom) + PosXY;
   }
   else {
      float sides = max (MINIMUM, Sides);
      float scale = max (MINIMUM, Scale);
      float radius = length (xy);
      float p = max (MINIMUM, abs (xy.x));

      xy.x = xy.x < 0.0 ? -p : p;

      float angle = atan (xy.y / xy.x);

      p = TWO_PI / sides;
      angle -= p * floor (angle / p);
      angle = abs (angle - (p * 0.5));

      sincos (angle, xy.y, xy.x);
      xy = ((xy * radius / zoom) + PosXY) / scale;
   }

   return ReadPixel (Inp, xy);
}

