// @Maintainer jwrl
// @Released 2018-04-05
// @Author quality
// @Created 2013-02-09
// @see https://www.lwks.com/media/kunena/attachments/6375/MotionBlur.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect motionblur.fx
//
// Modified 5 February 2016 by user jwrl.
// This effect was originally posted by Lightworks user quality.  It was converted for
// better ps_2_b compliance.
//
// Cross platform compatibility check 29 July 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Modified the code so that low values of Samples didn't make the video levels jump.
// Also added an offset adjustment to compensate for the subjective position shift seen
// with low values of that variable.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Modified by LW user jwrl 15 September 2018.
// Corrected a bug which could cause this effect to fail to compile.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Motion blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler InputSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

#define MAXSAMPLES 60.0

#pragma warning ( disable : 3571 )

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

float Samples
<
  string Description = "Samples";
  float MinVal = 0.0;
  float MaxVal = MAXSAMPLES;
> = MAXSAMPLES;

float Mix
<
    string Description = "Mix";
    float MinVal = 0.0;
    float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Pixel Shader
//-----------------------------------------------------------------------------------------//

float4 main (float2 uv : TEXCOORD1) : COLOR
{
   float4 original = tex2D (InputSampler, uv);
   float4 output = 0.0.xxxx;  

   float2 offset, xy = uv;

   int sampleVal = round (min (MAXSAMPLES, Samples));

   if ((Mix <= 0.0) || (sampleVal <= 0) || (Strength <= 0.0)) return original;

   sincos (radians (Angle), offset.y, offset.x);
   offset *= (Strength * 0.005);

   xy += (sampleVal < 2) ? 0.0.xx :
         (sampleVal > 2) ? offset : offset / 2.0;

   for (int i = 0; i < MAXSAMPLES; i++) {

      if (i < sampleVal) {
         output += tex2D (InputSampler, xy);
         xy -= offset;
      }
   }
    
   output /= sampleVal;

   return lerp (original, output, Mix);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE main ();
   }
}
