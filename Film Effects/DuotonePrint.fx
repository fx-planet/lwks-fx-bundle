// @Maintainer jwrl
// @Released 2021-10-01
// @Author jwrl
// @Created 2021-10-01
// @see https://www.lwks.com/media/kunena/attachments/6375/Duotone_640.png

/**
 This simulates the effect of the old Duotone film colour process.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DuotonePrint.fx
//
// Version history:
//
// Rewrite 2021-10-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Duotone print";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "This simulates the look of the old Duotone colour film process";
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

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define R_ORG  1.4088
#define G_ORG  0.5912

#define G_BGN  1.7472
#define B_BGN  0.2528

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Profile
<
   string Description = "Colour profile";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 1.0;

float Curve
<
   string Description = "Dye curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.4;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float gamma = (Curve > 0.0) ? 1.0 - Curve * 0.2 : 1.0;
   float luma  = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));

   float4 altret = float2 (luma, retval.a).xxxy;
   float4 desat  = altret;

   float orange = dot (retval.rg, float2 (G_ORG, R_ORG));
   float cyan   = dot (retval.gb, float2 (G_BGN, B_BGN));

   altret.r = orange - luma;
   altret.b = cyan - luma;

   retval.r    = orange / 2.0;
   retval.b    = cyan / 2.0;
   luma        = dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   retval.rgb += retval.rgb - luma.xxx;

   retval = saturate (lerp (altret, retval, Profile));
   retval = pow (retval, gamma);

   return lerp (desat, retval, Saturation * 4.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DuotonePrint
{
   pass P_1 ExecuteShader (ps_main)
}

