// @Maintainer jwrl
// @Released 2023-01-19
// @Author jwrl
// @Released 2023-01-19

/**
 This effect is a flexible vignette with the ability to apply a range of masks using
 the Lightworks mask effect.  The edges of the mask can be bordered with a bicolour
 shaded surround as a percentage of the edge softness.  Drop shadowing of the mask
 is included, and is set as an offset percentage.

 Because using the mask opacity to fade the foreground will give ugly results when
 a border is used, the master opacity is the best way to fade the effect out.  If
 the mask invert function is used the border colours will swap and the drop shadow
 will appear inside the mask.  To stop this happening you should use the master
 invert function.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Flexicrop.fx
//
// Version history:
//
// Built 2023-01-19 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Flexible crop", "DVE", "Border and Crop", "A flexible bordered crop", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Invert, "Invert effect", kNoGroup, false);

DeclareBoolParam (UseBorder, "Use border", "Border", true);

DeclareFloatParam (bStrength, "Strength", "Border", kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (BorderColour, "Inner colour", "Border", kNoFlags, 0.2, 0.8, 0.8, 1.0);
DeclareColourParam (BorderColour_1, "Outer colour", "Border", kNoFlags, 0.2, 0.1, 1.0, 1.0);

DeclareBoolParam (UseShadow, "Use drop shadow", "Drop shadow", true);

DeclareFloatParam (sStrength, "Strength", "Drop shadow", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (ShadowX, "Offset", "Drop shadow", "SpecifiesPointX|DisplayAsPercentage", 0.525, 0.4, 0.6);
DeclareFloatParam (ShadowY, "Offset", "Drop shadow", "SpecifiesPointY|DisplayAsPercentage", 0.475, 0.4, 0.6);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0,1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (cFg)
{ return Invert ? ReadPixel (Bg, uv2) : ReadPixel (Fg, uv1); }

DeclarePass (cBg)
{ return Invert ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Flexicrop)
{
   float4 Fgd = ReadPixel (cFg, uv3);
   float4 Bgd = ReadPixel (cBg, uv3);

   float2 xy1 = uv3 - float2 (ShadowX - 0.5, (0.5 - ShadowY) * _OutputAspectRatio);

   float Mraw = tex2D (Mask, uv3).g;
   float Sraw = tex2D (Mask, xy1).g;

   if (UseBorder) {
      float width = 1.5 * Mraw;
      float innerBorder = lerp (1.0, saturate (width - 0.5), bStrength);
      float borderWidth = lerp (1.0, saturate ((width * 2.0) - 1.0), bStrength);

      float4 colour = lerp (BorderColour_1, BorderColour, borderWidth);

      Fgd  = lerp (colour, Fgd, innerBorder);
      Mraw = lerp (Mraw, saturate (width), bStrength);
      Sraw = lerp (Sraw, saturate (1.5 * Sraw), bStrength);
   }

   float4 retval = UseShadow ? lerp (Bgd, BLACK, Sraw * sStrength) : Bgd;

   return lerp (Bgd, lerp (retval, Fgd, Mraw), Opacity);
}

