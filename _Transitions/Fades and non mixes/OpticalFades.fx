// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This simulates the look of the classic film optical fade to or from black.  It applies
 an exposure shift and a degree of black crush to the transition the way that the early
 optical printers did.  It isn't a transition, and requires one input only.  It must be
 applied in the same way as a title effect, i.e., by marking the region that the fade is
 to occupy.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OpticalFades.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Optical fades", "Mix", "Fades and non mixes", "Simulates the black crush effect of a film optical fade to or from black", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Type, "Fade type", kNoGroup, 0, "Fade up|Fade down");

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

DeclareEntryPoint (OpticalFades)
{
   float4 video = ReadPixel (Inp, uv1);

   float level = Type ? Amount : 1.0 - Amount;
   float alpha = max (video.a, level);

   float3 retval = pow (video.rgb, 1.0 + (level * 0.25));

   retval = lerp (retval, BLACK, level * 0.8);
   retval = saturate (retval - (level * 0.2).xxx);

   return float4 (retval, alpha);
}

