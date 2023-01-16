// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 A transition that splits a blended foreground image into strips and compresses it to zero
 height.  The vertical centring can be adjusted so that the collapse is symmetrical or
 asymmetrical.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Strips_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Strips (keyed)", "Mix", "Wipe transitions", "Splits the foreground into strips and compresses it to zero height", CanSize);

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

DeclareFloatParam (Spacing, "Spacing", "Strips", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Spread, "Spread", "Strips", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (centreX, "Centre", "Strips", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (centreY, "Centre", "Strips", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

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

// technique Strips_F

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

DeclareEntryPoint (Strips_F)
{
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv3.y * PI);
   float Height   = 1.0 + ((1.0 - cos (amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * amount;

   float2 xy = uv3 + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Super_F, xy);

   return lerp (ReadPixel (Fg, uv1), Fgnd, Fgnd.a * Amount);
}


// technique Strips_I

DeclarePass (Super_I)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Strips_I)
{
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv3.y * PI);
   float Height   = 1.0 + ((1.0 - cos (amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * amount;

   float2 xy = uv3 + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_I, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * Amount);
}


// technique Strips_O

DeclarePass (Super_O)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Strips_O)
{
   float amount   = 1.0 - Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv3.y * PI);
   float Height   = 1.0 + ((1.0 - cos (Amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * Amount;

   float2 xy = uv3 + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_O, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * amount);
}

