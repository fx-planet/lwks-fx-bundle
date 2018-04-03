// @Maintainer jwrl
// @Released 2018-03-31
// @Author quality
//--------------------------------------------------------------//
// This effect was originally posted by Lightworks user
// quality.  It was converted for better ps_2_0 compliance
// by user jwrl 5 February 2016.
//
// Cross platform compatibility check 29 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//
// Modified the code so that low values of Samples didn't make
// the video levels jump.  Also added an offset adjustment to
// compensate for the subjective position shift seen with low
// values of that variable.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Motion blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

float _Progress;

texture Input;

sampler InputSampler = sampler_state {
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Define parameters here.
//--------------------------------------------------------------//

#define MAXSAMPLES 60.0

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

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------

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

//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------

technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE main ();
   }
}
