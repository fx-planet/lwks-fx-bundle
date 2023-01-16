// @Maintainer jwrl
// @Released 2023-01-11
// @Author jwrl
// @Created 2023-01-11

/**
 This is a diagnostic tool that can be used to display individual RGB channels, luminance,
 summed RGB, U, V and alpha channels.  The alpha channel is preserved for potential later
 use in other effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChannelDiags.fx
//
// Version history:
//
// Built 2023-01-11 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Channel diagnostics", "User", "Technical", "Can be used to display individual RGB channels, luminance, summed RGB, U, V and alpha channels", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (ColourSpace, "Colour space", kNoGroup, 1, "Rec-601 (Standard definition)|Rec-709 (High definition)|Rec-2020 (Ultra high definition)");
DeclareIntParam (SetTechnique, "Display channel", kNoGroup, 0, "Bypass|Luminance (Y)|RGB sum|Red|Green|Blue|Alpha|B-Y (U/Pb/Cb)|R-Y (V/Pr/Cr)");

DeclareBoolParam (Negative, "Display as negative", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float3 _Luma_matrix [3] = { { 0.2989, 0.5866, 0.1145 }, { 0.2126, 0.7152, 0.0722 },
                            { 0.2627, 0.678,  0.0593 } };

float _Cb_matrix [3] = { 0.564, 0.635, 0.5315 };
float _Cr_matrix [3] = { 0.713, 0.539, 0.6782 };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ChannelDiags_Bypass)
{
   float4 retval = ReadPixel (Inp, uv1);

   return Negative ? float4 (1.0.xxx - retval.rgb, retval.a) : retval;
}

DeclareEntryPoint (ChannelDiags_Y)
{
   float4 retval = ReadPixel (Inp, uv1);

   retval.rgb = dot (retval.rgb, _Luma_matrix [ColourSpace]).xxx;

   return Negative ? float4 (1.0.xxx - retval.rgb, retval.a) : retval;
}

DeclareEntryPoint (ChannelDiags_RGBsum)
{
   float4 retval = ReadPixel (Inp, uv1);

   retval.rgb = ((retval.r + retval.g + retval.b) / 3.0).xxx;

   return Negative ? float4 (1.0.xxx - retval.rgb, retval.a) : retval;
}

DeclareEntryPoint (ChannelDiags_Red)
{
   float4 retval = ReadPixel (Inp, uv1).rrra;

   return Negative ? float4 (1.0.xxx - retval.rgb, retval.a) : retval;
}

DeclareEntryPoint (ChannelDiags_Green)
{
   float4 retval = ReadPixel (Inp, uv1).ggga;

   return Negative ? float4 (1.0.xxx - retval.rgb, retval.a) : retval;
}

DeclareEntryPoint (ChannelDiags_Blue)
{
   float4 retval = ReadPixel (Inp, uv1).bbba;

   return Negative ? float4 (1.0.xxx - retval.rgb, retval.a) : retval;
}

DeclareEntryPoint (ChannelDiags_Alpha)
{
   float4 retval = ReadPixel (Inp, uv1).aaaa;

   return Negative ? float4 (1.0.xxx - retval.rgb, retval.a) : retval;
}

DeclareEntryPoint (ChannelDiags_Cb)
{
   float4 retval = ReadPixel (Inp, uv1);

   float luma = dot (retval.rgb, _Luma_matrix [ColourSpace]);

   luma = saturate (((luma - retval.b) * _Cb_matrix [ColourSpace]) + 0.5);

   if (Negative) luma = 1.0.xxx - retval.rgb;

   return float4 (luma.xxx, retval.a);
}

DeclareEntryPoint (ChannelDiags_Cr)
{
   float4 retval = ReadPixel (Inp, uv1);

   float luma = dot (retval.rgb, _Luma_matrix [ColourSpace]);

   luma = saturate (((luma - retval.r) * _Cr_matrix [ColourSpace]) + 0.5);

   if (Negative) luma = 1.0.xxx - retval.rgb;

   return float4 (luma.xxx, retval.a);
}

