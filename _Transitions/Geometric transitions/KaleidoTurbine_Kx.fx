// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is loosely based on the user effect Kaleido, converted to function as a transition
 into or out of a blended foreground effect, such as titles, image keys and the like.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KaleidoTurbine_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Kaleido turbine mix (keyed)", "Mix", "Geometric transitions", "Breaks the blended foreground into a rotary kaleidoscope pattern", CanSize);

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

DeclareFloatParam (Sides, "Sides", "Kaleidoscope", kNoFlags, 25.0, 5.0, 50.0);
DeclareFloatParam (scaleAmt, "Scale", "Kaleidoscope", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (zoomFactor, "Zoom", "Kaleidoscope", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (PosX, "Effect centre", "Kaleidoscope", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (PosY, "Effect centre", "Kaleidoscope", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268
#define PI      3.1415926536
#define TWO_PI  6.2831853072

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
// Shaders
//-----------------------------------------------------------------------------------------//

// technique KaleidoTurbine_Kx_F

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

DeclareEntryPoint (KaleidoTurbine_Kx_F)
{
   float mixval = sin (Amount * HALF_PI);
   float amount = 1.0 - Amount;
   float Scale = 1.0 + (amount * (1.2 - scaleAmt));
   float sideval = 1.0 + (amount * Sides);
   float Zoom = 1.0 + (amount * zoomFactor);

   float2 xy1 = 1.0.xx - float2 (PosX, PosY);
   float2 xy2 = float2 (1.0 - uv3.x, uv3.y) - xy1;

   float radius = length (xy2) / Zoom;
   float angle  = atan2 (xy2.y, xy2.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy2.y, xy2.x);
   xy2 = ((xy2 * radius) / Scale) + xy1;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Super_F, xy2);

   return lerp (ReadPixel (Fg, uv1), Fgnd, Fgnd.a * mixval);
}


// technique KaleidoTurbine_Kx_I

DeclarePass (Super_I)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (KaleidoTurbine_Kx_I)
{
   float mixval = sin (Amount * HALF_PI);
   float amount = 1.0 - Amount;
   float Scale = 1.0 + (amount * (1.2 - scaleAmt));
   float sideval = 1.0 + (amount * Sides);
   float Zoom = 1.0 + (amount * zoomFactor);

   float2 xy1 = 1.0.xx - float2 (PosX, PosY);
   float2 xy2 = float2 (1.0 - uv3.x, uv3.y) - xy1;

   float radius = length (xy2) / Zoom;
   float angle  = atan2 (xy2.y, xy2.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy2.y, xy2.x);
   xy2 = ((xy2 * radius) / Scale) + xy1;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_I, xy2);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * mixval);
}


// technique KaleidoTurbine_Kx_O

DeclarePass (Super_O)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (KaleidoTurbine_Kx_O)
{
   float Scale = 1.0 + (Amount * (1.2 - scaleAmt));
   float mixval = cos (Amount * HALF_PI);
   float sideval = 1.0 + (Amount * Sides);
   float Zoom = 1.0 + (Amount * zoomFactor);

   float2 xy1 = 1.0.xx - float2 (PosX, PosY);
   float2 xy2 = float2 (1.0 - uv3.x, uv3.y) - xy1;

   float radius = length (xy2) / Zoom;
   float angle  = atan2 (xy2.y, xy2.x);

   angle = fmod (angle, TWO_PI / sideval);
   angle = abs (angle - (PI / sideval));

   sincos (angle, xy2.y, xy2.x);
   xy2 = ((xy2 * radius) / Scale) + xy1;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_O, xy2);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * mixval);
}

