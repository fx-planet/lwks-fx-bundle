// @Maintainer jwrl
// @Released 2023-02-02
// @Author jwrl
// @Created 2023-02-02

/**
 This obliterates the outgoing image with a mosaic pattern that progressively fills the
 screen to halfway through the effect.  It then removes the mosaic progressively to show
 the incoming image.  The mosaic build and the incoming reveal are both from the darkest
 to the brightest sections of a 50 percent mix of the two images, making the progression
 in and out reasonably logical.

 The linearity of this effect is highly dependant on the black/white balance between the
 two images used.  If this is important to you, you can adjust it by adding intermediate
 keyframes within the transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MosaicBlocks_Dx.fx
//
// Version history:
//
// Built 2023-02-02 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Mosaics and blocks", "Mix", "Geometric transitions", "Obliterates the outgoing image into expanding blocks as it fades to the incoming image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Mode", kNoGroup, 0, "Mosaic tiles|Coloured blocks");

DeclareFloatParam (TileSize, "Size", "Tiles", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Aspect, "Aspect ratio", "Tiles", kNoFlags, 1.0, 0.25, 4.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268
#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Mosaics

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Mix_M)
{
    float4 Fgnd = tex2D (Outgoing, uv3);
    float4 Bgnd = tex2D (Incoming, uv3);

   return (Fgnd + Bgnd) / (Fgnd.a + Bgnd.a);
}

DeclareEntryPoint (Mosaics)
{
   float Tscale  = TileSize * 0.2;                    // Prescale the tile size by 1/5
   float mosaic  = max (0.00000001, Tscale * 0.2);    // Scale mosaic and prevent zero values
   float range_1 = Amount * 2.0;                      // range_1 reaches 1.0 at 50% point
   float range_2 = max (0.0, range_1 - 1.0);          // range_2 starts at 50% point
   float AspectRatio = clamp (Aspect, 0.01, 10.0);

   // We perform a slight zoom in the size, which is dependant on the tile size.  While
   // this is a nice enhancement to the effect, it also has the extremely practical effect
   // of ensuring that we never run off the edges of the frame when sampling the mosaic.

   float2 xy = (uv3 * (1.0 - Tscale)) + (Tscale * 0.5).xx;

   // Generate the mosaic addressing, compensating for the aspect ratio

   xy.x    = (round ((xy.x - 0.5) / mosaic) * mosaic) + 0.5;
   mosaic *= _OutputAspectRatio * AspectRatio;
   xy.y    = (round ((xy.y - 0.5) / mosaic) * mosaic) + 0.5;

   // Ensure that range_1 can't overflow

   range_1 = min (range_1, 1.0);

   // This produces the 50% mixed mosaic then does a level dependant mix from Outgoing
   // to the mosaic for the first half of the transition, followed by a level dependant
   // mix from the mosaic to Incoming for the second half of the transition.

   float4 m_1 = ReadPixel (Mix_M, xy);
   float4 m_2 = max (m_1.r, max (m_1.g, m_1.b)) >= range_1 ? tex2D (Outgoing, uv3) : m_1;

   return max (m_2.r, max (m_2.g, m_2.b)) >= range_2 ? m_2 : tex2D (Incoming, uv3);
}

//-----------------------------------------------------------------------------------------//

// technique Blocks

DeclarePass (Mix_B)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   float dissolve = saturate ((Amount * 3.0) - 1.0);

   return lerp (Fgnd, Bgnd, dissolve);
}

DeclareEntryPoint (Blocks)
{
   float2 xy = uv3;

   if (TileSize > 0.0) {
      float AspectRatio = clamp (Aspect, 0.01, 10.0);
      float Xsize = max (1e-6, TileSize * sin (Amount * PI) * 0.1);
      float Ysize = Xsize * AspectRatio * _OutputAspectRatio;

      xy.x = (floor ((xy.x - 0.5) / Xsize) * Xsize) + 0.5;
      xy.y = (floor ((xy.y - 0.5) / Ysize) * Ysize) + 0.5;
   }

   return ReadPixel (Mix_B, xy);
}

