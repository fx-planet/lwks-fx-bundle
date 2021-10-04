// @Maintainer jwrl
// @Released 2021-10-01
// @Author jwrl
// @Created 2021-10-01
// @see https://www.lwks.com/media/kunena/attachments/6375/MultiToner_640.png

/**
 Multiple toner aims to produce the effect of a range of chemical processes that
 can be applied to black and white prints.  The tones used are generic, and the
 black and white conversion approximates the spectral response of panchromatic
 film.

 The sepia toner is based on an existing effect, and closely matches the look of
 of photographic prints that have been compared with it.  The selenium toners
 have two presets because the actual colour produced is seriously affected by
 the chemistry of the paper used.   Bottom line: these colour values have been
 obtained empirically.  Even with the best care and attention given, how well the
 results match can only be subjective.

 I've had to rely on on-line reference images for the gold toner.  As far as I'm
 aware I've never actually seen one "in the flesh", so to speak.  If it's wrong
 I can only apologise.  Copper toning can vary from the reddish tones that you
 see here through to quite green or even blue depending on the print's age and
 how it has been stored.  I just picked a colour and contrast setting that had
 about the right look.  I've based the blue in the iron toner on the blue you
 see in blueprints, because the chemistry that produces that colour is identical
 to the chemistry in a treated photographic print.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MultiToner.fx
//
// Version history:
//
// Rewrite 2021-10-01 jwrl.
// Rebuild of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Multiple toner";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Select from sepia, selenium, gold, copper and ferro toners to simulate darkroom processes";
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

#define ExecuteShader(SHD) { PixelShader = compile PROFILE SHD (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LUMA       float3(0.217, 0.265, 0.518)  // A rough panchromatic profile

#define SEPIA      float3(0.732, 0.899, 1.0)
#define SELENIUM_1 float3(0.725, 0.950, 1.0)
#define SELENIUM_2 float3(0.744, 1.0, 0.871)
#define GOLD       float3(0.782, 0.983, 1.0)
#define COPPER     float3(0.604, 0.968, 1.0)
#define FERRO      float3(1.0, 0.776, 0.486)

//-----------------------------------------------------------------------------------------//
// Inputs and shaders
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Toner type";
   string Enum = "Sepia,Selenium 1,Selenium 2,Gold,Copper,Iron";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Tone
<
   string Group = "Toner settings";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Exposure
<
   string Group = "Toner settings";
   string Description = "Exposure";
   string Flags = "DisplayAsLiteral";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (SEPIA * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma), toner_mix);

   return float4 (lerp (retval.rgb, toner, Amount), retval.a);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (SELENIUM_1 * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.116), toner_mix);

   return float4 (lerp (retval.rgb, toner, Amount), retval.a);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (SELENIUM_2 * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.187), toner_mix);

   return float4 (lerp (retval.rgb, toner, Amount), retval.a);
}

float4 ps_main_3 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (GOLD * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.463), toner_mix);

   return float4 (lerp (retval.rgb, toner, Amount), retval.a);
}

float4 ps_main_4 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (COPPER * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.559), toner_mix);

   return float4 (lerp (retval.rgb, toner, Amount), retval.a);
}

float4 ps_main_5 (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = GetPixel (s_Input, uv);

   float gamma = (pow (clamp ((1.0 - Exposure) / 2.0, 1e-6, 1.0), 1.585) * 1.5) + 0.5;

   float3 toner = pow (retval.rgb, gamma * 1.375);

   toner = 1.0.xxx - (FERRO * pow (1.0 - dot (toner, LUMA), 2.8));

   float toner_mix = min (1.0, pow (2.0 * (Tone + toner.b), 4.0) * min (1.0, Tone * 1.5));

   gamma = 1.0 - (1.2 * max (0.0, Tone - 0.5));
   toner = lerp (toner.bbb, pow (toner, gamma * 1.408), toner_mix);

   return float4 (lerp (retval.rgb, toner, Amount), retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique MultiToner_0 { pass P_1 ExecuteShader (ps_main_0) }

technique MultiToner_1 { pass P_1 ExecuteShader (ps_main_1) }

technique MultiToner_2 { pass P_1 ExecuteShader (ps_main_2) }

technique MultiToner_3 { pass P_1 ExecuteShader (ps_main_3) }

technique MultiToner_4 { pass P_1 ExecuteShader (ps_main_4) }

technique MultiToner_5 { pass P_1 ExecuteShader (ps_main_5) }

