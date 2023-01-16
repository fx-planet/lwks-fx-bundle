// @Maintainer jwrl
// @Released 2023-01-16
// @Author schrauber
// @Author baopao
// @Author nouanda
// @Created 2016-08-10

/**
 This effect is based on the user effect Kaleido, converted to function as a transition.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KaleidoTurbine_Dx.fx
//
// From Schrauber revised for transitions.  The transition effect is based on baopao's
// (and/or nouanda?)  "Kaleido".  In the "Kaleido" file was the following:
// Quote: ...................
// Kaleido   http://www.alessandrodallafontana.com/ based on the pixel shader of:
// http://pixelshaders.com/ corrected for HLSL by Lightworks user nouanda
// ..........................
//
// Version history:
//
// Updated 2023-01-16 jwrl
// Updated to provide LW 2022 revised cross platform support.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Kaleido turbine mix", "Mix", "Geometric transitions", "Uses a kaleidoscope pattern to transition between two clips", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

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

// This function is necessary because at the moment we can't set addressing modes

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
// Code
//-----------------------------------------------------------------------------------------//

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

   if ((a > amount) && (amount < 0.5) && (fan)) color = ReadPixel (Fg, uv1);        // Fan phase 1
   if ((a > 1.0 - amount) && (amount > 0.5) && (fan)) color = ReadPixel (Bg, uv2);  // Fan phase 2

   return color;
}

