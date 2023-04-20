// @Maintainer jwrl
// @Released 2023-04-20
// @Author Nicholas Carroll
// @Created 2016-21-02

/**
 INK is an extremely good proportionate colour difference keyer.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Ink.fx
//
// Copyright 2016 Nicholas Carroll http://casanico.com
//
// INK is free software: you can redistribute it and/or modify it under the terms of
// the GNU General Public License published by the Free Software Foundation; either
// version 3 of the License, or (at your option) any later version. See
// http://www.gnu.org/licenses/gpl-3.0.html
//
// VERSION HISTORY
// 1.0  N. Carroll  2-MAY-16  First version
// 1.1  jwrl        2-MAY-16  Reworked to remove array indexing which didn't work
// 1.2  N. Carroll  4-MAY-16  Put the matte in the alpha channel.
//
// Version history:
//
// Updated 2023-01-26 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//
// Updated 2023-04-18 jwrl
// Added alpha detection to fg to bypass the effect if the image is already transparent.
//
// Updated 2023-04-20 jwrl:  Cleaned up code after above update.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("INK", "Key", "Key Extras", "INK is a quick, simple and effective proportionate colour difference keyer", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (fg, bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareColourParam (keyColor, "Key Colour", kNoGroup, kNoFlags, 0.2, 1.0, 0.0, 1.0);

DeclareFloatParam (bal, "Key Balance", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (KeyGain, "Key Gain", kNoGroup, "DisplayAsPercentage", 1.0, 0.5, 2.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FG)
{ return ReadPixel (fg, uv1); }           // Color FG

DeclarePass (BG)
{ return ReadPixel (bg, uv2); }           // Color BG

DeclareEntryPoint (Ink)
{
   float4 foreground = tex2D (FG, uv3);
   float4 background = tex2D (BG, uv3);
   float4 Ckey;

   if (IsOutOfBounds (uv1) || (foreground.a == 0.0)) { Ckey = background; }
   else {
      float3 chan, P = foreground.rgb;
      float3 K = keyColor.rgb;

      float nbal = 1 - bal;

      int minKey = 0;
      int midKey = 1;
      int maxKey = 2;

      if (keyColor.b <= keyColor.r && keyColor.r <= keyColor.g) {
         minKey = 2;
         midKey = 0;
         maxKey = 1;
         P = foreground.brg;
         K = keyColor.brg;
      }
      else if (keyColor.r <= keyColor.b && keyColor.b <= keyColor.g) {
         minKey = 0;
         midKey = 2;
         maxKey = 1;
         P = foreground.rbg;
         K = keyColor.rbg;
      }
      else if (keyColor.g <= keyColor.b && keyColor.b <= keyColor.r) {
         minKey = 1;
         midKey = 2;
         maxKey = 0;
         P = foreground.gbr;
         K = keyColor.gbr;
      }
      else if (keyColor.g <= keyColor.r && keyColor.r <= keyColor.b) {
         minKey = 1;
         midKey = 0;
         maxKey = 2;
         P = foreground.grb;
         K = keyColor.grb;
      }
      else if (keyColor.b <= keyColor.g && keyColor.g <= keyColor.r) {
         minKey = 2;
         midKey = 1;
         maxKey = 0;
         P = foreground.bgr;
         K = keyColor.bgr;
      }

      // solve minKey

      float min1 = (P.x / (P.z - bal * P.y) - K.x / (K.z - bal * K.y))
                 / (1 + P.x / (P.z - bal * P.y) - (2 - bal) * K.x / (K.z - bal * K.y));
      float min2 = min (P.x, (P.z - bal * P.y) * min1 / (1 - min1));

      if (minKey == 0) chan.r = saturate (min2);
      else if (minKey == 1) chan.g = saturate (min2);
      else chan.b = saturate (min2);

      // solve midKey

      float mid1 = (P.y / (P.z - nbal * P.x) - K.y / (K.z - nbal * K.x)) 
                 / (1 + P.y / (P.z - nbal * P.x) - (1 + bal) * K.y / (K.z - nbal * K.x));
      float mid2 = min (P.y, (P.z - nbal * P.x) * mid1 / (1 - mid1));

      if (midKey == 0) chan.r = saturate (mid2);
      else if (midKey == 1) chan.g = saturate (mid2);
      else chan.b = saturate (mid2);

      // solve chan.z (chan [maxKey])

      float max1 = min (P.z, (bal * min (P.y, (P.z - nbal * P.x) * mid1 / (1 - mid1))
                 + nbal * min (P.x, (P.z - bal * P.y) * min1 / (1 - min1))));

      if (maxKey == 0) chan.r = saturate (max1);
      else if (maxKey == 1) chan.g = saturate (max1);
      else chan.b = saturate (max1);

      // solve alpha

      float a1 = (1.0 - K.z) + (bal * K.y + (1.0 - bal) * K.x);
      float a2 = 1.0 + a1 / abs (1.0 - a1);
      float a3 = (1.0 - P.z) - P.z * (a2 - (1.0 + (bal * P.y + (1.0 - bal) * P.x) / P.z * a2));
      float a4 = max (chan.g, max (a3, chan.b));

      float matte = saturate (((a4 - 0.5) * KeyGain) + 0.5);    // alpha

      Ckey = float4 (lerp (background.rgb, chan, matte), max (background.a, matte));
   }

   return lerp (background, Ckey, tex2D (Mask, uv3).x);
}
