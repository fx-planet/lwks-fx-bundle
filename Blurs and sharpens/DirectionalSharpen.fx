// @Maintainer jwrl
// @Released 2021-08-31
// @Author jwrl
// @Created 2021-08-31
// @see https://www.lwks.com/media/kunena/attachments/6375/DirectionalSharpen_640.png

/**
 A directional unsharp mask.  Useful where directional stretching and motion blur must be
 compensated for.  The angle can only be adjusted through 180 degrees, because it uses a
 bidirectional blur.  Using that technique, 90 degrees and 270 degrees would give identical
 results.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalSharpen.fx
//
// Version history:
//
// Rewrite 2021-08-31 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Directional sharpen";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This is a directional unsharp mask useful where directional blurring must be compensated for";
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

#define LUMA_DOT  float3(1.1955,2.3464,0.4581)
#define GAMMA_VAL 1.666666667

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

SetInputMode (Inp, s_RawInp, Mirror);

SetTargetMode (FixInp, s_Input, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float BlurAngle
<
   string Description = "Blur angle";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 0.0;

float BlurWidth
<
   string Description = "Sample width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Threshold
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Tolerance
<
   string Description = "Tolerance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float EdgeGain
<
   string Description = "Edge gain";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Amount
<
   string Description = "Mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.15;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip
// geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_RawInp, uv); }

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   if (Overflow (uv1)) return EMPTY;

   float4 retval = tex2D (s_Input, uv2);
   float4 unblur = EMPTY;

   float2 offset, xy = uv2;

   if ((Amount <= 0.0) || (BlurWidth <= 0.0)) return retval;

   sincos (radians (BlurAngle), offset.y, offset.x);
   offset *= (BlurWidth * 0.0005);
   offset.y *= _OutputAspectRatio;

   xy += offset * 30.0;

   for (int i = 0; i < 60; i++) {
      unblur += tex2D (s_Input, xy);
      xy -= offset;
   }
    
   unblur /= 60.0;

   float sharpMask = dot (retval.rgb, LUMA_DOT);
   float maskGamma = min (1.15, 1.1 - min (1.05, EdgeGain)) * GAMMA_VAL;
   float maskGain  = Tolerance * 2.0;

   sharpMask -= dot (unblur.rgb, LUMA_DOT);
   maskGamma *= maskGamma;

   float sharpness = pow (max (0.0, sharpMask - Threshold), maskGamma);

   sharpness -= pow (max (0.0, -sharpMask - Threshold), maskGamma);
   sharpness *= maskGain;

   unblur = float4 (retval.rgb + sharpness.xxx, retval.a);

   return lerp (retval, unblur, Amount);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique DirectionalSharpen
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_main)
}

