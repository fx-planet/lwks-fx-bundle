// @Maintainer jwrl
// @Released 2021-08-31
// @Author khaver
// @Created 2011-08-30
// @see https://www.lwks.com/media/kunena/attachments/6375/MaskedBlur_640.png

/**
 This is a 3 pass 13 tap circular kernel blur.  The blur can be masked using the alpha
 channel or the luminance value of the source video or another video track.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MaskedBlur.fx
//
// Version history:
//
// Updated 2021-08-31 jwrl:
// Partial rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Masked blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "The blur can be masked using the source alpha or luminance or an external video track";
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

#define SetInputMode(TEX, SMPL, MODE) \
                                      \
 texture TEX;                         \
                                      \
 sampler SMPL = sampler_state         \
 {                                    \
   Texture   = <TEX>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SetTargetMode(TGT, SMP, MODE) \
                                      \
 texture TGT : RenderColorTarget;     \
                                      \
 sampler SMP = sampler_state          \
 {                                    \
   Texture   = <TGT>;                 \
   AddressU  = MODE;                  \
   AddressV  = MODE;                  \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_Input, Mirror);
SetInputMode (Mask, s_Mask, Mirror);

SetTargetMode (FixInp, s0, Mirror);
SetTargetMode (FixMsk, affector, Mirror);

SetTargetMode (MaskPass, masktex, Mirror);

SetTargetMode (Pass1, s1, Mirror);
SetTargetMode (Pass2, s2, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float blurry
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 0.0;

bool big
<
   string Description = "x10";
> = false;

int alpha
<
   string Description = "Mask Type";
   string Group = "Mask";
   string Enum = "None,Source_Alpha,Source_Luma,Mask_Alpha,Mask_Luma";
> = 0;

int SetTechnique
<
   string Description = "Blur Mask";
   string Enum = "No,Yes";
   string Group = "Mask";
> = 0;

float adjust
<
   string Description = "Brightness";
   string Group = "Mask";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float contrast
<
   string Description = "Contrast";
   string Group = "Mask";
   float MinVal = 0.0;
   float MaxVal = 10.0;
> = 0.0;

float thresh
<
   string Description = "Threshold";
   string Group = "Mask";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

bool invert
<
   string Description = "Invert";
   string Group = "Mask";
> = false;

bool show
<
   string Description = "Show";
   string Group = "Mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 circle(float angle)
{
   return float2 (cos (angle), sin (angle)) / 2.333;
}

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float2 coord;
   float2 halfpix = pixelSize / 2.0;
   float2 radius = halfpix * discRadius;
   float2 sample = run * 0.1745;                      // 10 degrees expressed in radians

   float4 cOut = tex2D (tSource, texCoord + halfpix);
   float4 orig = tex2D (tSource, texCoord);

   for (int tap = 0; tap < 12; tap++) {
      coord = texCoord + (radius * circle (sample));
      cOut += tex2D (tSource, coord);
      sample += 0.5236;                               // 30 degrees expressed in radians
   }

   cOut /= 13.0;

   return cOut;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the input and mask timelines to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_Input, uv); }
float4 ps_initMsk (float2 uv : TEXCOORD2) : COLOR { return tex2D (s_Mask, uv); }

float4 Masking (float2 Tex : TEXCOORD3) : COLOR
{
   float4 orig = tex2D (s0, Tex);
   float4 aff  = tex2D (affector, Tex);

   float themask = (alpha == 0) ? 0.0
                 : (alpha == 1) ? orig.a
                 : (alpha == 2) ? dot (orig.rgb, float3 (0.33, 0.34, 0.33))
                 : (alpha == 3) ? aff.a
                                : dot (aff.rgb, float3 (0.33, 0.34, 0.33));
   themask += adjust;
   themask *= 1.0 + contrast;

   if (themask < thresh) themask = 0.0;

   if (invert) themask = 1.0 - themask;

   return themask.xxxx;
}

float4 PSMask (float2 Tex : TEXCOORD3) : COLOR
{  
   float blur = (big) ? blurry * 10.0 : blurry;

   float2 pixsize = float2 (1.0 / _OutputWidth, 1.0 / _OutputHeight);
   float2 halfpix = pixsize / 2.0;

   return GrowablePoissonDisc13FilterRGBA (masktex, Tex + halfpix, pixsize, blur, 0);
}

float4 PSMain (float2 Tex : TEXCOORD3, uniform int test) : COLOR
{  
   float blur = (big) ? blurry * 10.0 : blurry;

   float2 pixsize = float2 (1.0 / _OutputWidth, 1.0 / _OutputHeight);
   float2 halfpix = pixsize / 2.0;

   return (test == 1) ? GrowablePoissonDisc13FilterRGBA (s1, Tex + halfpix, pixsize, blur, 1)
        : (test == 2) ? GrowablePoissonDisc13FilterRGBA (s2, Tex + halfpix, pixsize, blur, 2)
                      : GrowablePoissonDisc13FilterRGBA (s0, Tex + halfpix, pixsize, blur, 0);
}

float4 Combine (float2 uv : TEXCOORD1, float2 Tex : TEXCOORD3) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   float blur = blurry;

   float2 pixsize = float2 (1.0 / _OutputWidth, 1.0 / _OutputHeight);
   float2 halfpix = pixsize / 2.0;

   float4 orig = tex2D (s0, Tex + halfpix);
   float4 masked, color, cout;

   if (blurry > 0.0) {
      color = tex2D (s1, Tex + halfpix);
      masked = tex2D (masktex, Tex + halfpix);
      cout = lerp (color, orig, saturate (masked. a));
   }
   else {
      cout = orig;
      masked = tex2D (masktex, Tex + pixsize);
   }

   if (show) return masked;

   return cout;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique No
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pma < string Script = "RenderColorTarget0 = FixMsk;"; > ExecuteShader (ps_initMsk)

   pass PassMask < string Script = "RenderColorTarget0 = MaskPass;"; > ExecuteShader (Masking)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 0)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 1)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 2)

   pass Last ExecuteShader (Combine)
}

technique Yes
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pma < string Script = "RenderColorTarget0 = FixMsk;"; > ExecuteShader (ps_initMsk)

   pass PassMask < string Script = "RenderColorTarget0 = MaskPass;"; > ExecuteShader (Masking)

   pass MBlur1 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteShader (PSMask)
   pass MBlur2 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 1)
   pass MBlur3 < string Script = "RenderColorTarget0 = MaskPass;"; > ExecuteParam (PSMain, 2)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 0)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 1)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 2)

   pass Last ExecuteShader (Combine)
}

