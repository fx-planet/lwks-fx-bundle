// @Maintainer jwrl
// @Released 2021-08-31
// @Author quality
// @Created 2013-02-09
// @see https://www.lwks.com/media/kunena/attachments/6375/MotionBlur.png

/**
 A directional blur that can be used to simulate fast motion, whip pans and the like.

 NOTE: This effect previously had a means of setting the number of samples used to make
 the blur.  That made use of a forced return which is now blocked in current versions
 of Lightworks, and has now been removed.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MotionBlur.fx
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
   string Description = "Motion blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "A directional blur that can be used to simulate fast motion, whip pans and the like";
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

#define SAMPLES 60.0

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_Input, Mirror);

SetTargetMode (FixInp, InputSampler, Mirror);

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
> = 0.0;

float Mix
<
    string Description = "Mix";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_Input, uv); }

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 output = EMPTY;  

   if (Overflow (uv1)) return output;

   float4 original = tex2D (InputSampler, uv2);

   if ((Mix <= 0.0) || (Strength <= 0.0)) return original;

   float2 offset, xy = uv2;

   sincos (radians (Angle), offset.y, offset.x);
   offset *= (Strength * 0.005);
   offset.y *= _OutputAspectRatio;

   for (int i = 0; i < SAMPLES; i++) {
      output += tex2D (InputSampler, xy);
      xy -= offset;
   }
    
   output /= SAMPLES;

   return lerp (original, output, Mix);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass SinglePass ExecuteShader (ps_main)
}

