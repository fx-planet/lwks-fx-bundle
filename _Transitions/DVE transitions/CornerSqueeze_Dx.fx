// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This is based on the corner wipe effect, modified to squeeze or expand the divided
 section of the frame.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerSqueeze_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Corner squeeze", "Mix", "DVE transitions", "A corner wipe effect that squeezes or expands the divided section of the frame", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Squeeze to corners|Expand from corners");

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique CornerSqueeze_Dx_0

DeclarePass (SqzOut)
{ return IsOutOfBounds (uv1) ? BLACK : tex2D (Fg, uv1); }

DeclarePass (Bg_0)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Video_0)
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 ((uv3.x - Amount) / negAmt, uv3.y);
   float2 xy2 = float2 (uv3.x / negAmt, uv3.y);

   negAmt /= 2.0;

   return (uv3.x > posAmt) ? tex2D (SqzOut, xy1) : (uv3.x < negAmt)
                           ? tex2D (SqzOut, xy2) : kTransparentBlack;
}

DeclareEntryPoint (CornerSqueeze_Dx_0)
{
   float negAmt = 1.0 - Amount;
   float posAmt = (1.0 + Amount) / 2.0;

   float2 xy1 = float2 (uv3.x, (uv3.y - Amount) / negAmt);
   float2 xy2 = float2 (uv3.x, uv3.y / negAmt);

   negAmt /= 2.0;

   float4 retval = (uv3.y > posAmt) ? tex2D (Video_0, xy1) : (uv3.y < negAmt)
                                    ? tex2D (Video_0, xy2) : kTransparentBlack;

   return lerp (tex2D (Bg_0, uv3), retval, retval.a);
}


// technique CornerSqueeze_Dx_1

DeclarePass (Fg_1)
{ return ReadPixel (Fg, uv1); }

DeclarePass (SqzIn)
{ return IsOutOfBounds (uv2) ? BLACK : tex2D (Bg, uv2); }

DeclarePass (Video_1)
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 ((uv3.x + Amount - 1.0) / Amount, uv3.y);
   float2 xy2 = float2 (uv3.x / Amount, uv3.y);

   return (uv3.x > posAmt) ? tex2D (SqzIn, xy1) : (uv3.x < negAmt)
                           ? tex2D (SqzIn, xy2) : kTransparentBlack;
}

DeclareEntryPoint (CornerSqueeze_Dx_1)
{
   float negAmt = Amount / 2.0;
   float posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
   float2 xy2 = float2 (uv3.x, uv3.y / Amount);

   float4 retval = (uv3.y > posAmt) ? tex2D (Video_1, xy1) : (uv3.y < negAmt)
                                    ? tex2D (Video_1, xy2) : kTransparentBlack;

   return lerp (ReadPixel (Fg_1, uv3), retval, retval.a);
}

