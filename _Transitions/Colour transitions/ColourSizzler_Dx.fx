// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect dissolves through a complex colour translation while performing what is
 essentially a non-additive mix.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSizzler_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Colour sizzler", "Mix", "Colour transitions", "Dissolves through a complex colour translation from one clip to another", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Saturation, "Saturation", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (HueCycle, "Cycle rate", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Outgoing)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Incoming)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ColourSizzler_Dx)
{
   float4 Fgnd   = tex2D (Outgoing, uv3);
   float4 Bgnd   = tex2D (Incoming, uv3);
   float4 nonAdd = max (Fgnd * min (1.0, 2.0 * (1.0 - Amount)), Bgnd * min (1.0, 2.0 * Amount));
   float4 premix = max (Fgnd, Bgnd);

   float Alpha = premix.w;
   float Luma  = 0.1 + (0.5 * premix.x);
   float Satn  = premix.y * Saturation;
   float Hue   = frac (premix.z + (Amount * HueCycle));
   float LumX3 = 3.0 * Luma;

   float HueX3 = 3.0 * Hue;
   float Hfac  = (floor (HueX3) + 0.5) / 3.0;

   Hue = SQRT_3 * tan ((Hue - Hfac) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   float4 retval = (HueX3 < 1.0) ? float4 (Green, Blue, Red, Alpha)
                 : (HueX3 < 2.0) ? float4 (Red, Green, Blue, Alpha)
                                 : float4 (Blue, Red, Green, Alpha);

   float mixval = abs (2.0 * (0.5 - Amount));

   mixval *= mixval;

   return lerp (retval, nonAdd, mixval);
}

