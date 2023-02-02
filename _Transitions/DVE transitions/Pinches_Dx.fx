// @Maintainer jwrl
// @Released 2023-02-02
// @Author jwrl
// @Created 2023-02-02

/**
 This effect is a range of linear, radial and X pinches that pinch the outgoing video
 to a user-defined point to reveal the incoming shot.  It can also reverse the process
 to bring in the incoming video.

 The direction swap for the X pinch has been deliberately made asymmetric.  Subjectively
 it looked better to have the pinch established before the zoom out started, but to run
 the zoom in through the entire un-pinch process.  Trig functions are used on the effect
 progress to make the acceleration smoother.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Pinches_Dx.fx
//
// Version history:
//
// Built 2023-02-02 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Pinch transitions", "Mix", "DVE transitions", "Pinches the outgoing video to a user-defined point to reveal the incoming shot", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Linear pinch|Radial pinch|X pinch|Linear expansion|Radial expansion|X expansion");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (centreX, "Position", "End point", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (centreY, "Position", "End point", "SpecifiesPointY", 0.5, 0.0, 1.0);

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
// Code
//-----------------------------------------------------------------------------------------//

// technique Pinches_Dx_P_L (Linear pinch to reveal)

DeclarePass (Pinch_P_L)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (Bg_P_L)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Pinches_Dx_P_L)
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);
   float2 xy1 = (uv3 - centre) * (1.0 + pow ((1.0 - cos (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy1 * 2.0), -sin (Amount * HALF_PI));

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = ReadPixel (Pinch_P_L, xy1);

   return lerp (tex2D (Bg_P_L, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinches_Dx_P_R (Radial pinch to reveal)

DeclarePass (Pinch_P_R)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (Bg_P_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Pinches_Dx_P_R)
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);

   float progress = Amount / 2.14;
   float rfrnc = (distance (uv3, centre) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy1 = (uv3 - centre) * scale;

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = ReadPixel (Pinch_P_R, xy1);

   return lerp (tex2D (Bg_P_R, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinches_Dx_P_X (X pinch to reveal)

DeclarePass (Pinch_P_X)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (Bg_P_X)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Video_P_X)
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);

   float progress = sin (Amount * HALF_PI);
   float dist = (distance (uv3, centre) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy1 = ((uv3 - centre) * scale) + MID_PT;

   return ReadPixel (Pinch_P_X, xy1);
}

DeclareEntryPoint (Pinches_Dx_P_X)
{
   float progress = 1.0 - cos (max (0.0, Amount - 0.25) * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);
   float2 xy1 = ((uv3 - centre) * scale) + MID_PT;

   float4 retval = ReadPixel (Video_P_X, xy1);

   return lerp (tex2D (Bg_P_X, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinches_Dx_E_L (Linear expand to reveal)

DeclarePass (Fg_E_L)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Expand_E_L)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclareEntryPoint (Pinches_Dx_E_L)
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
   float2 xy1 = (uv3 - centre) * (1.0 + pow ((1.0 - sin (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy1 * 2.0), -cos ((Amount + 0.01) * HALF_PI));

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = ReadPixel (Expand_E_L, xy1);

   return lerp (tex2D (Fg_E_L, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinches_Dx_E_R (Radial expand to reveal)

DeclarePass (Fg_E_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Expand_E_R)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclareEntryPoint (Pinches_Dx_E_R)
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);

   float progress = (1.0 - Amount) / 2.14;
   float rfrnc = (distance (uv3, centre) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy1 = (uv3 - centre) * scale;

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = ReadPixel (Expand_E_R, xy1);

   return lerp (tex2D (Fg_E_R, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinches_Dx_E_X (X expand to reveal)

DeclarePass (Fg_E_X)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Pinch_E_X)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (Video_E_X)
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);

   float progress = cos (Amount * HALF_PI);
   float dist = (distance (uv3, centre) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy1 = ((uv3 - centre) * scale) + MID_PT;

   return ReadPixel (Pinch_E_X, xy1);
}

DeclareEntryPoint (Pinches_Dx_E_X)
{
   float progress = 1.0 - sin (Amount * HALF_PI);
   float scale    = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
   float2 xy1 = ((uv3 - centre) * scale) + MID_PT;

   float4 retval = ReadPixel (Video_E_X, xy1);

   return lerp (tex2D (Fg_E_X, uv3), retval, retval.a);
}

