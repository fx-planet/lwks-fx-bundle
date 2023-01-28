// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This mimics the Photoshop angled brush stroke effect to transition between two shots.
 The stroke length and angle can be independently adjusted, and can be keyframed while
 the transition happens to make the effect more dynamic.  To minimise edge of frame
 problems mirror addressing has been used for processing.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrush_Dx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dry brush mix", "Mix", "Art transitions", "Uses an angled brush stroke effect to transition between two shots", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Length, "Stroke length", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle, "Stroke angle", kNoGroup, kNoFlags, 45.0, -180.0, 180.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_rnd (float2 uv)
{
   return frac (sin (dot (uv, float2 (12.9898, 78.233))) * 43758.5453);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (DryBrush)
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy0 = fn_rnd (uv3 - 0.5.xx) * stroke * Amount;
   float2 xy1, xy2, xy3;

   sincos (angle, xy3.x, xy3.y);

   xy1.x = xy0.x * xy3.x + xy0.y * xy3.y;
   xy1.y = xy0.y * xy3.x - xy0.x * xy3.y;

   xy0 = fn_rnd (uv3 - 0.5.xx) * stroke * (1.0 - Amount);

   xy2.x = xy0.x * xy3.x + xy0.y * xy3.y;
   xy2.y = xy0.y * xy3.x - xy0.x * xy3.y;

   float4 Fgnd = tex2D (Fgd, uv3 + xy1);
   float4 Bgnd = tex2D (Bgd, uv3 + xy2);

   return lerp (Fgnd, Bgnd, Amount);
}

