// @Maintainer jwrl
// @Released 2020-03-22
// @Author jwrl
// @Created 2019-05-30
// @see https://www.lwks.com/media/kunena/attachments/6375/FastBleachBypass_640.png

/**
 This is another effect that emulates the altered contrast and saturation produced when the
 silver bleach step is skipped or reduced in classical colour film processing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FastBleachBypass.fx
//
// MSI's earlier bleach bypass effect was based on sample code provided by Nvidia.  This
// version is all original and designed from first principles.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fast bleach bypass";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "Mimics the contrast and saturation changes caused by skipping film bleach processing";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler InpSampler = sampler_state { Texture = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Process stage";
   string Enum = "Negative, Print";
> = 0;

float Amount
<
   string Description = "Bypass level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Declarations and definitions
//-----------------------------------------------------------------------------------------//

#define RGB_VAL 0.33333333.xxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main_neg (float2 uv : TEXCOORD1) : COLOR
{
   float4 Input = tex2D (InpSampler, uv);

   Input.rgb = 1.0.xxx - Input.rgb;

   float4 retval = Input;

   float mono  = dot (RGB_VAL, retval.rgb);
   float level = (1.0 - mono) * Amount * 2.0;

   retval.rgb = pow (retval.rgb, 0.5);
   retval.rgb = 1.0.xxx - lerp (Input.rgb, retval.rgb * mono, level);

   return retval;
}

float4 main_pos (float2 uv : TEXCOORD1) : COLOR
{
   float4 Input  = tex2D (InpSampler, uv);
   float4 retval = Input;

   float mono  = dot (RGB_VAL, retval.rgb);
   float level = (1.0 - mono) * Amount * 2.0;

   retval.rgb = pow (retval.rgb, 0.5);
   retval.rgb = lerp (Input.rgb, retval.rgb * mono, level);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FastBleachBypass_1
{
   pass P1 { PixelShader = compile PROFILE main_neg (); }
}

technique FastBleachBypass_2
{
   pass P1 { PixelShader = compile PROFILE main_pos (); }
}

