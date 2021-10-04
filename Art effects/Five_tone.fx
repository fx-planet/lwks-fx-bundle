// @Maintainer jwrl
// @Released 2021-07-26
// @Author idealsceneprod (Val Gameiro)
// @Created 2014-12-24
// @see https://www.lwks.com/media/kunena/attachments/6375/FiveTone_640.png

/**
 Five tone (FivetoneFx.fx) is a posterization effect that extends the existing Lightworks
 Two Tone and Tri-Tone effects.  It reduces input video to five tonal values.  Blending and
 colour values are all adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Five_tone.fx
//
// Version history:
//
// Update 2021-07-26 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Five tone";
   string Category    = "Colour";
   string SubCategory = "Art Effects";
   string Notes       = "Extends the existing Lightworks Two Tone and Tri-Tone effects to provide five tonal values";
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

#define DeclareInput( TEXTURE, SAMPLER ) \
                                         \
   texture TEXTURE;                      \
                                         \
   sampler SAMPLER = sampler_state       \
   {                                     \
      Texture   = <TEXTURE>;             \
      AddressU  = ClampToEdge;           \
      AddressV  = ClampToEdge;           \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define DeclareTarget( TARGET, TSAMPLE ) \
                                         \
   texture TARGET : RenderColorTarget;   \
                                         \
   sampler TSAMPLE = sampler_state       \
   {                                     \
      Texture   = <TARGET>;              \
      AddressU  = Mirror;                \
      AddressV  = Mirror;                \
      MinFilter = Linear;                \
      MagFilter = Linear;                \
      MipFilter = Linear;                \
   }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

float _OutputHeight;
float _OutputWidth;

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0  / 64.0, 1.0  / 64.0 };  // See Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DeclareInput (Input, InputSampler);

DeclareTarget (ThresholdTexture, ThresholdSampler);
DeclareTarget (Blur1, BlurSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Level1
<
   string Description = "Threshold One";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.20;

float Level2
<
   string Description = "Threshold Two";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.40;

float Level3
<
   string Description = "Threshold Three";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.60;

float Level4
<
   string Description = "Threshold Four";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.80;

float BlendOpacity
<
   string Description = "Blend";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float4 DarkColour
<
   string Description = "Dark Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 1.0 };

float4 MidColour
<
   string Description = "Mid Dark Colour";
   bool SupportsAlpha = false;
> = { 0.3, 0.3, 0.3, 1.0 };

float4 MidColour2
<
   string Description = "Mid Colour";
   bool SupportsAlpha = false;
> = { 0.5, 0.5, 0.5, 1.0 };

float4 MidColour3
<
   string Description = "Mid Light Colour";
   bool SupportsAlpha = false;
> = { 0.7, 0.7, 0.7, 1.0 };

float4 LightColour
<
   string Description = "Light Colour";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 threshold_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 src1 = GetPixel (InputSampler, uv);
   float srcLum = ((src1.r * 0.3) + (src1.g * 0.59) + (src1.b * 0.11));

   if (srcLum < Level1) src1.rgb = BlendOpacity * DarkColour.rgb + (1.0 - BlendOpacity) * src1.rgb;
   else if ( srcLum < Level2 ) src1.rgb = BlendOpacity * MidColour.rgb + (1.0 - BlendOpacity) * src1.rgb;
   else if ( srcLum < Level3 ) src1.rgb = BlendOpacity * MidColour2.rgb + (1.0 - BlendOpacity) * src1.rgb;
   else if ( srcLum < Level4 ) src1.rgb = BlendOpacity * MidColour3.rgb + (1.0 - BlendOpacity) * src1.rgb;
   else src1.rgb = BlendOpacity * LightColour.rgb + (1.0 - BlendOpacity) * src1.rgb;

   return src1;
}

float4 blur1_ps_main (float2 uv : TEXCOORD2) : COLOR
{
   // Explicitly query BETWEEN pixels to get extra averaging

   float2 onePixAcross   = float2 (0.5 / _OutputWidth, 0.0);
   float2 twoPixAcross   = float2 (1.5 / _OutputWidth, 0.0);
   float2 threePixAcross = float2 (2.5 / _OutputWidth, 0.0);

   float4 keyPix = tex2D (ThresholdSampler, uv);
   float4 result = keyPix * blur [0];

   result += tex2D (ThresholdSampler, uv + onePixAcross)   * blur [1];
   result += tex2D (ThresholdSampler, uv - onePixAcross)   * blur [1];
   result += tex2D (ThresholdSampler, uv + twoPixAcross)   * blur [2];
   result += tex2D (ThresholdSampler, uv - twoPixAcross)   * blur [2];
   result += tex2D (ThresholdSampler, uv + threePixAcross) * blur [3];
   result += tex2D (ThresholdSampler, uv - threePixAcross) * blur [3];
   result.a = keyPix.a;

   return result;
}

float4 blur2_ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   // Explicitly query BETWEEN pixels to get extra averaging

   float2 onePixDown   = float2 (0.0, 0.5 / _OutputHeight);
   float2 twoPixDown   = float2 (0.0, 1.5 / _OutputHeight);
   float2 threePixDown = float2 (0.0, 2.5 / _OutputHeight);

   float4 source = GetPixel (InputSampler, uv1);
   float4 keyPix = tex2D (BlurSampler, uv2);

   float4 result = keyPix * blur [0];
   result += tex2D (BlurSampler, uv2 + onePixDown)   * blur [1];
   result += tex2D (BlurSampler, uv2 - onePixDown)   * blur [1];
   result += tex2D (BlurSampler, uv2 + twoPixDown)   * blur [2];
   result += tex2D (BlurSampler, uv2 - twoPixDown)   * blur [2];
   result += tex2D (BlurSampler, uv2 + threePixDown) * blur [3];
   result += tex2D (BlurSampler, uv2 - threePixDown) * blur [3];
   result.a = keyPix.a;

   if (Overflow (uv1)) result = EMPTY;

   result = lerp (source, result, source.a);
   result.a = source.a;

   return result;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique FiveTone
{
   pass ThresholdPass < string Script = "RenderColorTarget0 = ThresholdTexture;"; > ExecuteShader (threshold_main)
   pass BlurX < string Script = "RenderColorTarget0 = Blur1;"; > ExecuteShader (blur1_ps_main)
   pass BlurY ExecuteShader (blur2_ps_main)
}

