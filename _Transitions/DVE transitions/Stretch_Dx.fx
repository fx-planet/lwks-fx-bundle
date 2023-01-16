// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 Stretches the image horizontally through the dissolve.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Stretch_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Stretch transition", "Mix", "DVE transitions", "Stretches the image horizontally through the dissolve", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (StretchMode, "Transition", kNoGroup, 0, "Stretch horizontally|Stretch vertically");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Stretch, "Stretch", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Incoming)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (Outgoing)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclareEntryPoint (Stretch_Dx)
{
   float2 xy = uv3 - 0.5.xx;

   float dissAmt = saturate (lerp (Amount, ((1.5 * Amount) - 0.25), Stretch));
   float stretchAmt = lerp (0.0, saturate (sin (Amount * PI)), Stretch);
   float distort;

   if (StretchMode == 0) {
      distort = sin (xy.y * PI);
      distort = sin (distort * HALF_PI);

      xy.y = lerp (xy.y, distort / 2.0, stretchAmt);
      xy.x /= 1.0 + (5.0 * stretchAmt);
   }
   else {
      distort = sin (xy.x * PI);
      distort = sin (distort * HALF_PI);

      xy.x = lerp (xy.x, distort / 2.0, stretchAmt);
      xy.y /= 1.0 + (5.0 * stretchAmt);
   }

   xy += 0.5.xx;

   float4 fgPix = ReadPixel (Outgoing, xy);
   float4 bgPix = ReadPixel (Incoming, xy);

   return lerp (fgPix, bgPix, dissAmt);
}

