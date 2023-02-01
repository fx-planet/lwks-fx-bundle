// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This is a dissolve/wipe that uses sine distortion to perform a left-right or right-left
 transition into or out of the blended foreground.  Phase can be offset by 180 degrees.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sine_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sinusoidal mix (keyed)", "Mix", "Special Fx transitions", "Uses a sine wave distortion to transition into or out of the blended foreground", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (Direction, "Transition direction", kNoGroup, 0, "Left to right|Right to left");

DeclareIntParam (Mode, "Distortion", "Ripples", 0, "Upwards|Downwards");

DeclareFloatParam (Width, "Softness", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples, "Spread", "Ripples", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Spread, "Amount", "Ripples", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

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

// technique Sine_F

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

DeclareEntryPoint (Sine__Kx_F)
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = Amount * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? uv3.x : 1.0 - uv3.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv3.x, uv3.y + offset) : float2 (uv3.x, uv3.y - offset);

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_F, xy);

   return lerp (tex2D (Bg_F, uv3), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//

// technique Sine_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (Sine__Kx_I)
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = Amount * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? uv3.x : 1.0 - uv3.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv3.x, uv3.y + offset) : float2 (uv3.x, uv3.y - offset);

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_I, xy);

   return lerp (tex2D (Bg_I, uv3), Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//

// technique Sine_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (Sine__Kx_O)
{
   float range  = max (0.0, Width * SOFTNESS) + OFFSET;
   float maxVis = (1.0 - Amount) * (1.0 + range);
   float minVis = maxVis - range;

   float x = (Direction == 0) ? 1.0 - uv3.x : uv3.x;

   float amount = (x <= minVis) ? 1.0
                : (x >= maxVis) ? 0.0 : (maxVis - x) / range;

   float ripples = max (0.0, RIPPLES * (x - minVis));
   float spread  = ripples * Spread * SCALE;
   float offset  = sin (pow (max (0.0, Ripples), 5.0) * ripples) * spread;

   float2 xy = (Mode == 0) ? float2 (uv3.x, uv3.y + offset) : float2 (uv3.x, uv3.y - offset);

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_O, xy);

   return lerp (tex2D (Bg_O, uv3), Fgnd, Fgnd.a * amount);
}

