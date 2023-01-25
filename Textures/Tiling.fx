// @Maintainer jwrl
// @Released 2023-01-25
// @Author khaver
// @Created 2011-04-28

/**
 Breaks the image into a mosaic or into glass tiles.  It's a combination of two original
 effects by khaver, Tiles.fx and GlassTiles.fx.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Tiling.fx
//
// Version history:
//
// Updated 2023-01-25 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tiling", "Stylize", "Textures", "Breaks the image into mosaic or glass tiles", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Tile style", kNoGroup, 0, "Mosaic pattern|Glass tiles");

DeclareFloatParam (Tiles, "Tiles", kNoGroup, kNoFlags, 15.0, 0.0, 200.0);
DeclareFloatParam (BevelWidth, "Bevel Width", kNoGroup, kNoFlags, 15.0, 0.0, 200.0);
DeclareFloatParam (Offset, "Offset", kNoGroup, kNoFlags, 0.0, 0.0, 200.0);

DeclareColourParam (EdgeColor, "Edge/Grout Color", kNoGroup, kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (MosaicTiles)
{
   float Size = Tiles / 200.0;
   float EdgeWidth = BevelWidth / 100.0;

   if (Size <= 0.0) return tex2D (Inp, uv2);

   float threshholdB = 1.0 - EdgeWidth;

   float2 Pbase = uv2 - fmod (uv2, Size.xx);
   float2 PCenter = Pbase + (Size / 2.0).xx;
   float2 st = (uv2 - Pbase) / Size;

   float3 cTop = 0.0.xxx;
   float3 cBottom = 0.0.xxx;
   float3 invOff = 1.0.xxx - EdgeColor.rgb;

   if ((st.x > st.y) && any (st > threshholdB)) { cTop = invOff; }

   if ((st.x > st.y) && any (st < EdgeWidth)) { cBottom = invOff; }

   float4 tileColor = tex2D (Inp, PCenter);

   return float4 (max (0.0.xxx, (tileColor.rgb + cBottom - cTop)), tileColor.a);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (GlassTiles)
{
   float2 newUV1 = uv1 + tan ((Tiles * 2.5) * (uv1 - 0.5) + Offset) * (BevelWidth / _OutputWidth);

   return IsOutOfBounds (newUV1) ? float4 (EdgeColor.rgb, 1.0) : tex2D (Input, newUV1);
}

