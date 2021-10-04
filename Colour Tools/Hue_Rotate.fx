// @Maintainer jwrl
// @Released 2021-08-18
// @Author gr00by
// @Created 2016-06-14
// @OriginalAuthor "Mark Ransom"
// @see https://www.lwks.com/media/kunena/attachments/6375/HueRotate_640.png

/**
 A quick method to correct hue errors on archival NTSC media and the like.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Hue_Rotate.fx
//
// This code is based on the Mark Ransom alghoritm written in Python and published on:
// http://stackoverflow.com/a/8510751/512594
//
// The template of this file is based on TwoAxis.fx by Lightworks user jwrl.
//
// Version history:
//
// Update 2021-08-18 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Hue rotate";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "A quick method to correct hue errors on archival NTSC media and the like";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

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

#define PI         3.14159

#define ONE_THIRD  0.33333

#define SQRT_THIRD 0.57735

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Hue
<
   string Description = "Hue";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float c, s;

   sincos (Hue * PI, s, c);
   
   float4 rMat =float4 (c + ONE_THIRD * (1.0 - c), ONE_THIRD * (1.0 - c) - SQRT_THIRD * s, ONE_THIRD * (1.0 - c) + SQRT_THIRD * s, 1.0);
   float4 gMat =float4 (ONE_THIRD * (1.0 - c) + SQRT_THIRD * s, c + ONE_THIRD * (1.0 - c), ONE_THIRD * (1.0 - c) - SQRT_THIRD * s, 1.0);
   float4 bMat =float4 (ONE_THIRD * (1.0 - c) - SQRT_THIRD * s, ONE_THIRD * (1.0 - c) + SQRT_THIRD * s, c + ONE_THIRD * (1.0 - c), 1.0);

   float4 Image = GetPixel (s_Input, xy);

   float4 retval = float4 (
      Image.r * rMat.r + Image.g * rMat.g + Image.b * rMat.b,
      Image.r * gMat.r + Image.g * gMat.g + Image.b * gMat.b,
      Image.r * bMat.r + Image.g * bMat.g + Image.b * bMat.b,
      Image.a);

   return saturate (retval);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ColourTemp
{
   pass pass_one ExecuteShader (ps_main)
}

