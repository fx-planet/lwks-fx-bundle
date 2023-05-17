// @Maintainer jwrl
// @Released 2023-05-17
// @Author schrauber
// @Author baopao
// @Author nouanda
// @Created 2016-08-10

/**
 This is loosely based on the user effect Kaleido, converted to function as a transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KaleidoTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Kaleidoscope transition", "Mix", "Geometric transitions", "Breaks the images into a rotary kaleidoscope pattern", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Zoom, "Zoom", kNoGroup, kNoFlags, 1.0, 0.0, 2.0);

DeclareFloatParam (PosX, "Position", "Pan", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (PosY, "Position", "Pan", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam (fan, "Fan", kNoGroup, true);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536

#define MINIMUM 0.0000000001

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function is necessary because we can't set addressing modes

float4 MirrorPixel (sampler S, float2 xy)
{
   float2 xy1 = 1.0.xx - abs (2.0 * (frac (xy / 2.0) - 0.5.xx));

   return ReadPixel (S, xy1);
}

// This function added to mimic the GLSL mod() function

float mod (float x, float y)
{
   return x - y * floor (x/y);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These passes provide the edge mirroring necessary for this effect.

DeclarePass (FgK)
{ return MirrorPixel (Fg, uv1); }

DeclarePass (BgK)
{ return MirrorPixel (Bg, uv2); }

DeclareEntryPoint (KaleidoTurbine_Dx)
{
   float4 color;    // Output

   float2 PosXY = float2 (PosX, 1.0 - PosY);
   float2 p = uv3 - PosXY;

   float scale = 1.0 - (1.8 * amount);    // Phase 2, kaleido, tube (Z), strengthen
   float r = length (p);
   float a = atan2 (p.y, p.x);            // Changed from GLSL version - float a = atan (p.y, p.x)
   float amount_b = (amount - 0.4) * 5.0; 
   float kaleido = (amount * 50.0) + 0.1; // Phase 1, kaleido,rotation, strengthen
   float tau = 2.0 * PI / kaleido;

   if (amount > 0.5 ) {
      kaleido = 50.1 - (amount * 50.0);   // Phase 2, kaleido, rotation, weaken
      scale = 1.8 * (amount - 0.5) + 0.1; // Phase 2, kaleido, tube (Z), weaken
   }

   a = mod (a, tau);
   a = abs (a - (tau / 2.0));

   sincos (a, p.y, p.x);

   p = (((p * r) / Zoom) + PosXY) / scale;

   if (r > amount_b) color = MirrorPixel (FgK, p);    // Kaleido phase 1 (FB outside & BG inside)
   else color = MirrorPixel (BgK, p);                 // Kaleido phase 2

   // Fan phase 1
   if ((a > amount) && (amount < 0.5) && (fan)) color = ReadPixel (Fg, uv1);

   // Fan phase 2
   if ((a > 1.0 - amount) && (amount > 0.5) && (fan)) color = ReadPixel (Bg, uv1);

   return lerp (ReadPixel (Fg, uv1), color, tex2D (Mask, uv3).x);
}

