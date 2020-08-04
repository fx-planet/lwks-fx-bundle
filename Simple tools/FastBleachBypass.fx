// @Maintainer jwrl
// @Released 2020-08-04
// @Author jwrl
// @Created 2019-05-30
// @see https://www.lwks.com/media/kunena/attachments/6375/FastBleachBypassRev_640.png

/**
 This is another effect that emulates the altered contrast and saturation produced when the
 silver bleach step is skipped or reduced in classical colour film processing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FastBleachBypass.fx
//
// MSI's earlier bleach bypass effect was based on sample code provided by Nvidia.  This
// version is all original and designed from first principles.
//
// Rewrite jwrl 2020-08-04:
// Never very happy with any of the previous attempts, this is yet another rewrite of the
// bleach bypass effect.  The negative version has the S-curve biassed towards the blacks
// and averages the RGB components to create the desaturated image.  The print version
// biasses the S-curve towards whites, and uses an empirically derived conversion profile
// to create the desaturated image.  As it is now it feels pretty right.
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
   string Enum = "Negative,Print";
> = 0;

float Amount
<
   string Description = "Bypass level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Declarations and definitions
//-----------------------------------------------------------------------------------------//

#define NEG    0.33333333.xxx

#define POS    float3(0.217, 0.265, 0.518)

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main_neg (float2 uv : TEXCOORD1) : COLOR
{
   float4 Input = tex2D (InpSampler, uv);

   float amnt = Amount * 0.75;
   float prof = 1.0 / (1.0 + amnt);
   float luma = pow (dot (NEG, Input.rgb), 1.0 + (Amount * 0.15));
   float mono = abs ((luma * 2.0) - 1.0);

   mono = pow (mono, prof) / 2.0;
   luma = (luma > 0.5) ? 0.5 + mono : 0.5 - mono;

   return float4 (lerp (Input.rgb, luma.xxx, amnt), Input.a);
}

float4 main_pos (float2 uv : TEXCOORD1) : COLOR
{
   float4 Input = tex2D (InpSampler, uv);

   float amnt = Amount * 0.75;
   float prof = 1.0 / (1.0 + amnt);
   float luma = pow (dot (POS, Input.rgb), 1.0 - (Amount * 0.15));
   float mono = abs ((luma * 2.0) - 1.0);

   mono = pow (mono, prof) / 2.0;
   luma = (luma > 0.5) ? 0.5 + mono : 0.5 - mono;

   return float4 (lerp (Input.rgb, luma.xxx, amnt), Input.a);
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
