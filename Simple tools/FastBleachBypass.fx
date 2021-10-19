// @Maintainer jwrl
// @Released 2021-10-19
// @Author jwrl
// @Created 2021-10-19
// @see https://www.lwks.com/media/kunena/attachments/6375/FastBleachBypassRev_640.png

/**
 This is another effect that emulates the altered contrast and saturation produced when the
 silver bleach step is skipped or reduced in classical colour film processing.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FastBleachBypass.fx
//
// Version history:
//
// Rewrite 2021-10-19 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fast bleach bypass";
   string Category    = "Colour";
   string SubCategory = "Simple tools";
   string Notes       = "Mimics the contrast and saturation changes caused by skipping film bleach processing";
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

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define NEG    0.33333333.xxx

#define POS    float3(0.217, 0.265, 0.518)

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_main_neg (float2 uv : TEXCOORD2) : COLOR
{
   float4 Input = saturate (tex2D (s_Input, uv));

   float amnt = Amount * 0.75;
   float prof = 1.0 / (1.0 + amnt);
   float luma = pow (dot (NEG, Input.rgb), 1.0 + (Amount * 0.15));
   float mono = abs ((luma * 2.0) - 1.0);

   mono = pow (mono, prof) / 2.0;
   luma = (luma > 0.5) ? 0.5 + mono : 0.5 - mono;

   return float4 (saturate (lerp (Input.rgb, luma.xxx, amnt)), Input.a);
}

float4 ps_main_pos (float2 uv : TEXCOORD2) : COLOR
{
   float4 Input = saturate (tex2D (s_Input, uv));

   float amnt = Amount * 0.75;
   float prof = 1.0 / (1.0 + amnt);
   float luma = pow (dot (POS, Input.rgb), 1.0 - (Amount * 0.15));
   float mono = abs ((luma * 2.0) - 1.0);

   mono = pow (mono, prof) / 2.0;
   luma = (luma > 0.5) ? 0.5 + mono : 0.5 - mono;

   return float4 (saturate (lerp (Input.rgb, luma.xxx, amnt)), Input.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FastBleachBypass_0
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_neg)
}

technique FastBleachBypass_1
{
   pass P_1 < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_2 ExecuteShader (ps_main_pos)
}

