// @Maintainer jwrl
// @Released 2023-01-12
// @Author juhartik
// @Created 2011-08-01

/**
 This old monitor effect is black and white with scan lines, which are fully adjustable.
 NOTE:  Because this effect needs to be able to precisely set line widths no matter
 what the original clip size or aspect ratio is it has not been possible to make it
 truly resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OldMonitor.fx
// 
// JH Stylize Vignette v1.0 - Juha Hartikainen - juha@linearteam.org - Emulates old
// Hercules monitor
//
// Version history:
//
// Updated 2023-01-12 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Old monitor", "Stylize", "Video artefacts", "This old monitor effect gives a black and white image with fully adjustable scan lines", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareColourParam (LineColor, "Scanline Color", kNoGroup, kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (LineCount, "Scanline Count", kNoGroup, kNoFlags, 300.0, 100.0, 1080.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define _PI 3.14159265

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (OldMonitor)
{
   float4 color = ReadPixel (Input, uv1);

   float intensity = (color.r + color.g + color.b) / 3.0;
   float multiplier = (sin (_PI * uv1.y * LineCount) + 1.0) / 2.0;

   return float4 (LineColor * intensity * multiplier.xxx, color.a);
}

