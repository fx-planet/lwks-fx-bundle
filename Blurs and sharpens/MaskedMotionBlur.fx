// @Maintainer jwrl
// @Released 2018-04-05
// @Author baopao
// 
// @see https://www.lwks.com/media/kunena/attachments/6375/MmotionBlur_1.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect MaskedMotionBlur.fx
//
// This is an extremely strong directional blur.  The blur angle can be adjusted through
// a full 360 degrees, and sampling can be adjusted to range from a succession of
// discrete images to smooth blur.  An external mask input is available to control where
// the mask appears.
//
//  Cross-platform conversion by jwrl April 28 2016.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Masked Motion Blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;
texture Mask;

texture blurInput : RenderColorTarget;
texture mainInput : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler InputSampler = sampler_state {
	Texture = <Input>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler MaskSampler = sampler_state {
	Texture = <Mask>;
	AddressU = Mirror;
	AddressV = Mirror;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler blurSampler = sampler_state
{
   Texture = <blurInput>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler mainSampler = sampler_state
{
   Texture = <mainInput>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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

float InputSamples
<
   string Description = "Samples";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define MAXSAMPLES 60

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 pre_blur (float2 uv : TEXCOORD1) : COLOR
{
   return tex2D (InputSampler, uv);
}

float4 ps_blur (float2 uv : TEXCOORD1) : COLOR
{
   if (Strength == 0.0) return tex2D (InputSampler, uv);

   float4 Mask = tex2D (MaskSampler, uv);
   float4 output = tex2D (blurSampler, uv);
   float2 offset, xy = uv;

   if (!invertMask) Mask = 1.0.xxxx - Mask;

   float OutMask = dot (Mask.rgb, float3 (0.3, 0.59, 0.11));

   int Samples = int (1.0 + (InputSamples * 59.0));

   sincos (radians (Angle), offset.y, offset.x);
   offset *= (OutMask * Strength * 0.6) / Samples;

   for (int i = 0; i < MAXSAMPLES; i++) {

      if (i < Samples) output += tex2D (blurSampler, xy);

      xy -= offset;
   }

   Samples++;
   output /= Samples;

   return output;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (InputSampler, uv);
   float4 blurry = tex2D (mainSampler, uv);

   return lerp (retval, blurry, Mix);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass pass_one
   <
      string Script = "RenderColorTarget0 = blurInput;";
   >
   {
      PixelShader = compile PROFILE pre_blur ();
   }

   pass pass_two
   <
      string Script = "RenderColorTarget0 = blurInput;";
   >
   {
      PixelShader = compile PROFILE ps_blur ();
   }

   pass pass_three
   <
      string Script = "RenderColorTarget0 = mainInput;";
   >
   {
      PixelShader = compile PROFILE ps_blur ();
   }

   pass pass_four
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
