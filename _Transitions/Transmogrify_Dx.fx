// @Maintainer jwrl
// @Released 2023-01-30
// @Author jwrl
// @Created 2023-01-30

/**
 This is is a truly bizarre transition.  Sort of a stripy blurry dissolve, I guess.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 Unlike with LW transitions there is no mask.  Instead the ability to crop the effect
 to the background is provided, which dissolves between the cropped areas during the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transmogrify_Dx.fx
//
// Version history:
//
// Built 2023-01-30 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Transmogrify burst", "Mix", "Abstract transitions", "Breaks the outgoing image into a cloud of particles which blow apart.", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SCALE 0.000545

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Transmogrify_Dx)
{
   float2 pxS = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE ;

   float rand = frac (sin (dot (pxS, float2 (18.5475, 89.3723))) * 54853.3754);

   float2 xy1 = lerp (uv3, saturate (pxS + (sqrt (_Progress) - 0.5).xx + (uv3 * rand)), Amount);
   float2 xy  = saturate (pxS + (sqrt (1.0 - _Progress) - 0.5).xx + (uv3 * rand));
   float2 xy2 = lerp (float2 (xy.x, 1.0 - xy.y), uv3, Amount);

   float4 Fgnd = tex2D (Outgoing, xy1);
   float4 Bgnd = tex2D (Incoming, xy2);
   float4 retval = lerp (Fgnd, Bgnd, Amount);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

