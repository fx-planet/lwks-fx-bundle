// @Maintainer jwrl
// @Released 2021-07-26
// @Author khaver
// @Created 2012-08-21
// @see https://www.lwks.com/media/kunena/attachments/6375/Sketch_640.png

/**
 Sketch (SketchFx.fx) simulates a sketch from a standard video source.  An extremely wide
 range of adjustment parameters have been provided which should meet most needs.  Border
 line colour is adjustable, as are the individual thresholds for each RGB channel.

 Shadow area colour can also be adjusted for best effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SketchFx.fx
//
// Version history:
//
// Update 2021-07-26 jwrl.
// Update of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 11 July 2020:
// Various changes to better support cross platform versions.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Sketch";
   string Category    = "Stylize";
   string SubCategory = "Art Effects";
   string Notes       = "Converts any standard video source or graphic to a simple sketch";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
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

float _OutputWidth;
float _OutputHeight;

int GX [3][3] =
{
    { -1, +0, +1 },
    { -2, +0, +2 },
    { -1, +0, +1 },
};

int GY [3][3] =
{
    { +1, +2, +1 },
    { +0, +0, +0 },
    { -1, -2, -1 },
};

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Input, s_RawInp);

DefineTarget (FixInp,  SourceTextureSampler);
DefineTarget (ThresholdTexture, ThresholdSampler);
DefineTarget (Blur1, BlurSampler1);
DefineTarget (Blur2, BlurSampler2);
DefineTarget (Target, TarSamp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Invert
<
   string Description = "Invert All";
> = false;

float4 BorderLineColor
<
   string Description = "Color";
   string Group = "Lines";
   bool SupportsAlpha = true;
> = { 0.0, 0.0, 0.0, 1.0 };

float Strength
<
   string Description = "Strength";
   string Group = "Lines";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 1.0;

bool InvLines
<
   string Description = "Invert";
   string Group = "Lines";
> = false;

float RLevel
<
   string Description = "Red Threshold";
   string Group = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3;

float GLevel
<
   string Description = "Green Threshold";
   string Group = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.59;

float BLevel
<
   string Description = "Blue Threshold";
   string Group = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.11;

float Level
<
   string Description = "Shadow Amount";
   string Group = "Background";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 DarkColor
<
   string Description = "Shadow Color";
   string Group = "Background";
   bool SupportsAlpha = true;
> = { 0.5, 0.5, 0.5, 1.0 };

float4 LightColor
<
   string Description = "Highlight Color";
   string Group = "Background";
   bool SupportsAlpha = true;
> = { 1.0, 1.0, 1.0, 1.0 };

bool Swap
<
   string Description = "Swap";
   string Group = "Background";
> = false;

bool InvBack
<
   string Description = "Invert";
   string Group = "Background";
> = false;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 threshold_main (float2 xy : TEXCOORD2) : COLOR
{
   float4 src1 = tex2D (SourceTextureSampler, xy);
   float srcLum = saturate ((src1.r * RLevel) + (src1.g * GLevel) + (src1.b * BLevel));

   if (Swap) src1.rgb = (srcLum <= Level) ? LightColor.rgb : DarkColor.rgb;
   else src1.rgb = (srcLum > Level) ? LightColor.rgb : DarkColor.rgb;

   if (InvBack) src1 = 1.0.xxxx - src1;

   return src1;
}

float4 blurX_main (float2 xy : TEXCOORD2) : COLOR
{
   float one   = 1.0 / _OutputWidth;
   float tap1  = xy.x + one;
   float ntap1 = xy.x - one;

   float4 blurred = tex2D (ThresholdSampler, xy);

   blurred += tex2D (ThresholdSampler, float2 (tap1,  xy.y));
   blurred += tex2D (ThresholdSampler, float2 (ntap1, xy.y));

   return blurred / 3.0;
}

float4 blurY_main (float2 xy : TEXCOORD2) : COLOR
{
   float one  = 1.0 / _OutputHeight;
   float tap1 = xy.y + one;
   float ntap1 = xy.y - one;

   float4 ret = tex2D (BlurSampler1, xy);

   ret += tex2D (BlurSampler1, float2 (xy.x, tap1));
   ret += tex2D (BlurSampler1, float2 (xy.x, ntap1));

   return ret / 3.0;
}

float4 EdgedetectGrayscaleFunc (float2 tex : TEXCOORD2) : COLOR
{
   float4 bl = BorderLineColor;

   float2 PIXEL_SIZE = 1.0 / float2 (_OutputWidth, _OutputHeight);
   float2 HALF_PIX = PIXEL_SIZE / 2.0;
   float2 xy = 0.0.xx;

   float sumX = 0.0;
   float sumY = 0.0;

   for (int i = -1; i <= 1; i++) {

      for (int j = -1; j <= 1; j++) {
         float2 ntex = float2 (i * PIXEL_SIZE.x, j * PIXEL_SIZE.y);
         float val = dot (tex2D (SourceTextureSampler, tex + ntex).rgb, float3 (0.3, 0.59, 0.11));

         sumX += val * GX [i + 1][j + 1] * Strength;
         sumY += val * GY [i + 1][j + 1] * Strength;
      }
   }

   float4 color = 1.0.xxxx - (saturate (abs (sumX) + abs (sumY)) * (1.0.xxxx - bl));
   color.a = (color.r + color.g + color.b) / 3.0;

   if (InvLines) color.rgb = 1.0.xxx - color.rgb;

   return color;
}

float4 Fix (float2 uv : TEXCOORD1, float2 tex : TEXCOORD2) : COLOR
{
   float alpha = tex2D (SourceTextureSampler, tex).a;

   float2 PIXEL_SIZE = 1.0 / float2 (_OutputWidth, _OutputHeight);
   float2 HALF_PIX = PIXEL_SIZE / 2.0;

   float4 lines = tex2D (TarSamp, tex - (PIXEL_SIZE * 2.0));
   float4 back = tex2D (BlurSampler2, tex - (PIXEL_SIZE * 1.5));

   if (Invert) return 1.0.xxxx - lerp (lines, back, lines.a);

   float4 retval = (Overflow (uv)) ? EMPTY : lerp (lines, back, lines.a);

   return lerp (EMPTY, retval, alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique EdgeDetect
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass ThresholdPass < string Script = "RenderColorTarget0 = ThresholdTexture;"; > ExecuteShader (threshold_main)
   pass BlurX < string Script = "RenderColorTarget0 = Blur1;"; > ExecuteShader (blurX_main)
   pass BlurY < string Script = "RenderColorTarget0 = Blur2;"; > ExecuteShader (blurY_main)
   pass one < string Script = "RenderColorTarget0 = Target;"; > ExecuteShader (EdgedetectGrayscaleFunc)
   pass two ExecuteShader (Fix)
}

