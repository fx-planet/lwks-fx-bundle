// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2017-02-22

/**
 This effect simulates a close-up look at an analogue colour TV screen.  Three options
 are available: Trinitron (Sony), Diamondtron (Mitusbishi/NEC) and Linitron.  For
 copyright reasons they are identified as type 1, type 2 and type 3 respectively in
 this effect.  No attempt has been made to emulate a dot matrix shadow mask tube,
 because in early tests we just lost too much luminance for the effect to be useful.
 That's pretty much why the manufacturers stopped using the real shadowmask too.

 The stabilising wires have not been emulated in the type 1 tube for anything other
 than the lowest two pixel sizes.  They just looked absurd with the larger settings.

 The glow/halation effect is just a simple box blur, slightly modified to give a
 reasonable simulation of the burnout that could be obtained by overdriving a CRT.

 NOTE 1:  Because this effect needs to be able to precisely set pixel widths no matter
 what the original clip size or aspect ratio is it has not been possible to make it
 truly resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.

 NOTE 2:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user CRTscreen.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-12 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("CRT TV screen", "Stylize", "Video artefacts", "Simulates a close-up look at an analogue colour TV screen.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (PixelScale, "Pixel scale", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareIntParam (Style, "Screen mask", kNoGroup, 0, "Type 1|Type 2|Type 3");

DeclareFloatParam (GlowRadius, "Glow radius", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (GlowAmount, "Glow amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define R_ON   0.00
#define R_OFF  0.25
#define G_ON   0.33
#define G_OFF  0.58
#define B_ON   0.66
#define B_OFF  0.91

#define V_MAX  0.8

#define SONY   0
#define DMD    2

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Raster)
{
   float4 retval = tex2D (Input, uv1);

   int scale = 1.0 + (10.0 * max (PixelScale, 0.0));

   float H_pixels = float (int (uv1.x * _OutputWidth * 3.0 / scale) / 12.0);
   float V_pixels = frac (int (uv1.y * _OutputWidth / (_OutputAspectRatio + scale)) / 8.0);
   float P_pixels;

   H_pixels = modf (H_pixels, P_pixels);
   P_pixels = round (frac (P_pixels / 2.0) + 0.25);

   if ((P_pixels == 1.0) && (Style == DMD))
      V_pixels = (V_pixels >= 0.5) ? V_pixels - 0.5 : V_pixels + 0.5;

   if ((H_pixels < R_ON) || (H_pixels > R_OFF)) retval.r = 0.0;

   if ((H_pixels < G_ON) || (H_pixels > G_OFF)) retval.g = 0.0;

   if ((H_pixels < B_ON) || (H_pixels > B_OFF)) retval.b = 0.0;

   if (Style == SONY) {                // New code for Sony Trinitron stabilising wires

      if (scale <= 2) {
         V_pixels = abs (uv1.y - 0.5);
         P_pixels = (scale == 1) ? (V_pixels) * 2.0 : V_pixels;
         P_pixels = (P_pixels < 0.4) ? 1.0 : P_pixels - 0.4;

         if (P_pixels < 0.002) return float4 (0.0.xxx, retval.a);
      }
   }
   else if (V_pixels > V_MAX) return float4 (0.0.xxx, retval.a);

   return retval;
}

DeclarePass (Prelim)
{
   float2 xy = uv2;

   float Pixel_1 = GlowRadius / _OutputWidth;
   float Pixel_2 = Pixel_1 + Pixel_1 + Pixel_1;

   xy.x    += Pixel_1;
   Pixel_1 += Pixel_2;

   float4 retval = tex2D (Raster, xy);

   xy.x += Pixel_1; retval += tex2D (Raster, xy);
   xy.x += Pixel_1; retval += tex2D (Raster, xy);
   xy.x += Pixel_1; retval += tex2D (Raster, xy);
   xy.x += Pixel_1; retval += tex2D (Raster, xy);

   xy.x = uv2.x - Pixel_2;
   retval += tex2D (Raster, xy);

   xy.x -= Pixel_1; retval += tex2D (Raster, xy);
   xy.x -= Pixel_1; retval += tex2D (Raster, xy);
   xy.x -= Pixel_1; retval += tex2D (Raster, xy);
   xy.x -= Pixel_1; retval += tex2D (Raster, xy);

   return retval / 10.0;
}

DeclareEntryPoint (CRTscreen)
{
   float2 xy = uv2;

   float Pixel_1 = GlowRadius * _OutputAspectRatio / _OutputWidth;
   float Pixel_2 = Pixel_1 + Pixel_1 + Pixel_1;

   xy.y    += Pixel_1;
   Pixel_1 += Pixel_2;

   float4 retval = tex2D (Prelim, xy);

   xy.y += Pixel_1; retval += tex2D (Prelim, xy);
   xy.y += Pixel_1; retval += tex2D (Prelim, xy);
   xy.y += Pixel_1; retval += tex2D (Prelim, xy);
   xy.y += Pixel_1; retval += tex2D (Prelim, xy);

   xy.y = uv2.y - Pixel_2;
   retval += tex2D (Prelim, xy);

   xy.y -= Pixel_1; retval += tex2D (Prelim, xy);
   xy.y -= Pixel_1; retval += tex2D (Prelim, xy);
   xy.y -= Pixel_1; retval += tex2D (Prelim, xy);
   xy.y -= Pixel_1; retval += tex2D (Prelim, xy);

   retval /= 10.0;
   retval = lerp (retval, 0.0.xxxx, 1.0 - GlowAmount);

   float4 Inp = tex2D (Raster, uv2);

   retval = min (max (retval, Inp), 1.0.xxxx);
   retval = pow (retval, 0.4);

   float luma = dot (retval.rgb, float3 (0.2989, 0.5866, 0.1145));

   retval.a = Inp.a;
   Inp = saturate (retval + retval - luma);
   Inp.a = retval.a;

   luma = sqrt (GlowRadius * GlowAmount);

   return IsOutOfBounds (uv1) ? kTransparentBlack : lerp (retval, Inp, luma);
}

