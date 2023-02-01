// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This effect is a user-selectable zoom in or zoom out that transitions into or out of
 blended and keyed foreground layers.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
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
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta|Standard transitions");

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

float4 fn_keygen (sampler F, sampler B, float2 xy, bool fold)
{
   float4 Fgnd = ReadPixel (F, xy);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy);

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

// technique Zoom_Kx_F

DeclarePass (Fg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_F)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_F)
{ return fn_keygen (Fg_F, Bg_F, uv3, true); }

DeclarePass (Super_F)
{ return Direction ? fn_zoom_A (Title_F, uv3) : fn_zoom_C (Title_F, uv3); }

DeclareEntryPoint (Zoom_Kx_F)
{
   float4 Title = Direction ? fn_zoom_A (Super_F, uv3) : fn_zoom_C (Super_F, uv3);

   return fn_main (Fg_F, uv3, Title, Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Zoom_Kx_I

DeclarePass (Fg_I)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_I)
{ return fn_keygen (Fg_I, Bg_I, uv3, false); }

DeclarePass (Super_I)
{ return Direction ? fn_zoom_A (Title_I, uv3) : fn_zoom_B (Title_I, uv3); }

DeclareEntryPoint (Zoom_Kx_I)
{
   float4 Title = Direction ? fn_zoom_A (Super_I, uv3) : fn_zoom_B (Super_I, uv3);

   return fn_main (Bg_I, uv3, Title, Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Zoom_Kx_O

DeclarePass (Fg_O)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_O)
{ return fn_keygen (Fg_O, Bg_O, uv3, false); }

DeclarePass (Super_O)
{ return Direction ? fn_zoom_C (Title_O, uv3) : fn_zoom_D (Title_O, uv3); }

DeclareEntryPoint (Zoom_Kx_O)
{
   float4 Title = Direction ? fn_zoom_C (Super_O, uv3) : fn_zoom_D (Super_O, uv3);

   return fn_main (Bg_O, uv3, Title, 1.0 - Amount);
}

