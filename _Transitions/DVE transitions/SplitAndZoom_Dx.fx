// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect splits the outgoing video horizontally or vertically to reveal the incoming
 shot, which zooms up out of an opaque black background.  It is a rewrite of an earlier
 effect, H split with zoom, which has been withdrawn.  Instead of the colour background
 provided with the earlier effect transparent black has been used.  This gives maximum
 flexibility when using aspect ratios that don't match the sequence.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SplitAndZoom_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Split and zoom", "Mix", "DVE transitions", "Splits the outgoing video to reveal the incoming shot zooming out of black", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Split horizontally|Split vertically");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK float2(0.0, 1.0).xxxy

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing_H)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (Incoming_H)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclareEntryPoint (SplitAndZoom_Dx_H)
{
   float pos = Amount / 2.0;

   float2 xy1 = uv3;
   float2 xy2 = ((uv3 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;

   float4 retval;

   if ((uv3.x < pos + 0.5) && (uv3.x > 0.5 - pos))
      retval = ReadPixel (Outgoing_H, xy2);
   else {
      if (uv3.x > 0.5) xy1.x -= pos;
      else xy1.x += pos;

      retval = ReadPixel (Incoming_H, xy1);
   }

   return retval;
}

DeclarePass (Outgoing_V)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (Incoming_V)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclareEntryPoint (SplitAndZoom_Dx_V)
{
   float pos = Amount / 2.0;

   float2 xy1 = uv3;
   float2 xy2 = ((uv3 - 0.5.xx) * (2.0 - sin (Amount * HALF_PI))) + 0.5.xx;

   float4 retval;

   if ((uv3.y < pos + 0.5) && (uv3.y > 0.5 - pos))
      retval = ReadPixel (Outgoing_V, xy2);
   else {
      if (uv3.y > 0.5) xy1.y -= pos;
      else xy1.y += pos;

      retval = ReadPixel (Incoming_V, xy1);
   }

   return retval;
}

