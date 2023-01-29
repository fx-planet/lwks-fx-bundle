// @Maintainer jwrl
// @Released 2023-01-29
// @Author jwrl
// @Created 2023-01-29

/**
 This is a transition that sunders the central area of the outgoing image from the
 background and pushes it to reveal the incoming media.  At the same time the whole
 background also pushes to reveal the incoming media.  Each can be pushed left, right,
 up or down, and the centre area of the background can optionally be blanked.  The
 various combinations amount to a possible total of 32 variants.

 As well, the background can be reduced in level as the transition takes place to
 help separate it from the centre.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sunder_Dx.fx
//
// Version history:
//
// Built 2023-01-29 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sunder", "Mix", "Wipe transitions", kNoNotes, CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam (BlankCentre, "Blank centre area in outer", kNoGroup, false);

DeclareIntParam (CentrePan, "Center direction", kNoGroup, 0, "Pan left|Pan right|Tilt up|Tilt down");
DeclareIntParam (OuterPan, "Outer direction", kNoGroup, 0, "Pan left|Pan right|Tilt up|Tilt down");

DeclareFloatParam (DarkenOuter, "Outer levels", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.141593
#define TWO_PI 6.283185

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool Boxed (float2 xy)
{
   return (abs (xy.x - 0.5) < 0.25) && (abs (xy.y - 0.5) < 0.25);
}

float4 CentreLeft (sampler F, sampler B, float2 xy)
{
   xy.x += Amount * 0.5;

   return xy.x <= 0.75 ? tex2D (F, xy) : tex2D (B, float2 (xy.x - 0.5, xy.y));
}

float4 CentreRight (sampler F, sampler B, float2 xy)
{
   xy.x -= Amount * 0.5;

   return xy.x > 0.25 ? tex2D (F, xy) : tex2D (B, float2 (xy.x + 0.5, xy.y));
}

float4 CentreUp (sampler F, sampler B, float2 xy)
{
   xy.y += Amount * 0.5;

   return xy.y <= 0.75 ? tex2D (F, xy) : tex2D (B, float2 (xy.x, xy.y - 0.5));
}

float4 CentreDown (sampler F, sampler B, float2 xy)
{
   xy.y -= Amount * 0.5;

   return xy.y > 0.25 ? tex2D (F, xy) : tex2D (B, float2 (xy.x, xy.y + 0.5));
}

float4 OuterLeft (sampler F, sampler B, float2 xy)
{
   xy.x += Amount;

   return IsOutOfBounds (xy) ? tex2D (B, float2 (xy.x - 1.0, xy.y)) : tex2D (F, xy);
}

float4 OuterRight (sampler F, sampler B, float2 xy)
{
   xy.x -= Amount;

   return IsOutOfBounds (xy) ? tex2D (B, float2 (xy.x + 1.0, xy.y)) : tex2D (F, xy);
}

float4 OuterUp (sampler F, sampler B, float2 xy)
{
   xy.y += Amount;

   return IsOutOfBounds (xy) ? tex2D (B, float2 (xy.x, xy.y - 1.0)) : tex2D (F, xy);
}

float4 OuterDown (sampler F, sampler B, float2 xy)
{
   xy.y -= Amount;

   return IsOutOfBounds (xy) ? tex2D (B, float2 (xy.x, xy.y + 1.0)) : tex2D (F, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg_C)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_C)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Fg_O)
{
   float4 retval = BlankCentre && Boxed (uv3) ? kTransparentBlack : ReadPixel (Fg, uv1);

   float gain_adjust = Amount > 0.5 ? 0.0 : (1.0 + cos (Amount * TWO_PI)) * 0.5;

   retval.rgb *= lerp (DarkenOuter, 1.0, gain_adjust);

   return retval;
}

DeclarePass (Bg_O)
{
   float4 retval = BlankCentre && Boxed (uv3) ? kTransparentBlack : ReadPixel (Bg, uv2);

   float gain_adjust = Amount < 0.5 ? 0.0 : (1.0 + cos (Amount * TWO_PI)) * 0.5;

   retval.rgb *= lerp (DarkenOuter, 1.0, gain_adjust);

   return retval;
}

DeclareEntryPoint (Sunder)
{
   if (Boxed (uv3)) return CentrePan == 0 ? CentreLeft (Fg_C, Bg_C, uv3)
                         : CentrePan == 1 ? CentreRight (Fg_C, Bg_C, uv3)
                         : CentrePan == 2 ? CentreUp (Fg_C, Bg_C, uv3)
                         : CentreDown (Fg_C, Bg_C, uv3);

   return OuterPan == 0 ? OuterLeft (Fg_O, Bg_O, uv3)
        : OuterPan == 1 ? OuterRight (Fg_O, Bg_O, uv3)
        : OuterPan == 2 ? OuterUp (Fg_O, Bg_O, uv3) : OuterDown (Fg_O, Bg_O, uv3);
}

