// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This is a dissolve that warps.  The warp is driven by the background image, and so will be
 different each time that it's used.  It supports titles and other blended effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Warp_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Warp transition (keyed)", "Mix", "Abstract transitions", "Warps into or out of titles, keys and other effects", "CanSize");

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

DeclareFloatParam (Distortion, "Distortion", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

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

DeclareEntryPoint (Main_Folded)
{
   float4 Bgnd = ReadPixel (Fg, uv1);
   float4 warp = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy = uv3 + float2 (warp.y - 0.5, (warp.z - warp.x) * 2.0) * (1.0 - sin (Amount * HALF_PI));

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Super_F, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

DeclarePass (Super_I)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Main_In)
{
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 warp = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy = uv3 + float2 (warp.y - 0.5, (warp.z - warp.x) * 2.0) * (1.0 - sin (Amount * HALF_PI));

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_I, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

DeclarePass (Super_O)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Main_Out)
{
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 warp = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy = uv3 + float2 ((warp.y - warp.z) * 2.0, 0.5 - warp.x) * (1.0 - cos (Amount * HALF_PI));

   float amount = 1.0 - Amount;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_O, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * amount);
}

