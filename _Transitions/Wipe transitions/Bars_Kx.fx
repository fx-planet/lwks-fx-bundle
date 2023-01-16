// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is a transition that moves the strips of a blended foreground together from off-screen
 either horizontally or vertically or splits it into strips then blows them apart either
 horizontally or vertically.  Useful for applying transitions to titles.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bars_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bar wipe (keyed)", "Mix", "Wipe transitions", "Splits a foreground image into strips which separate horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (SetTechnique, "Transition direction", kNoGroup, 0, "Horizontal|Vertical");

DeclareFloatParam (Width, "Bar width", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define WIDTH  50
#define OFFSET 1.2

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = tex2D (F, xy1);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (B, xy2);
      }
      else Bgnd = tex2D (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Bars_H

DeclarePass (Super_H)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Bars_H)
{
   float4 Bgnd;

   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 bgd, offset = float2 (0.0, floor (uv1.y * dsplc));
   float2 xy = (Ttype == 2) ? uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_H, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Bars_V

DeclarePass (Super_V)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Bars_V)
{
   float4 Bgnd;

   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 bgd, offset = float2 (floor (uv3.x * dsplc), 0.0);
   float2 xy = (Ttype == 2) ? uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   if (Ttype == 0) {
      bgd = uv1;
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      bgd = uv2;
      Bgnd = ReadPixel (Bg, uv2);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_V, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

