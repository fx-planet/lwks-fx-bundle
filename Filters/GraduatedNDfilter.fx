// @Maintainer jwrl
// @Released 2023-01-10
// @Author khaver
// @Created 2014-07-10

/**
 Original effect by khaver, this is a neutral density filter which can be tinted, and its
 blend modes can be adjusted.  Select vertical or horizontal, flip the gradient, adjust
 strength and use the on-screen handles to move where the gradient starts and ends.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GraduatedNDFilter.fx
//
// Version history:
//
// Updated 2023-01-10 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Graduated ND Filter", "Stylize", "Filters", "A tintable neutral density filter which can have its blend modes adjusted", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Direction, "Direction", kNoGroup, 0, "Vertical|Horizontal");

DeclareBoolParam (Flip, "Flip", kNoGroup, false);

DeclareIntParam (Mode, "Blend mode", kNoGroup, 2, "Add|Subtract|Multiply|Screen|Overlay|Soft Light|Hard Light|Exclusion|Lighten|Darken|Difference|Burn");

DeclareColourParam (Tint, "Tint", kNoGroup, kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareFloatParam (Mixit, "Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (SX, "Start", kNoGroup, "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (SY, "Start", kNoGroup, "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (EX, "End", kNoGroup, "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (EY, "End", kNoGroup, "SpecifiesPointY", 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (GraduatedNDFilter)
{
   float h1 = SX;
   float h2 = EX;

   float v1 = 1.0 - SY;
   float v2 = 1.0 - EY;

   float left = 0.0;
   float right = 1.0;
   float top = 1.0;
   float bottom = 0.0;

   float4 orig = tex2D (Input, uv1);

   float3 bg = orig.rgb;
   float3 fg = Tint.rgb;
   float3 newc, outc;

   if (Mode == 0) newc = saturate (bg + fg);       // Add
   else if (Mode == 1) newc = saturate (bg - fg);  // Subtract
   else if (Mode == 2) newc = bg * fg;             // Multiply
   else if (Mode == 3) newc = 1.0.xxx - ((1.0.xxx - fg) * (1.0.xxx - bg)); // Screen
   else if (Mode == 4) {                           // Overlay
      newc.r = bg.r < 0.5 ? 2.0 * fg.r * bg.r : 1.0 - (2.0 * (1.0 - fg.r) * (1.0 - bg.r));
      newc.g = bg.g < 0.5 ? 2.0 * fg.g * bg.g : 1.0 - (2.0 * (1.0 - fg.g) * (1.0 - bg.g));
      newc.b = bg.b < 0.5 ? 2.0 * fg.b * bg.b : 1.0 - (2.0 * (1.0 - fg.b) * (1.0 - bg.b));
   }
   else if (Mode == 5) newc = ((1.0.xxx - bg) * fg * bg) + (bg * (1.0.xxx - ((1.0.xxx - bg) * (1.0.xxx - fg))));  // Soft Light
   else if (Mode == 6) {                           // Hard Light
      newc.r = fg.r < 0.5 ? 2.0 * fg.r * bg.r : 1.0 - (2.0 * (1.0 - fg.r) * (1.0 - bg.r));
      newc.g = fg.g < 0.5 ? 2.0 * fg.g * bg.g : 1.0 - (2.0 * (1.0 - fg.g) * (1.0 - bg.g));
      newc.b = fg.b < 0.5 ? 2.0 * fg.b * bg.b : 1.0 - (2.0 * (1.0 - fg.b) * (1.0 - bg.b));
   }
   else if (Mode == 7) newc = fg + bg - (2.0 * fg * bg); // Exclusion
   else if (Mode == 8) newc = max (fg, bg);        // Lighten
   else if (Mode == 9) newc = min (fg, bg);        // Darken
   else if (Mode == 10) newc = abs (fg - bg);      // Difference
   else if (Mode == 11) newc = saturate (1.0.xxx - ((1.0.xxx - fg) / bg)); // Burn

   float deltv = abs (EY - SY);
   float delth = abs (EX - SX);

   if (Flip) {
      if (Direction == 0) {
         outc = uv1.y < v1 ? bg
              : uv1.y > v2 ? newc : lerp (newc, bg, (v2 - uv1.y) / deltv);
      }
      else outc = uv1.x < h1 ? bg
                : uv1.x > h2 ? newc : lerp (bg, newc, (uv1.x - h1) / delth);
   }
   else if (Direction == 0) {
      outc = uv1.y < v1 ? newc
           : uv1.y > v2 ? bg : lerp (bg, newc, (v2 - uv1.y) / deltv);
      }
   else outc = uv1.x < h1 ? newc
             : uv1.x > h2 ? bg : lerp (newc, bg, (uv1.x - h1) / delth);

   outc = lerp (kTransparentBlack, outc, orig.a);

   return lerp (orig, float4 (outc, orig.a), Mixit);
}

