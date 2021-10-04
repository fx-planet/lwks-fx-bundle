// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/SoftMotionBlur_640.png

/**
 This blur is actually a simple directional blur.  It is extremely soft because it uses a
 radially-sampled blur engine.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftMotionBlur.fx
//
// Version history:
//
// Rewrite 2021-08-31 jwrl:
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Soft motion blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This effect gives a very smooth, soft directional blur";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define Execute2param(SHD,P1,P2) { PixelShader = compile PROFILE SHD (P1, P2); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define DIVISOR 18.5

#define SCALE_1 36
#define SCALE_2 108
#define SCALE_3 324

#define WEIGHT  1.0
#define W_DIFF  0.0277778

#define PI      3.1415927

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Inp, s_RawInp, Mirror);

SetTargetMode (FixInp, s_Input, Mirror);

SetTargetMode (blur_1, s_Blur_1, Mirror);
SetTargetMode (blur_2, s_Blur_2, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Length
<
   string Description = "Blur length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Angle
<
   string Description = "Blur direction";
   float MinVal = 0.0;
   float MaxVal = 360.0;
> = 180.0;

float Amount
<
   string Description = "Blur density";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_Blur (float2 uv : TEXCOORD2, uniform sampler blurSampler, uniform int scale) : COLOR
{
   if ((Amount == 0.0) || (Length == 0.0)) return tex2D (s_Input, uv);

   float4 retval = EMPTY;

   float S, C, weight = WEIGHT;

   sincos (PI * (Angle / 180.0), S, C);

   float2 xy1 = uv;
   float2 xy2 = float2 (-C, -S * _OutputAspectRatio) * (Length / scale);

   for (int i = 0; i < 36; i++) {
      retval += tex2D (blurSampler, xy1) * weight;
      weight -= W_DIFF;
      xy1 += xy2;
   }

   return retval / DIVISOR;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float offset = 0.7 - (Length / 2.7777778);
   float adjust = 1.0 + (Length / 1.5);

   float4 blurry = tex2D (s_Blur_1, uv2);
   float4 retval = lerp (blurry, float4 (((blurry.rgb - offset.xxx) * adjust) + offset.xxx, blurry.a), 0.1);

   return lerp (tex2D (s_Input, uv2), retval, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique soft_motion_blur
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1
   < string Script = "RenderColorTarget0 = blur_1;"; > Execute2param (ps_Blur, s_Input, SCALE_1)
   pass P_2
   < string Script = "RenderColorTarget0 = blur_2;"; > Execute2param (ps_Blur, s_Blur_1, SCALE_2)
   pass P_3
   < string Script = "RenderColorTarget0 = blur_1;"; > Execute2param (ps_Blur, s_Blur_2, SCALE_3)
   pass P_4 ExecuteShader (ps_main)
}

