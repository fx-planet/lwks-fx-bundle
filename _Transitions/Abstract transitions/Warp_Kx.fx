// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This is a dissolve that warps.  The warp is driven by the background image, and so will be
 different each time that it's used.  It supports titles and other blended effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 Unlike with LW transitions there is no mask.  Instead the ability to crop the effect
 to the background is provided, which dissolves between the cropped areas during the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Warp_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
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
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta unfolded|Standard transitions");

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

// technique Warp_Kx_F

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

DeclareEntryPoint (Warp_Kx_F)
{
   float4 Bgnd = tex2D (Bg_F, uv3);
   float4 warp = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy = uv3 + float2 (warp.y - 0.5, (warp.z - warp.x) * 2.0) * (1.0 - sin (Amount * HALF_PI));

   float4 Fgnd = tex2D (Super_F, xy);

   warp = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : warp;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : warp;

      warp = lerp (Fgnd, Bgnd, Amount);
   }

   return warp;
}

//-----------------------------------------------------------------------------------------//

// technique Warp_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (Warp_Kx_I)
{
   float4 Bgnd = tex2D (Bg_I, uv3);
   float4 warp = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy = uv3 + float2 (warp.y - 0.5, (warp.z - warp.x) * 2.0) * (1.0 - sin (Amount * HALF_PI));

   float4 Fgnd = tex2D (Super_I, xy);

   warp = lerp (Bgnd, Fgnd, Fgnd.a * Amount);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : warp;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : warp;

      warp = lerp (Fgnd, Bgnd, Amount);
   }

   return warp;
}

//-----------------------------------------------------------------------------------------//

// technique Warp_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (Warp_Kx_O)
{
   float4 Bgnd = tex2D (Bg_O, uv3);
   float4 warp = (Bgnd - 0.5.xxxx) * Distortion * 4.0;

   float2 xy = uv3 + float2 ((warp.y - warp.z) * 2.0, 0.5 - warp.x) * (1.0 - cos (Amount * HALF_PI));

   float amount = 1.0 - Amount;

   float4 Fgnd = tex2D (Super_O, xy);

   warp = lerp (Bgnd, Fgnd, Fgnd.a * amount);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : warp;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : warp;

      warp = lerp (Fgnd, Bgnd, 1.0 - Amount);
   }

   return warp;
}

