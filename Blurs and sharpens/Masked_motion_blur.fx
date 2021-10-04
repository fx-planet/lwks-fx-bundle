// @Maintainer jwrl
// @Released 2021-08-31
// @Author baopao
// @Created 2015-10-04
// @see https://www.lwks.com/media/kunena/attachments/6375/MaskedMotionBlur_640.png

/**
 This is an extremely strong directional blur.  The blur angle can be adjusted through
 a full 360 degrees, and sampling can be adjusted to range from a succession of discrete
 images to a very smooth blur.  An external mask input is available to control where the
 mask appears.

 NOTE: This effect previously had a means of setting the number of samples used to make
 the blur.  That made use of a forced return which is now blocked in current versions
 of Lightworks, and has now been removed.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Masked_motion_blur.fx
//
// Version history:
//
// Updated 2021-08-31 jwrl:
// Partial rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Masked motion blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "An extremely strong directional blur with an external mask input";
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

#define EMPTY 0.0.xxxx
#define WHITE 1.0.xxxx

#define SAMPLES 60
#define DIVISOR 61.0

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_Input, Mirror);
SetInputMode (Mask, s_Mask, Mirror);

SetTargetMode (FixInp, InputSampler, Mirror);
SetTargetMode (FixMask, MaskSampler, Mirror);

SetTargetMode (blurInput, blurSampler, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Angle
<
   string Description = "Angle";
   float MinVal = 0.00;
   float MaxVal = 360.0;
> = 0.0;

float Strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Mix
<
   string Description = "Mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool invertMask
<
   string Description = "Invert mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the input and mask timelines to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_Input, uv); }
float4 ps_initMask (float2 uv : TEXCOORD2) : COLOR { return tex2D (s_Mask, uv); }

float4 ps_blur (float2 uv : TEXCOORD3) : COLOR
{
   float4 output = tex2D (InputSampler, uv);

   if (Strength == 0.0) return output;

   float4 Mask = invertMask ? tex2D (MaskSampler, uv) : WHITE - tex2D (MaskSampler, uv);

   float2 offset, xy = uv;

   float OutMask = dot (Mask.rgb, float3 (0.3, 0.59, 0.11));

   sincos (radians (Angle), offset.y, offset.x);
   offset *= (OutMask * Strength * 0.6) / SAMPLES;
   offset.y *= _OutputAspectRatio;

   for (int i = 0; i < SAMPLES; i++) {
      output += tex2D (InputSampler, xy);
      xy -= offset;
   }

   output /= DIVISOR;

   return output;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float4 retval = tex2D (InputSampler, uv3);
   float4 blurry = tex2D (blurSampler, uv3);

   if (Strength > 0.0) {
      float4 Mask = invertMask ? tex2D (MaskSampler, uv3) : WHITE - tex2D (MaskSampler, uv3);

      float2 offset, xy = uv3;

      float OutMask = dot (Mask.rgb, float3 (0.3, 0.59, 0.11));

      sincos (radians (Angle), offset.y, offset.x);
      offset *= (OutMask * Strength * 0.6) / SAMPLES;
      offset.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         blurry += tex2D (blurSampler, xy);
         xy -= offset;
      }

      blurry /= DIVISOR;
   }

   return lerp (retval, blurry, Mix);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pmk < string Script = "RenderColorTarget0 = FixMask;"; > ExecuteShader (ps_initMask)
   pass pass_one < string Script = "RenderColorTarget0 = blurInput;"; > ExecuteShader (ps_blur)
   pass pass_two ExecuteShader (ps_main)
}

