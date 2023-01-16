// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect pinches the outgoing blended foreground to a user-defined point to reveal
 the background video.  It can also reverse the process to bring in the foreground.
 It's the effect version of rPinch_Dx.  Unlike "Pinch", this version compresses to the
 diagonal radii of the images.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rpinch_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Radial pinch (keyed)", "Mix", "DVE transitions", "Pinches the foreground radially to a user-defined point to either hide or reveal it", CanSize);

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

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define MID_PT  0.5.xx

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

// technique rPinch_Fx_F

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

DeclareEntryPoint (rPinch_Fx_F)
{
   float progress = (1.0 - Amount) / 2.14;
   float rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv3 - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv1) ? kTransparentBlack : ReadPixel (Super_F, xy);

   return lerp (ReadPixel (Fg, uv1), Fgnd, Fgnd.a);
}


// technique rPinch_Fx_I

DeclarePass (Super_I)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (rPinch_Fx_I)
{
   float progress = (1.0 - Amount) / 2.14;
   float rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv3 - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : ReadPixel (Super_I, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a);
}


// technique rPinch_Fx_O

DeclarePass (Super_O)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (rPinch_Fx_O)
{
   float progress = Amount / 2.14;
   float rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

   float2 xy = (uv3 - MID_PT) * scale;

   xy *= scale;
   xy += MID_PT;

   float4 Fgnd = CropEdges && IsOutOfBounds (uv2) ? kTransparentBlack : ReadPixel (Super_O, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a);
}

