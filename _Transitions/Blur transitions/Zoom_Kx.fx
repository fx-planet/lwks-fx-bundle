// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect is a user-selectable zoom in or zoom out that transitions into or out of
 blended and keyed foreground layers.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Zoom dissolve (keyed)", "Mix", "Blur transitions", "Zooms in or out of the foreground to establish or remove it", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (zoomAmount, "Strength", "Zoom", kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Direction, "Direction", "Zoom", 0, "Zoom in|Zoom out");

DeclareFloatParam (Xcentre, "Centre", "Zoom", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Centre", "Zoom", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SAMPLE  61
#define DIVISOR 61.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2, bool fold)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = fold ? Bgnd.rgb * Fgnd.a : Fgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_zoom_A (sampler S, float2 uv)
{
   if (zoomAmount == 0.0) return tex2D (S, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount);
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1, xy2 = uv - zoomCentre;

   float4 retval = kTransparentBlack;

   for (int i = 0; i < SAMPLE; i++) {
      xy1 = (xy2 * scale) + zoomCentre;
      retval += tex2D (S, xy1);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 fn_zoom_B (sampler S, float2 uv)
{
   if (zoomAmount == 0.0) return tex2D (S, uv);

   float zoomStrength = zoomAmount * Amount / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1, xy2 = uv - zoomCentre;

   float4 retval = kTransparentBlack;

   for (int i = 0; i < SAMPLE; i++) {
      xy1 = (xy2 * scale) + zoomCentre;
      retval += tex2D (S, xy1);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 fn_zoom_C (sampler S, float2 uv)
{
   if (zoomAmount == 0.0) return tex2D (S, uv);

   float zoomStrength = zoomAmount * (1.0 - Amount) / SAMPLE;
   float scale = 1.0;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1, xy2 = uv - zoomCentre;

   float4 retval = kTransparentBlack;

   for (int i = 0; i < SAMPLE; i++) {
      xy1 = (xy2 * scale) + zoomCentre;
      retval += tex2D (S, xy1);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 fn_zoom_D (sampler S, float2 uv)
{
   if (zoomAmount == 0.0) return tex2D (S, uv);

   float zoomStrength = zoomAmount * Amount;
   float scale = 1.0 - zoomStrength;

   zoomStrength /= SAMPLE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1, xy2 = uv - zoomCentre;

   float4 retval = kTransparentBlack;

   for (int i = 0; i < SAMPLE; i++) {
      xy1 = (xy2 * scale) + zoomCentre;
      retval += tex2D (S, xy1);
      scale += zoomStrength;
   }

   return retval / DIVISOR;
}

float4 fn_main (sampler B, float2 uv, float4 F, float amt)
{
   float4 Fgnd = CropEdges && IsOutOfBounds (uv) ? kTransparentBlack : F;

   return lerp (ReadPixel (B, uv), Fgnd, Fgnd.a * amt);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Zoom_Kx_1

DeclarePass (Title_0)
{ return fn_keygen (Fg, uv1, Bg, uv2, true); }

DeclarePass (Super_0)
{ return Direction ? fn_zoom_A (Title_0, uv3) : fn_zoom_C (Title_0, uv3); }

DeclareEntryPoint (Zoom_Kx_0)
{
   float4 Title = Direction ? fn_zoom_A (Super_0, uv3) : fn_zoom_C (Super_0, uv3);

   return fn_main (Fg, uv1, Title, Amount);
}


// technique Zoom_Kx_1

DeclarePass (Title_1)
{ return fn_keygen (Fg, uv1, Bg, uv2, false); }

DeclarePass (Super_1)
{ return Direction ? fn_zoom_A (Title_1, uv3) : fn_zoom_B (Title_1, uv3); }

DeclareEntryPoint (Zoom_Kx_1)
{
   float4 Title = Direction ? fn_zoom_A (Super_1, uv3) : fn_zoom_B (Super_1, uv3);

   return fn_main (Bg, uv2, Title, Amount);
}


// technique Zoom_Kx_2

DeclarePass (Title_2)
{ return fn_keygen (Fg, uv1, Bg, uv2, false); }

DeclarePass (Super_2)
{ return Direction ? fn_zoom_C (Title_2, uv3) : fn_zoom_D (Title_2, uv3); }

DeclareEntryPoint (Zoom_Kx_2)
{
   float4 Title = Direction ? fn_zoom_C (Super_2, uv3) : fn_zoom_D (Super_2, uv3);

   return fn_main (Bg, uv2, Title, 1.0 - Amount);
}

