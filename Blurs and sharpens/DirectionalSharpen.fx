// @Maintainer jwrl
// @Released 2019-01-10
// @Author jwrl
// @Created 2019-01-10
// @see https://www.lwks.com/media/kunena/attachments/6375/DirectionalSharpen_640.png

/**
A directional unsharp mask.  Useful where directional stretching and motion blur must be
compensated for.  The angle can only be adjusted through 180 degrees, because it uses a
bidirectional blur.  Using that technique, 90 degrees and 270 degrees would give identical
results.

NOTE: This version won't run or compile on Windows' Lightworks version 14.0 or earlier.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalSharpen.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Directional sharpen";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This is a directional unsharp mask useful where directional blurring must be compensated for";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state {
   Texture   = <Inp>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float BlurAngle
<
   string Description = "Blur angle";
   float MinVal = 0.00;
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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA_DOT  float3(1.1955,2.3464,0.4581)
#define GAMMA_VAL 1.666666667

//-----------------------------------------------------------------------------------------//
// Pixel Shader
//-----------------------------------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Input, uv);
   float4 unblur = 0.0.xxxx;  

   float2 offset, xy = uv;

   if ((Amount <= 0.0) || (BlurWidth <= 0.0)) return retval;

   sincos (radians (BlurAngle), offset.y, offset.x);
   offset *= (BlurWidth * 0.0005);

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
   pass P_1 { PixelShader = compile PROFILE main (); }
}
