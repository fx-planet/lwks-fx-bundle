// @Maintainer jwrl
// @Released 2023-01-07
// @Author baopao
// @Created 2015-09-23

/**
 RGB-CMY correction is a colorgrade tool based on the individual red, green, blue, cyan,
 magenta and yellow parameters.  This is a "Color_NOT_Channel" correction based filter
 originally created for Mac and Linux systems, and subsequently extended to Windows.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBCMYcorrect.fx
//
// Version history:
//
// Updated 2023-01-07 jwrl.
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("RGB-CMY correction", "Colour", "Colour Tools", "A colorgrade tool based on individual red, green, blue, cyan, magenta and yellow parameters", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

// RED_P

DeclareColourParam (R_TintColour, "TintColour", "RED", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (R_TintAmount, "TintAmount", "RED", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (R_Saturate, "Saturate", "RED", kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (R_Gamma, "Gamma", "RED", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (R_Contrast, "Contrast", "RED", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (R_Gain, "Gain", "RED", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (R_Brightness, "Brightness", "RED", kNoFlags, 0.0, -1.0, 2.0);

// GREEN_P

DeclareColourParam (G_TintColour, "TintColour", "GREEN", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (G_TintAmount, "TintAmount", "GREEN", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (G_Saturate, "Saturate", "GREEN", kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (G_Gamma, "Gamma", "GREEN", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (G_Contrast, "Contrast", "GREEN", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (G_Gain, "Gain", "GREEN", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (G_Brightness, "Brightness", "GREEN", kNoFlags, 0.0, -1.0, 2.0);

// BLUE_P

DeclareColourParam (B_TintColour, "TintColour", "BLUE", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (B_TintAmount, "TintAmount", "BLUE", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (B_Saturate, "Saturate", "BLUE", kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (B_Gamma, "Gamma", "BLUE", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (B_Contrast, "Contrast", "BLUE", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (B_Gain, "Gain", "BLUE", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (B_Brightness, "Brightness", "BLUE", kNoFlags, 0.0, -1.0, 2.0);

// CYAN_P

DeclareColourParam (C_TintColour, "TintColour", "CYAN", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (C_TintAmount, "TintAmount", "CYAN", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (C_Saturate, "Saturate", "CYAN", kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (C_Gamma, "Gamma", "CYAN", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (C_Contrast, "Contrast", "CYAN", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (C_Gain, "Gain", "CYAN", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (C_Brightness, "Brightness", "CYAN", kNoFlags, 0.0, -1.0, 2.0);

// MAGENTA_P

DeclareColourParam (M_TintColour, "TintColour", "MAGENTA", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (M_TintAmount, "TintAmount", "MAGENTA", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (M_Saturate, "Saturate", "MAGENTA", kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (M_Gamma, "Gamma", "MAGENTA", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (M_Contrast, "Contrast", "MAGENTA", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (M_Gain, "Gain", "MAGENTA", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (M_Brightness, "Brightness", "MAGENTA", kNoFlags, 0.0, -1.0, 2.0);

// YELLOW_P

DeclareColourParam (Y_TintColour, "TintColour", "YELLOW", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (Y_TintAmount, "TintAmount", "YELLOW", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Y_Saturate, "Saturate", "YELLOW", kNoFlags, 1.0, 0.0, 5.0);
DeclareFloatParam (Y_Gamma, "Gamma", "YELLOW", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Y_Contrast, "Contrast", "YELLOW", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Y_Gain, "Gain", "YELLOW", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Y_Brightness, "Brightness", "YELLOW", kNoFlags, 0.0, -1.0, 2.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RGBCMYcorrect)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 Inp = tex2D (Input, uv1);
   float4 Cs = saturate (Inp);

   float lum   = (Cs.r + Cs.g + Cs.b) / 3.0;
   float lum_1 = lum - 0.5;
   float alpha = Cs.a;

   float A = Cs.r - max (Cs.g, Cs.b);
   float B = Cs.g - max (Cs.r, Cs.b);
   float C = Cs.b - max (Cs.r, Cs.g);

   float red   = saturate (A - max (B, C));
   float green = saturate (B - max (C, A));
   float blue  = saturate (C - max (A, B));

   A = min (Cs.g, Cs.b) - Cs.r;
   B = min (Cs.b, Cs.r) - Cs.g;
   C = min (Cs.r, Cs.g) - Cs.b;

   float cyan    = saturate (A - max (B, C));
   float magenta = saturate (B - max (C, A));
   float yellow  = saturate (C - max (A, B));

   // RED

   float4 Tint = float4 (R_TintColour.rgb + lum_1.xxx, Cs.a);
   float4 Cs_R = lerp (Cs, Tint, R_TintAmount);

   Cs_R = saturate (lum + ((Cs_R - lum) * R_Saturate));
   Cs_R = ((((pow (Cs_R, 1.0 / R_Gamma) * R_Gain) + R_Brightness) - 0.5) * R_Contrast) + 0.5;

   // GREEN

   Tint.rgb = G_TintColour.rgb + lum_1.xxx;

   float4 Cs_G = lerp (Cs, Tint, G_TintAmount);

   Cs_G = saturate (lum + ((Cs_G - lum) * G_Saturate));
   Cs_G = ((((pow (Cs_G, 1.0 / G_Gamma) * G_Gain) + G_Brightness) - 0.5) * G_Contrast) + 0.5;

   // BLUE

   Tint.rgb = B_TintColour.rgb + lum_1.xxx;

   float4 Cs_B = lerp( Cs, Tint, B_TintAmount);

   Cs_B = saturate (lum + ((Cs_B - lum) * B_Saturate));
   Cs_B = (((( pow (Cs_B, 1.0 / B_Gamma ) * B_Gain) + B_Brightness) - 0.5) * B_Contrast) + 0.5;

   // CYAN

   Tint.rgb = C_TintColour.rgb + lum_1.xxx;

   float4 Cs_C = lerp (Cs, Tint, C_TintAmount);
   Cs_C = saturate (lum + ((Cs_C - lum) * C_Saturate));
   Cs_C = ((((pow (Cs_C, 1.0 / C_Gamma) * C_Gain) + C_Brightness) - 0.5) * C_Contrast) + 0.5;

   // MAGENTA

   Tint.rgb = M_TintColour.rgb + lum_1.xxx;

   float4 Cs_M = lerp( Cs, Tint, M_TintAmount);

   Cs_M = saturate (lum + ((Cs_M - lum) * M_Saturate));
   Cs_M = ((((pow (Cs_M, 1.0 / M_Gamma) * M_Gain) + M_Brightness) - 0.5) * M_Contrast) + 0.5;

   // YELLOW

   Tint.rgb = Y_TintColour.rgb + lum_1.xxx;

   float4 Cs_Y = lerp (Cs, Tint, Y_TintAmount);

   Cs_Y = saturate (lum + ((Cs_Y - lum) * Y_Saturate));
   Cs_Y = ((((pow (Cs_Y, 1.0 / Y_Gamma) * Y_Gain) + Y_Brightness) - 0.5) * Y_Contrast) + 0.5;

   // OUTPUT

   Cs_R = lerp (Cs,   Cs_R, red);
   Cs_G = lerp (Cs_R, Cs_G, green);
   Cs_B = lerp (Cs_G, Cs_B, blue);
   Cs_C = lerp (Cs_B, Cs_C, cyan);
   Cs_M = lerp (Cs_C, Cs_M, magenta);
   Cs   = lerp (Cs_M, Cs_Y, yellow);

   return lerp (Inp, saturate (Cs), tex2D (Mask, uv1));
}

