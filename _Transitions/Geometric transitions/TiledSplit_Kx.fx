// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This is a delta key and alpha transition that splits a keyed image into tiles then blows
 them apart or materialises the key from tiles.  It's a combination of two previous effects,
 TileSplit_Ax and TileSplit_Adx.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiledSplit_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tiled split (keyed)", "Mix", "Geometric transitions", "Splits a blended foreground into tiles and blows them apart", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Width, "Width", "Tile size", kNoFlags, 0.5, 0.0, 1.0;);
DeclareFloatParam (Height, "Height", "Tile size", kNoFlags, 0.5, 0.0, 1.0;);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define FACTOR 100
#define OFFSET 1.2

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler B, float2 xy1, float2 xy2)
{
   float4 Fgnd = ReadPixel (Fg, xy1);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_horiz_split (sampler S, float2 uv)
{
   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (1.0 - offset) * (1.0 - Amount);

   return tex2D (S, uv + float2 (offset, 0.0));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique TiledSplit_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1; }

DeclarePass (Super_F)
{
   float4 Fgnd = tex2D (Bg_F, uv3);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

DeclarePass (Tiles_F)
{ return fn_horiz_split (Super_F, uv3); }

DeclareEntryPoint (TiledSplit_F)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv.x * dsplc);

   offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   uv.y += offset / _OutputAspectRatio;

   float4 Fgnd = tex2D (Tiles_F, uv);

   if (CropEdges && IsOutOfBounds (uv1)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique TiledSplit_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2; }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclarePass (Tiles_I)
{ return fn_horiz_split (Super_I, uv3); }

DeclareEntryPoint (TiledSplit_I)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv.x * dsplc);

   offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   uv.y += offset / _OutputAspectRatio;

   float4 Fgnd = tex2D (Tiles_I, uv);

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique TiledSplit_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2; }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclarePass (Tiles_O)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (offset - 1.0) * Amount;
   uv.x += offset;

   return tex2D (Super_O, uv);
}

DeclareEntryPoint (TiledSplit_O)
{
   float2 uv = uv3;

   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv.x * dsplc);

   offset = ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * Amount;
   uv.y += offset / _OutputAspectRatio;

   float4 Fgnd = tex2D (Tiles_O, uv);

   if (CropEdges && IsOutOfBounds (uv2)) Fgnd = kTransparentBlack;

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a);
}

