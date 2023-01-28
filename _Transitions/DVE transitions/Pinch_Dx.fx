// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This effect pinches the outgoing video to a user-defined point to reveal the incoming
 shot.  It can also reverse the process to bring in the incoming video.  A really
 simple effect, it makes no claim to be anything much.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Pinch_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Pinch transition", "Mix", "DVE transitions", "Pinches the outgoing video to a user-defined point to reveal the incoming shot", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Pinch to reveal|Expand to reveal");

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
// Shaders
//-----------------------------------------------------------------------------------------//

// technique Pinch_Dx (pinch to reveal)

DeclarePass (Pinch_0)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (Bg_0)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Pinch_Dx_0)
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);
   float2 xy1 = (uv3 - centre) * (1.0 + pow ((1.0 - cos (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy1 * 2.0), -sin (Amount * HALF_PI));

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = tex2D (Pinch_0, xy1);

   return lerp (tex2D (Bg_0, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Pinch_Dx (expand to reveal)

DeclarePass (Fg_1)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Pinch_1)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclareEntryPoint (Pinch_Dx_1)
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
   float2 xy1 = (uv3 - centre) * (1.0 + pow ((1.0 - sin (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy1 * 2.0), -cos ((Amount + 0.01) * HALF_PI));

   xy1 *= scale;
   xy1 += MID_PT;

   float4 retval = tex2D (Pinch_1, xy1);

   return lerp (tex2D (Fg_1, uv3), retval, retval.a);
}

