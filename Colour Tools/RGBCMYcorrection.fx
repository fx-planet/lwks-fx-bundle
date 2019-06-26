// @Maintainer jwrl
// @Released 2018-12-23
// @Author baopao
// @Created 2015-09-23
// @see https://www.lwks.com/media/kunena/attachments/6375/CC_RGBCMY_640.png

/**
RGB-CMY correction is a colorgrade tool based on the individual red, green, blue, cyan,
magenta and yellow parameters.  This is a "Color_NOT_Channel" correction based filter
originally created for Mac and Linux systems, and subsequently extended to Windows.

NOTE: This version won't run or compile on Windows' Lightworks version 14.0 or earlier.
A legacy version is available for users with that requirement.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBCMYcorrection.fx
//
// Feedback should be to http://www.alessandrodallafontana.com/ 
//
// Cross platform compatibility check 31 July 2017 jwrl.
// Explicitly defined samplers to compensate for cross platform default sampler state
// differences.  In the process the original version has been rewritten to make it more
// modular and to provide Windows support.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified by LW user jwrl 23 December 2018.
// Changed subcategory.
// Changed name from CC_RGBCMY.fx.
// Added creation date.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RGB-CMY correction";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "A colorgrade tool based on individual red, green, blue, cyan, magenta and yellow parameters";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler   = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

// RED_P

float4 R_TintColour
<
   string Description = "TintColour";
   string Group = "RED";
> = { 1.0, 1.0, 1.0, 1.0 };

float R_TintAmount
<
   string Description = "TintAmount";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float R_Saturate
<
   string Description = "Saturate";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float R_Gamma
<
   string Description = "Gamma";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float R_Contrast
<
   string Description = "Contrast";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float R_Gain
<
   string Description = "Gain";
   string Group = "RED";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float R_Brightness
<
   string Description = "Brightness";
   string Group = "RED";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// GREEN_P

float4 G_TintColour
<
   string Description = "TintColour";
   string Group = "GREEN";
> = { 1.0, 1.0, 1.0, 1.0 };

float G_TintAmount
<
   string Description = "TintAmount";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float G_Saturate
<
   string Description = "Saturate";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float G_Gamma
<
   string Description = "Gamma";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float G_Contrast
<
   string Description = "Contrast";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float G_Gain
<
   string Description = "Gain";
   string Group = "GREEN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float G_Brightness
<
   string Description = "Brightness";
   string Group = "GREEN";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// BLUE_P

float4 B_TintColour
<
   string Description = "TintColour";
   string Group = "BLUE";
> = { 1.0, 1.0, 1.0, 1.0 };

float B_TintAmount
<
   string Description = "TintAmount";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float B_Saturate
<
   string Description = "Saturate";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float B_Gamma
<
   string Description = "Gamma";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float B_Contrast
<
   string Description = "Contrast";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float B_Gain
<
   string Description = "Gain";
   string Group = "BLUE";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float B_Brightness
<
   string Description = "Brightness";
   string Group = "BLUE";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// CYAN_P

float4 C_TintColour
<
   string Description = "TintColour";
   string Group = "CYAN";
> = { 1.0, 1.0, 1.0, 1.0 };

float C_TintAmount
<
   string Description = "TintAmount";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float C_Saturate
<
   string Description = "Saturate";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float C_Gamma
<
   string Description = "Gamma";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float C_Contrast
<
   string Description = "Contrast";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float C_Gain
<
   string Description = "Gain";
   string Group = "CYAN";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float C_Brightness
<
   string Description = "Brightness";
   string Group = "CYAN";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// MAGENTA_P

float4 M_TintColour
<
   string Description = "TintColour";
   string Group = "MAGENTA";
> = { 1.0, 1.0, 1.0, 1.0 };

float M_TintAmount
<
   string Description = "TintAmount";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float M_Saturate
<
   string Description = "Saturate";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float M_Gamma
<
   string Description = "Gamma";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float M_Contrast
<
   string Description = "Contrast";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float M_Gain
<
   string Description = "Gain";
   string Group = "MAGENTA";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float M_Brightness
<
   string Description = "Brightness";
   string Group = "MAGENTA";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

// YELLOW_P

float4 Y_TintColour
<
   string Description = "TintColour";
   string Group = "YELLOW";
> = { 1.0, 1.0, 1.0, 1.0 };

float Y_TintAmount
<
   string Description = "TintAmount";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Y_Saturate
<
   string Description = "Saturate";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float Y_Gamma
<
   string Description = "Gamma";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Y_Contrast
<
   string Description = "Contrast";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Y_Gain
<
   string Description = "Gain";
   string Group = "YELLOW";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Y_Brightness
<
   string Description = "Brightness";
   string Group = "YELLOW";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 Cs = tex2D (FgSampler, xy);

   float lum   = (Cs.r + Cs.g + Cs.b) / 3.0;
   float lum_1 = lum - 0.5;

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

   return lerp (Cs_M, Cs_Y, yellow);
}

//-----------------------------------------------------------------------------------------//
//  Technique
//-----------------------------------------------------------------------------------------//

technique RGBCMYcorrection
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
