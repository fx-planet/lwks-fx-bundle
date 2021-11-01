// @Maintainer jwrl
// @Released 2021-11-01
// @Author juhartik
// @Created 2011-08-01
// @see https://www.lwks.com/media/kunena/attachments/6375/jh_stylize_oldmonitor_640.png

/**
 This old monitor effect is black and white with scan lines, which are fully adjustable.
 NOTE:  Because this effect needs to be able to precisely set line widths no matter
 what the original clip size or aspect ratio is it has not been possible to make it
 truly resolution independent.  What it does is lock the clip resolution to sequence
 resolution instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OldMonitor.fx
// 
// JH Stylize Vignette v1.0 - Juha Hartikainen - juha@linearteam.org - Emulates old
// Hercules monitor
//
// Version history:
//
// Update 2021-11-01 jwrl.
// Updated the original effect to better support LW 2021 and higher.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Old monitor";      
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "This old monitor effect gives a black and white image with fully adjustable scan lines";
   bool CanSize       = false;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define _PI 3.14159265

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 LineColor
<
   string Description = "Scanline Color";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

float LineCount
<
   string Description = "Scanline Count";
   float MinVal       = 100.0;
   float MaxVal       = 1080.0;
> = 300.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 OldMonitorPS (float2 uv : TEXCOORD1) : COLOR
{
   float4 color = GetPixel (s_Input, uv);

   float intensity = (color.r + color.g + color.b) / 3.0;
   float multiplier = (sin (_PI * uv.y * LineCount) + 1.0) / 2.0;

   return float4 (LineColor * intensity * multiplier.xxx, color.a);
}

//-----------------------------------------------------------------------------------------//
//  Techniques
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique { pass p0 ExecuteShader (OldMonitorPS) }

