// @Maintainer jwrl
// @Released 2023-01-29
// @Author jwrl
// @Created 2023-01-29

/**
 This is a transition that moves the strips of a blended foreground together from off-screen
 either horizontally or vertically or splits it into strips then blows them apart either
 horizontally or vertically.  Useful for applying transitions to titles.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bars_Kx.fx
//
// Version history:
//
// Built 2023-01-29 jwrl.
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

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Bgnd, Fgnd = tex2D (F, xy);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (B, xy);
      }
      else Bgnd = tex2D (B, xy);

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

DeclarePass (Fg_H)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_H)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_H)
{ return fn_keygen (Fg_H, Bg_H, uv3); }

DeclareEntryPoint (Bars_H)
{
   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 bg, offset = float2 (0.0, floor (uv3.y * dsplc));
   float2 xy = (Ttype == 2) ? uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_H, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_H, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_H, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Bars_V

DeclarePass (Fg_V)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_V)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_V)
{ return fn_keygen (Fg_V, Bg_V, uv3); }

DeclareEntryPoint (Bars_V)
{
   float dsplc  = (OFFSET - Width) * WIDTH;

   float2 bg, offset = float2 (floor (uv3.x * dsplc), 0.0);
   float2 xy = (Ttype == 2) ? uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount
                            : uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);
   float4 Bgnd;

   if (Ttype == 0) {
      bg = uv1;
      Bgnd = tex2D (Fg_V, uv3);
   }
   else {
      bg = uv2;
      Bgnd = tex2D (Bg_V, uv3);
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bg)) ? kTransparentBlack : tex2D (Super_V, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

