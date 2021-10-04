// @Maintainer jwrl
// @Released 2021-09-30
// @Author rhinox202
// @Created 2012-11-21
// @see https://www.lwks.com/media/kunena/attachments/6375/Border_640.png

/**
 Border creates a coloured hard border over a cropped image.  The border is created
 inside the image being bordered, meaning that some of the image content will be lost.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BorderFx.fx
//
// Version history:
//
// Update 2021-09-30 jwrl:
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2018-12-23:
// Various updates and patches for cross platform support.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Border";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "Creates a coloured hard border over a cropped image.  The border is created inside the image being bordered";
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

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 BorderC
<
   string Description = "Color";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

float BorderM
<
   string Description = "Master";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float BorderT
<
   string Description = "Top";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 0.5;

float BorderR
<
   string Description = "Right";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 0.5;

float BorderB
<
   string Description = "Bottom";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 0.5;

float BorderL
<
   string Description = "Left";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 ret = GetPixel (s_Input, uv);
   
   float Border_T = BorderM * BorderT / 10.0;
   float Border_R = 1.0 - (BorderM * BorderR / (_OutputAspectRatio * 10.0));
   float Border_B = 1.0 - (BorderM * BorderB / 10.0);
   float Border_L = BorderM * BorderL / (_OutputAspectRatio * 10.0);
   
   if ((uv.y <= Border_T) || (uv.x >= Border_R) || (uv.y >=  Border_B) || (uv.x <= Border_L))
   {
      return BorderC;
   }
   
   return ret;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Border
{
   pass P_1 ExecuteShader (ps_main)
}

