// @Maintainer jwrl
// @Released 2021-08-31
// @Author khaver
// @Created 2012-01-23
// @see https://www.lwks.com/media/kunena/attachments/6375/ZoomBlur_640.png

/**
 A radial blur effect that simulates the motion of a zoom in or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Zoom_blur.fx
//
// Version history:
//
// Rewrite 2021-08-31 jwrl:
// Partial rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Zoom blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "A radial blur effect that simulates the motion of a zoom in or out";
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

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_RawInp, Mirror);

SetTargetMode (FixInp, InputSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CX
<
   string Description = "Center";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float CY
<
   string Description = "Center";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float BlurAmount
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float4 c = EMPTY;

   float2 Center = float2 (CX, 1.0 - CY);
   float2 xy = uv2 - Center;

   float scale;

   for (int i = 0; i < 41; i++) {
      scale = 1.0 - BlurAmount * (i / 40.0);
      c += tex2D (InputSampler, xy * scale + Center);
   }

   c /= 41.0;

   return c;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique ZoomBlur
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pass1 ExecuteShader (ps_main)
}

