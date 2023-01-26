// @Maintainer jwrl
// @Released 2023-01-26
// @Author jwrl
// @Created 2023-01-26

/**
 This is a simple keyer that has only five adjustments, the key colour, key clip, key
 gain and the defringe controls.  Defringing can either use the standard desaturate
 technique, or can replace the key colour with the background image either in colour
 or monochrome.  Finally, the key can be faded in and out by adjusting the opacity.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleChromakey.fx
//
// Version history:
//
// Built 2023-01-26 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Simple chromakey", "Key", "Key Extras", "An extremely simple chromakeyer with feathering and spill reduction", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareColourParam (Colour, "Key colour", kNoGroup, kNoFlags, 0.0, 1.0, 0.0, 1.0);

DeclareFloatParam (Clip, "Key clip", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Gain, "Key gain", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Size, "Feather", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (DefringeType, "Defringe technique", kNoGroup, 0, "Desaturate fringe|Use background (monochrome)|Use background (colour)");

DeclareFloatParam (DeFringeAmt, "Defringe amount", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (DeFringe, "Defringe depth", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define BdrPixel(SHADER,XY) (IsOutOfBounds(XY) ? BLACK : tex2D(SHADER, XY))

#define LUMACONV float3(0.2989, 0.5866, 0.1145)

#define LOOP   12
#define DIVIDE 24

#define RADIUS 0.002
#define ANGLE  0.2617993878

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Key_1)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   float cDiff = distance (Colour.r, Fgnd.r);

   cDiff = max (cDiff, distance (Colour.g, Fgnd.g));
   cDiff = max (cDiff, distance (Colour.b, Fgnd.b));

   float alpha = smoothstep (Clip, Clip + Gain, cDiff);

   return float4 (alpha.xxx, Fgnd.a);
}

DeclarePass (Key_2)
{
   float4 retval = tex2D (Key_1, uv3);
   float4 Fgnd = ReadPixel (Fg, uv1);

   float alpha = retval.r;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      alpha += tex2D (Key_1, uv3 + xy).r;
      alpha += tex2D (Key_1, uv3 - xy).r;
      xy += xy;
      alpha += tex2D (Key_1, uv3 + xy).r;
      alpha += tex2D (Key_1, uv3 - xy).r;
   }

   alpha = saturate ((alpha / DIVIDE) - 1.0);
   Fgnd.a = min (Fgnd.a, alpha);

   return IsOutOfBounds (uv1) ? kTransparentBlack : Fgnd;
}

DeclareEntryPoint (SimpleChromakey)
{
   float4 Fgnd = tex2D (Key_2, uv3);
   float4 Bgnd = BdrPixel (Bg, uv2);

   float3 Frng = Fgnd.rgb;
   float3 Ref = DefringeType == 0 ? dot (Fgnd, LUMACONV).xxx
              : DefringeType == 1 ? dot (Bgnd, LUMACONV).xxx : Bgnd.rgb;

   float cMask;

   if (Colour.g >= max (Colour.r, Colour.b)) {
      cMask = saturate (Frng.g - lerp (Frng.r, Frng.b, DeFringe));
      Frng.g -= cMask;
   }
   else if (Colour.b >= max (Colour.r, Colour.g)) {
      cMask = saturate (Frng.b - lerp (Frng.r, Frng.g, DeFringe));
      Frng.b -= cMask;
   }
   else {
      cMask = saturate (Frng.r - lerp (Frng.g, Frng.b, DeFringe));
      Frng.r -= cMask;
   }

   Frng += Ref * cMask;

   Fgnd.rgb = lerp (Fgnd.rgb, Frng, DeFringeAmt);
   Fgnd.a  *= Amount;

   return lerp (Bgnd, Fgnd, Fgnd.a * tex2D (Mask, uv3).x);
}

