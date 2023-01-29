// @Maintainer jwrl
// @Released 2023-01-29
// @Author jwrl
// @Created 2023-01-29

/**
 This obliterates the outgoing image with a mosaic pattern of highly coloured tiles that
 progressively fill the screen to halfway through the effect.  It then removes the tiles
 progressively to show the incoming image.  The tile build and "un-build" are from the
 brightest to the darkest sections of a dissolve between the two images and back again.
 This makes the linearity of this effect highly dependant on the black/white balance
 between the two images used.  If this is important to you, you can adjust it by adding
 intermediate keyframes within the transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourTile_Dx.fx
//
// Version history:
//
// Built 2023-01-29 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Coloured tiles", "Mix", "Geometric transitions", "Transitions between images using a mosaic pattern of highly coloured tiles",CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (TileSize, "Tile size", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268
#define SCALE   float3(1.2, 0.8, 1.0)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// These two passes map the outgoing and incoming video sources to sequence coordinates.
// This makes handling the aspect ratio, size and rotation much simpler.

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

// This sets up a mix between the two sources and uses it to generate a colour pseudo
// random noise pattern which in turn is later used to generate the mosaic wipe.

DeclarePass (Tiles)
{
   float4 retval = tex2D (Outgoing, uv3);

   retval = lerp (retval, tex2D (Incoming, uv3), Amount);

   // This next section was produced empirically.  What I wanted was to produce colour
   // noise that was more than just RGB pixels, but more subtle mixes of those primaries.
   // I experimented with various combinations of things until I had a satisfying mix.

   float a, b;

   sincos (Amount * HALF_PI, a, b);
   retval.rgb = min (abs (retval.rgb - float3 (a, b, frac ((uv3.x + uv3.y) * 1.2345 + Amount))), 1.0);
   retval.a   = 1.0;

   float3 x = retval.aga;

   for (int i = 0; i < 32; i++) {
      retval.rgb = SCALE * abs (retval.gbr / dot (retval.brg, retval.rgb) - x);
   }

   return retval;
}

DeclareEntryPoint (ColourTile_Dx)
{
   float Tscale = TileSize * 0.2;     // Prescale the tile size by 1/5

   // Generate the mosaic size, compensating for the aspect ratio

   float2 mosaic = float2 (1.0, _OutputAspectRatio) * max (1.0e-6, Tscale * 0.2);

   // We perform a slight zoom which is dependent on the tile size.  This ensures that
   // we never run off the edges of the noise pattern when sampling the mosaic.  The
   // mosaic address is generated for each of the three video sources, which are
   // Outgoing, Incoming and sequence.

   float2 Mscale = (1.0 - Tscale) / mosaic;

   float2 xy1 = (round ((uv3 - 0.5.xx) * Mscale) * mosaic) + 0.5.xx;
   float2 xy2 = (round ((uv3 - 0.5.xx) * Mscale) * mosaic) + 0.5.xx;
   float2 xy3 = (round ((uv3 - 0.5.xx) * Mscale) * mosaic) + 0.5.xx;

   // This recovers the required input depending on whether the transition has passed the
   // halfway point or not.  It also recovers a gated version of the source to be used in
   // generating the coloured mosaic tiles.

   float4 gating = lerp (tex2D (Outgoing, xy1), tex2D (Incoming, xy2), Amount);
   float4 retval = (Amount < 0.5) ? tex2D (Outgoing, uv3) : tex2D (Incoming, uv3);

   // The reference tile level depending on the luminance value of the gated source is now
   // calculated, and a range value that runs from 1.0 to 0.0 back to 1.0 again is produced.

   float level = max (gating.r, max (gating.g, gating.b));
   float range = abs (Amount - 0.5) * 2.0;

   // Finally if the gating level exceeds the expected range we show the tile colour.

   return (level >= range) ? tex2D (Tiles, xy3) : retval;
}

