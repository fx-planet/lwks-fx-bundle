// @Maintainer jwrl
// @Released 2023-06-14
// @Author jwrl
// @Created 2021-06-04

/**
 This effect splits the outgoing video horizontally or vertically to reveal the incoming
 shot, which zooms up out of an opaque black background.  Instead of the colour background
 provided in an earlier version of this effect transparent black has been used.  This
 gives maximum flexibility when using aspect ratios that don't match the sequence.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SplitAndZoomTrans.fx
//
// Version history:
//
// Updated 2023-06-14 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
// Changed subcategory from "DVE transitions" to "Transform transitions".
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Split and zoom transition", "Mix", "Transform transitions", "Splits the outgoing video to reveal the incoming shot zooming out of black", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Split horizontally|Split vertically");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique SpinAndZoom_Dx (pinch to reveal)

DeclarePass (Fg_H)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_H)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (SplitAndZoom_Dx_H)
{
   float pos = Amount / 2.0;

   float2 xy1 = uv3;
   float2 xy2 = ((uv3 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;

   float4 retval;

   if ((uv3.x < pos + 0.5) && (uv3.x > 0.5 - pos))
      retval = ReadPixel (Bg_H, xy2);
   else {
      if (uv3.x > 0.5) xy1.x -= pos;
      else xy1.x += pos;

      retval = ReadPixel (Fg_H, xy1);
   }

   return lerp (tex2D (Fg_H, uv3), retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique SpinAndZoom_Dx (expand to reveal)

DeclarePass (Fg_V)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_V)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (SplitAndZoom_Dx_V)
{
   float pos = Amount / 2.0;

   float2 xy1 = uv3;
   float2 xy2 = ((uv3 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;

   float4 retval;

   if ((uv3.y < pos + 0.5) && (uv3.y > 0.5 - pos))
      retval = ReadPixel (Bg_V, xy2);
   else {
      if (uv3.y > 0.5) xy1.y -= pos;
      else xy1.y += pos;

      retval = ReadPixel (Fg_V, xy1);
   }

   return lerp (tex2D (Fg_V, uv3), retval, tex2D (Mask, uv3).x);
}

