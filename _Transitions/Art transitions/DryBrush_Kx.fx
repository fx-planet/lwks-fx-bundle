// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

/**
 This mimics the Photoshop angled brush stroke effect to reveal or remove a clip or
 an effect using an alpha or delta key.  The stroke length and angle can be
 independently adjusted, and can be keyframed while the transition progresses to
 make the effect more dynamic.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrush_Kx.fx
//
// Version history:
//
// Built 2023-01-28 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dry brush mix (keyed)", "Mix", "Art transitions", "Mimics the Photoshop angled brush effect to reveal or remove the foreground video", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Length, "Stroke length", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle, "Stroke angle", kNoGroup, kNoFlags, 45.0, -180.0, 180.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_rnd (float2 uv)
{
   return frac (sin (dot (uv - 0.5.xx, float2 (12.9898, 78.233))) * 43758.5453);
}

float4 fn_keygen (sampler B, float2 xy1, float2 xy2)
{
   float4 Fgnd = ReadPixel (Fg, xy1);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique DryBrush_Kx_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Super_F)
{
   float4 Fgnd = tex2D (Bg_F, uv3);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

DeclareEntryPoint (DryBrush_Folded)
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = fn_rnd (uv3) * stroke * (1.0 - Amount);
   float2 xy2;

   sincos (angle, xy2.x, xy2.y);

   xy1 = uv3 + float2 ((xy1.x * xy2.x) + (xy1.y * xy2.y), (xy1.y * xy2.x) - (xy1.x * xy2.y));

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_F, xy1);

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique DryBrush_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (DryBrush_In)
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = fn_rnd (uv3) * stroke * (1.0 - Amount);
   float2 xy2;

   sincos (angle, xy2.x, xy2.y);

   xy1 = uv3 + float2 ((xy1.x * xy2.x) + (xy1.y * xy2.y), (xy1.y * xy2.x) - (xy1.x * xy2.y));

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_I, xy1);

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique DryBrush_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (DryBrush_Out)
{
   float stroke = (Length * 0.1) + 0.02;
   float angle  = radians (Angle + 135.0);

   float2 xy1 = fn_rnd (uv3) * stroke * Amount;
   float2 xy2;

   sincos (angle, xy2.x, xy2.y);

   xy1 = uv3 + float2 ((xy1.x * xy2.x) + (xy1.y * xy2.y), (xy1.y * xy2.x) - (xy1.x * xy2.y));

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_O, xy1);

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a * (1.0 - Amount));
}

