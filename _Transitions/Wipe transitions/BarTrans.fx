// @Maintainer jwrl
// @Released 2023-08-02
// @Author jwrl
// @Created 2018-06-11

/**
 This is a transition that moves the strips of a blended foreground together from
 off-screen either horizontally or vertically or splits that foreground into strips
 then blows those apart either horizontally or vertically.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BarTrans.fx
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
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bar transition", "Mix", "Wipe transitions", "Splits a foreground image into strips which separate horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition direction", kNoGroup, 0, "Horizontal|Vertical");

DeclareFloatParam (Width, "Bar width", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

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

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (SwapSource) {
      Bgnd = Fgnd;
      Fgnd = ReadPixel (B, xy2);
   }
   else Bgnd = ReadPixel (B, xy2);

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Bars_H

DeclarePass (Fg_H)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_H)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Bars_H)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_H, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float dsplc  = (OFFSET - Width) * WIDTH;

      float2 offset = float2 (0.0, floor (uv3.y * dsplc));
      float2 xy = SwapDir ? uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount)
                          : uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount;

      Bgnd = tex2D (Bg_H, uv3);
      Fgnd = ReadPixel (Fg_H, xy);
   }

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Bars_V

DeclarePass (Fg_V)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_V)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Bars_V)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_H, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float dsplc  = (OFFSET - Width) * WIDTH;

      float2 offset = float2 (floor (uv3.x * dsplc), 0.0);
      float2 xy = SwapDir ? uv3 + (1.0.xx - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount)
                          : uv3 + ((ceil (frac (offset / 2.0)) * 2.0) - 1.0.xx) * Amount;

      Bgnd = tex2D (Bg_V, uv3);
      Fgnd = ReadPixel (Fg_V, xy);
   }

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

