// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect pinches the outgoing video to a user-defined point to reveal the incoming
 shot, while zooming out of the pinched image.  It can also reverse the process to bring
 in the incoming video.

 The direction swap has been deliberately made asymmetric.  Subjectively it looked better
 to have the pinch established before the zoom out started, but to run the zoom in through
 the entire un-pinch process.  Trig functions are used on the effect progress to make the
 acceleration smoother.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Xpinch_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("X-pinch", "Mix", "DVE transitions", "Pinches the outgoing video to an X-shape then a user-defined point to reveal the incoming shot", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Pinch to reveal|Expand to reveal");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

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
// Shaders
//-----------------------------------------------------------------------------------------//

// technique xPinch_Dx_0

DeclarePass (Pinch_0)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (Video_0)
{
   float progress = sin (Amount * HALF_PI);
   float dist = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy1 = ((uv3 - MID_PT) * scale) + MID_PT;

   return ReadPixel (Pinch_0, xy1);
}

DeclareEntryPoint (xPinch_Dx_0)
{
   float progress = 1.0 - cos (max (0.0, Amount - 0.25) * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy1 = ((uv3 - MID_PT) * scale) + MID_PT;

   float4 retval = tex2D (Video_0, xy1);

   return lerp (ReadPixel (Bg, uv2), retval, retval.a);
}


// technique xPinch_Dx_1

DeclarePass (Pinch_1)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (Video_1)
{
   float progress = cos (Amount * HALF_PI);
   float dist = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy1 = ((uv3 - MID_PT) * scale) + MID_PT;

   return ReadPixel (Pinch_1, xy1);
}

DeclareEntryPoint (xPinch_Dx_1)
{
   float progress = 1.0 - sin (Amount * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy1 = ((uv3 - MID_PT) * scale) + MID_PT;

   float4 retval = tex2D (Video_1, xy1);

   return lerp (ReadPixel (Fg, uv1), retval, retval.a);
}

