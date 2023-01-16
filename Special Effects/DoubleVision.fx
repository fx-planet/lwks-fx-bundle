// @Maintainer jwrl
// @Released 2023-01-11
// @Author jwrl
// @Created 2023-01-11

/**
 Double vision gives a blurry double vision effect suitable for removing glasses or drunken
 or head punch effects.  The blur adjustment is scaled by the displacement amount, so that
 when the amount reaches zero the blur does also.  The displacement is produced by scaling
 the video slightly in the X direction, ensuring that no edge artefacts are visible.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DoubleVision.fx
//
// Version history:
//
// Built 2023-01-11 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Double vision", "Stylize", "Special Effects", "Gives a blurry double vision effect suitable for impaired vision POVs", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Blurriness, "Blurriness", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LOOP   12
#define DIVIDE 49

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Input)
{ return ReadPixel (Inp, uv1); }

DeclarePass (Blur)
{
   float2 uv = uv2 + (0.5 / float2 (_OutputWidth, _OutputHeight));

   float4 retval = tex2D (Input, uv);

   if (Amount > 0.0) {

      float2 xy = 0.0.xx;
      float2 spread = float2 (Amount * Blurriness * 0.00075, 0.0);

      for (int i = 0; i < LOOP; i++) {
         xy += spread;
         retval += tex2D (Input, uv + xy);
         retval += tex2D (Input, uv - xy);
         xy += spread;
         retval += tex2D (Input, uv + xy);
         retval += tex2D (Input, uv - xy);
      }

      retval /= DIVIDE;
   }

   return retval;
}

DeclareEntryPoint (DoubleVision)
{
   float2 uv = uv2 + (0.5 / float2 (_OutputWidth, _OutputHeight));

   float4 retval = tex2D (Input, uv);

   if (Amount <= 0.0) return retval;

   float split = (0.05 * Amount) + 1.0;

   float2 xy1 = float2 (uv.x / split, uv.y);
   float2 xy2 = float2 (1.0 - ((1.0 - uv.x) / split), uv.y);

   return lerp (kTransparentBlack, lerp (tex2D (Blur, xy1), tex2D (Blur, xy2), 0.5), retval.a);
}

