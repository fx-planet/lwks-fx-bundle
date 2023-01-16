// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is is a truly bizarre transition.  Sort of a stripy blurry dissolve, I guess.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transmogrify_Dx_2022.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Transmogrify burst 2022+", "Mix", "Abstract transitions", "Breaks the outgoing image into a cloud of particles which blow apart.", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

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

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint ()
{
   float2 pxS = uv3 * float2 (1.0, _OutputAspectRatio) * SCALE ;

   float rand = frac (sin (dot (pxS, float2 (18.5475, 89.3723))) * 54853.3754);

   float2 xy1 = lerp (uv3, saturate (pxS + (sqrt (_Progress) - 0.5).xx + (uv3 * rand)), Amount);
   float2 xy  = saturate (pxS + (sqrt (1.0 - _Progress) - 0.5).xx + (uv3 * rand));
   float2 xy2 = lerp (float2 (xy.x, 1.0 - xy.y), uv3, Amount);

   float4 Fgnd = tex2D (Fgd, xy1);
   float4 Bgnd = tex2D (Bgd, xy2);

   return lerp (Fgnd, Bgnd, Amount);
}

