// @Maintainer jwrl
// @Released 2021-10-28
// @Author juhartik
// @AuthorEmail juha@linearteam.org
// @Created 2016-05-09
// @see https://www.lwks.com/media/kunena/attachments/6375/JHshowHiLo_640.png

/**
 This effect blinks extreme blacks and whites.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ShowHiLo.fx
//
// JH Analysis Show Hi/Lo v1.0 - Juha Hartikainen - juha@linearteam.org - Blinks extreme
// darks/highlights.
//
// Version history:
//
// Update 2021-10-28 jwrl.
// Updated the original effect to better support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Show highs and lows";
   string Category    = "User";
   string SubCategory = "Technical";
   string Notes       = "This effect blinks blacks and whites that exceed preset levels";
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

float _Length;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, FgSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float LoLimit
<
   string Description = "Low Limit";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float HiLimit
<
   string Description = "High Limit";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.95;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 MainPS (float2 xy : TEXCOORD1) : COLOR
{
   float4 color = GetPixel (FgSampler, xy);

   float weight = (color.r + color.g + color.b) / 3.0;

   if ((weight <= LoLimit) || (weight >= HiLimit))
      color.rgb = frac (_Progress * _Length * 3.0) > 0.5 ? 1.0.xxx : 0.0.xxx;

   return color;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ShowHiLo { pass p0 ExecuteShader (MainPS) }

