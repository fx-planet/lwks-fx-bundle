// @Maintainer jwrl
// @Released 2023-08-02
// @Author khaver
// @Author jwrl
// @Created 2016-01-22

/**
 These are a collection of effects based on mosaic tiles that can be used to transition
 into or out of standard video, blended foregrounds and titles.  Images fade into or out
 of mosaic tiles or blocks progressively over the duration of the transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TileTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-13 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Tile transitions", "Mix", "Geometric transitions", "Builds images into larger and larger blocks as they fades in or out", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Mode", "Tiles", 0, "Mosaic tiles|Coloured blocks|Break apart to tiles|Materialise from tiles");
DeclareFloatParam (TileSize, "Size", "Tiles", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Aspect, "Aspect ratio", "Tiles", kNoFlags, 1.0, 0.25, 4.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2 (0.0,1.0).xxxy

#define FACTOR 100
#define OFFSET 1.2

#define BLOCKS  0.1

#define SCALE   float3(1.2, 0.8, 1.0)

#define HALF_PI 1.5707963268
#define PI      3.1415926536

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (!Blended) return float4 ((ReadPixel (F, xy1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (B, xy2);
      Bgnd = ReadPixel (F, xy1);
   }
   else {
      Fgnd = ReadPixel (F, xy1);
      Bgnd = ReadPixel (B, xy2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (F, xy1) : ReadPixel (B, xy2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

float2 fn_block_gen (float2 xy, float range)
{
   float AspectRatio = clamp (Aspect, 0.01, 10.0);
   float Xsize = max (1e-10, range) * TileSize * BLOCKS;
   float Ysize = Xsize * AspectRatio * _OutputAspectRatio;

   float2 xy1;

   xy1.x = (round ((xy.x - 0.5) / Xsize) * Xsize) + 0.5;
   xy1.y = (round ((xy.y - 0.5) / Ysize) * Ysize) + 0.5;

   return xy1;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Mosaics

DeclarePass (Fg_M)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bgd)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_M)
{
   float4 Bgnd = tex2D (Bgd, uv3);

   return Blended ? Bgnd
                  : lerp (tex2D (Fg_M, uv3), Bgnd, saturate ((Amount * 3.0) - 1.0));
}

DeclareEntryPoint (Mosaics)
{
   float4 Fgnd = tex2D (Fg_M, uv3);
   float4 Bgnd = tex2D (Bg_M, uv3);
   float4 maskBg, retval = Bgnd;

   float2 xy;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         if (SwapDir) {
            xy = (TileSize > 0.0) ? fn_block_gen (uv3, cos (Amount * HALF_PI)) : uv3;
            Fgnd = ReadPixel (Fg_M, xy);
            retval = lerp (Bgnd, Fgnd, Amount);
         }
         else {
            xy = (TileSize > 0.0) ? fn_block_gen (uv3, sin (Amount * HALF_PI)) : uv3;
            Fgnd = ReadPixel (Fg_M, xy);
            retval = lerp (Bgnd, Fgnd, 1.0 - Amount);
         }

         retval.a = Fgnd.a;
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      maskBg = Fgnd;
      xy = uv3;

      if (TileSize > 0.0) {
         float Xsize = max (1e-6, TileSize * sin (Amount * PI) * 0.1);
         float Ysize = Xsize * _OutputAspectRatio * Aspect;

         xy.x = (floor ((xy.x - 0.5) / Xsize) * Xsize) + 0.5;
         xy.y = (floor ((xy.y - 0.5) / Ysize) * Ysize) + 0.5;
      }

      retval = tex2D (Bg_M, xy);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Blocks

DeclarePass (Fg_C)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_C)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Tiles_C)
{
   float4 retval = tex2D (Fg_C, uv3);

   float amount = Amount * _LengthFrames / (_LengthFrames - 1.0);
   float a, b;

   retval = lerp (retval, tex2D (Bg_C, uv3), amount);
   sincos (amount * HALF_PI, a, b);
   retval.rgb = min (abs (retval.rgb - float3 (a, b, frac ((uv3.x + uv3.y) * 1.2345 + amount))), 1.0);
   retval.a   = 1.0;

   float3 x = retval.aga;

   for (int i = 0; i < 32; i++) {
      retval.rgb = SCALE * abs (retval.gbr / dot (retval.brg, retval.rgb) - x);
   }

   return retval;
}

DeclareEntryPoint (Blocks)
{
   float4 Fgnd = tex2D (Fg_C, uv3);
   float4 Bgnd = tex2D (Bg_C, uv3);
   float4 maskBg, retval = Bgnd;

   float alpha, amount;

   if (Blended) {
      if (ShowKey) return lerp (kTransparentBlack, Fgnd, Fgnd.a * tex2D (Mask, uv3).x);

      maskBg = Bgnd;
      alpha = Fgnd.a;
      amount = SwapDir ? 1.0 - Amount : Amount;
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
      Fgnd.rgb = retval.rgb;
   }
   else {
      maskBg = Fgnd;
      alpha = 1.0;
      amount = Amount;
   }

   if (alpha > 0.0) {
      amount = amount * _LengthFrames / (_LengthFrames - 1.0);

      float Tscale = TileSize * 0.2;

      float2 mosaic = float2 (1.0, _OutputAspectRatio * Aspect) * max (1.0e-6, Tscale * 0.2);
      float2 Mscale = (1.0 - Tscale) / mosaic;
      float2 xy1 = (round ((uv3 - 0.5.xx) * Mscale) * mosaic) + 0.5.xx;

      float4 gating = lerp (tex2D (Fg_C, xy1), tex2D (Bg_C, xy1), amount);

      retval = amount < 0.5 ? Fgnd : Bgnd;

      float level = max (gating.r, max (gating.g, gating.b));
      float range = abs (amount - 0.5) * 2.0;

      retval = level >= range ? tex2D (Tiles_C, xy1) : retval;
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique BreakTiles

DeclarePass (Fg_B)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_B)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Tiles_B)
{
   float4 retval;

   float2 uv = uv3;

   float amount = Amount * _LengthFrames / (_LengthFrames - 1.0);
   float dsplc  = (OFFSET - (TileSize * Aspect)) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;

   if (Blended) {
      uv.x += SwapDir ? (1.0 - offset) * (1.0 - amount) : (offset - 1.0) * amount;
      retval = ReadPixel (Fg_B, uv);
   }
   else {
      uv.x += (1.0 - offset) * (1.0 - amount);
      retval = ReadPixel (Bg_B, uv);
   }

   return retval;
}

DeclareEntryPoint (BreakTiles)
{
   float4 Fgnd = tex2D (Fg_B, uv3);
   float4 Bgnd = tex2D (Bg_B, uv3);
   float4 maskBg, retval = Bgnd;

   float2 uv = uv3;

   float amount = Amount * _LengthFrames / (_LengthFrames - 1.0);
   float dsplc  = (OFFSET - TileSize) * FACTOR;
   float offset = floor (uv.x * dsplc);

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         offset = SwapDir ? (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - amount)
                          : ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * amount;
         uv.y += offset / _OutputAspectRatio;

         retval = ReadPixel (Tiles_B, uv);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      maskBg = Fgnd;
      offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - amount);
      uv.y += offset / _OutputAspectRatio;
      retval = ReadPixel (Tiles_B, uv);
      retval = lerp (Fgnd, retval, retval.a);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique JoinTiles

DeclarePass (Fg_J)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_J)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Tiles_J)
{
   float4 retval;

   float2 uv = uv3;

   float amount = Amount * _LengthFrames / (_LengthFrames - 1.0);
   float dsplc  = (OFFSET - (TileSize * Aspect)) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;

   if (Blended) {
      uv.x += SwapDir ? (1.0 - offset) * (1.0 - amount) : (offset - 1.0) * amount;
   }
   else uv.x += (offset - 1.0) * amount;

   retval = ReadPixel (Fg_J, uv);

   return retval;
}

DeclareEntryPoint (JoinTiles)
{
   float4 Fgnd = tex2D (Fg_J, uv3);
   float4 Bgnd = tex2D (Bg_J, uv3);
   float4 maskBg, retval = Bgnd;

   float2 uv = uv3;

   float amount = Amount * _LengthFrames / (_LengthFrames - 1.0);
   float dsplc  = (OFFSET - TileSize) * FACTOR;
   float offset = floor (uv.x * dsplc);

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         offset = SwapDir ? (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - amount)
                          : ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * amount;
         uv.y += offset / _OutputAspectRatio;

         retval = ReadPixel (Tiles_J, uv);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      maskBg = Fgnd;
      offset  = ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * amount;
      uv.y += offset / _OutputAspectRatio;
      retval = ReadPixel (Tiles_J, uv);
      retval = lerp (Bgnd, retval, retval.a);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

