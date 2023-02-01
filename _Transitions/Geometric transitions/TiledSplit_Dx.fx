// @Maintainer jwrl
// @Released 2023-02_01
// @Author jwrl
// @Created 2023-02_01

/**
 This is a transition that splits the outgoing image into tiles then blows them apart or
 materialises the incoming video from those tiles.  It's the companion to the effect
 "Tiled split (keyed)" (TiledSplit_Kx.fx).

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiledSplit_Dx.fx
//
// Version history:
//
// Built 2023-02_01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tiled split", "Mix", "Geometric transitions", "Splits the outgoing video into tiles and blows them apart or reverses that process", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition direction", kNoGroup, 1, "Materialise from tiles|Break apart to tiles");

DeclareFloatParam (Width, "Width", "Tile size", kNoFlags, 0.5, 0.0, 1.0;);
DeclareFloatParam (Height, "Height", "Tile size", kNoFlags, 0.5, 0.0, 1.0;);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2 (0.0,1.0).xxxy

#define FACTOR 100
#define OFFSET 1.2

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// technique TiledSplit_Dx_I

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Overlay_I)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (Tiles_I)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (1.0 - offset) * (1.0 - Amount);
   uv.x += offset;

   return ReadPixel (Overlay_I, uv);
}

DeclareEntryPoint (TiledSplit_Dx_I)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv.x * dsplc);

   offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   uv.y += offset / _OutputAspectRatio;

   float4 Fgnd = ReadPixel (Tiles_I, uv);

   return lerp (tex2D (Outgoing, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique TiledSplit_Dx_O

DeclarePass (Overlay_O)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Tiles_O)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (offset - 1.0) * Amount;
   uv.x += offset;

   return ReadPixel (Overlay_O, uv);
}

DeclareEntryPoint (TiledSplit_Dx_O)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv.x * dsplc);

   offset  = ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * Amount;
   uv.y += offset / _OutputAspectRatio;

   float4 Fgnd = ReadPixel (Tiles_O, uv);

   return lerp (tex2D (Incoming, uv3), Fgnd, Fgnd.a);
}

