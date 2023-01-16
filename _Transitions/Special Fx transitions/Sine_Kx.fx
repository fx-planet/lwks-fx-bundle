// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is a dissolve/wipe that uses sine distortion to perform a left-right or right-left
 transition into or out of the blended foreground.  Phase can be offset by 180 degrees.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sine_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
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
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

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

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy2);

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

DeclarePass (Super_F)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

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

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Super_F, xy);

   return lerp (ReadPixel (Fg, uv1), Fgnd, Fgnd.a * amount);
}


// technique Sine_I

DeclarePass (Super_I)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

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

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_I, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * amount);
}


// technique Sine_O

DeclarePass (Super_O)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

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

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_O, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * amount);
}

