// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect performs a whip pan style of transition between two sources.  Unlike the
 blur dissolve effect, this also pans the incoming and outgoing vision sources.  The
 whip pan angle can be set over the range of plus or minus 180 degrees to allow for
 all likely camera moves.

 To better handle varying aspect ratios masking has been provided to limit the blur
 range to the input frame boundaries.  This changes as the effect progresses to allow
 for differing incoming and outgoing media aspect ratios.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhipPan_Dx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Whip pan", "Mix", "Blur transitions", "Uses a directional blur to simulate a whip pan between two sources", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Angle, "Angle", kNoGroup, kNoFlags, 0.0, -180.0, 180.0);
DeclareFloatParam (Spread, "Spread", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI        3.14159265359

#define SAMPLES   60
#define SAMPSCALE 61

#define STRENGTH  0.01

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (WhipPan_Dx)
{
   float amount = saturate (Amount);   // Just in case someone types in silly numbers

   float2 blur1, blur2;

   sincos (radians (Angle), blur1.y, blur1.x);
   sincos (radians (Angle + 180.0), blur2.y, blur2.x);

   blur1  *= Spread * amount;
   blur2  *= Spread * (1.0 - amount);
   blur1.x = -blur1.x;
   blur2.x = -blur2.x;

   float2 xy1 = uv3 + (blur1 * 3.0);
   float2 xy2 = uv3 + (blur2 * 3.0);

   float4 Fgnd = ReadPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bgd, xy2);

   if (Spread > 0.0) {
      blur1 *= STRENGTH;
      blur2 *= STRENGTH;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur1;
         xy2 += blur2;
         Fgnd += ReadPixel (Fgd, xy1);
         Bgnd += ReadPixel (Bgd, xy2);
      }
    
      Fgnd /= SAMPSCALE;
      Bgnd /= SAMPSCALE;
   }

   return lerp (Fgnd, Bgnd, 0.5 - (cos (amount * PI) / 2.0));
}

