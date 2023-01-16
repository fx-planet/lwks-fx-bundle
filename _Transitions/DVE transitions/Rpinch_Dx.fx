// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect pinches the outgoing video to a user-defined point to reveal the incoming
 shot.  It can also reverse the process to bring in the incoming video.  Unlike "Pinch",
 this version compresses to the diagonal radii of the images.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rpinch_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Radial pinch", "Mix", "DVE transitions", "Radially pinches the outgoing video to a user-defined point to reveal the incoming shot",CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define MID_PT  0.5.xx
#define HALF_PI 1.5707963

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Pinch to reveal|Expand to reveal");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (rPinch_0)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclareEntryPoint (rPinch_Dx_0)
{
   float progress = Amount / 2.14;
   float rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy1 = (uv3 - MID_PT) * scale;

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = ReadPixel (rPinch_0, xy1);

   return lerp (ReadPixel (Bg, uv2), retval, retval.a);
}

DeclarePass (rPinch_1)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclareEntryPoint (rPinch_Dx_1)
{
   float progress = (1.0 - Amount) / 2.14;
   float rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy1 = (uv3 - MID_PT) * scale;

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = ReadPixel (rPinch_1, xy1);

   return lerp (ReadPixel (Fg, uv1), retval, retval.a);
}
