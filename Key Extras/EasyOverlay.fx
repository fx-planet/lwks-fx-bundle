// @Maintainer jwrl
// @Released 2023-01-27
// @Author hugly
// @Author schrauber
// @Created 2019-08-09

/**
 'Easy overlay' is a luminance keyer for overlays which show luminance for transparency,
 i.e. full transparency appears as solid black in the overlay.  The keyer works also on
 overlays with an alpha channel.  It reveals transparency using a black&white mask created
 from the foreground.

 The presets should work for most material of that kind with good looking results. If
 adjustments should be necessary, start with 'MaskGain'.  'Fg Lift' influences overall
 brightness of the overlay while preserving highlights.  'Fg Opacity' is e.g. useful to
 dissolve from/to the overlay using keyframes.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EasyOverlay_2022.fx
//
// Version history:
//
// Updated 2023-01-27 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Easy overlay", "Key", "Key Extras", "For overlays where luminance represents transparency", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (fg, bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (MaskGain, "Mask Gain", kNoGroup, kNoFlags, 3.0, 0.0, 6.0);
DeclareFloatParam (FgLift, "Fg Lift", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (FgOpacity, "Fg Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 setFgLift (float4 x)
{
   float lift = FgLift * 0.55;

   float3 gamma1 = 1.0 - pow (1.0 - x.rgb, 1.0 / max ((1.0 - lift), 1E-6));
   float3 gamma2 =       pow (x.rgb , 1.0      / max (lift + 1.0, 1E-6));
   float3 gamma = (lift > 0) ? gamma1 : gamma2;

   gamma =  saturate (lerp ( gamma , (gamma1 + gamma2) / 2.0, 0.8));

   return float4 (gamma.rgb, x.a);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FG)
{ return ReadPixel (fg, uv1); }

DeclareEntryPoint (EasyOverlay)
{
   float4 Fgd  = ReadPixel (FG, uv3);
   float4 Bgd  = IsOutOfBounds (uv2) ? BLACK : tex2D (bg, uv2);
   float4 mask = Fgd;

   Fgd = setFgLift (Fgd);

   float alpha = mask.a * min (((mask.r + mask.g + mask.b) / 3.0) * MaskGain, 1.0);

   float4 ret = lerp (Bgd, Fgd, alpha * FgOpacity);

   ret.a = 1.0;

   return lerp (Bgd, ret, tex2D (Mask, uv3).x);
}

