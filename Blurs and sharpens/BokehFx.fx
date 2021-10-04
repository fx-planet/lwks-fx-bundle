// @Maintainer jwrl
// @Released 2021-08-31
// @Author khaver
// @Created 2011-08-30
// @see https://www.lwks.com/media/kunena/attachments/6375/Bokeh_640.png

/**
 Blur with adjustable bokeh.  Uses 6 GPU passes for blur and 8 passes for bokeh creation.
 Khaver warns that it may not be playable in real time on slower systems, although in my
 testing I've never found that to be a problem - jwrl.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bokeh.fx
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
   string Description = "Bokeh";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "Blur with adjustable bokeh";
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
#define MaskPixel(SHADER,XY,MASK) (Overflow (MASK) ? EMPTY : tex2D (SHADER, XY))

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (Input, s_Input, Mirror);
SetInputMode (Mask, s_Mask, Mirror);

SetTargetMode (FixInp, s0, Mirror);
SetTargetMode (FixMsk, m0, Mirror);

SetTargetMode (Pass1, s1, Mirror);
SetTargetMode (Pass2, s2, Mirror);

SetTargetMode (Bokeh1, b1, Mirror);
SetTargetMode (Bokeh2, b2, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float size
<
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 50.0;
> = 3.0;

float thresh
<
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float strength
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.8;

float gamma
<
   string Description = "Gamma";
   float MinVal = 0.0;
   float MaxVal = 3.0;
> = 0.75;

float focus
<
   string Description = "Focus";
   string Group = "Image";
   float MinVal = 0.0;
   float MaxVal = 100.0;
> = 10.0;

float igamma
<
   string Description = "Gamma";
   string Group = "Image";
   float MinVal = 0.0;
   float MaxVal = 3.0;
> = 0.75;

float bmix
<
   string Description = "Mix";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool smask
<
   string Description = "Show Bokeh Mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 BlurDisc13FilterRGBA (sampler tSource, float2 texCoord, float2 halfPix, float discRadius, int run)
{
   float2 coord, circle, Tex = texCoord + halfPix;
   float2 radius = halfPix * discRadius;

   float angle = run * 5.0;

   float4 cOut = MaskPixel (tSource, Tex + halfPix, Tex);
   float4 orig = tex2D (tSource, Tex);

   for (int tap = 0; tap < 12; tap++) {
      sincos (radians (angle), circle.y, circle.x);
      coord = Tex + (circle * radius);
      cOut += tex2D (tSource, coord);
      angle += 30.0;
   }

   cOut /= 13.0;

   return cOut;
}

float4 BokehFilterRGBA (sampler tSource, float2 texCoord, float2 pixelSize, float discRadius, int run)
{
   float4 color;

   float2 coord, circle;
   float2 halfpix = pixelSize / 2.0;
   float2 radius = pixelSize * discRadius;

   float angle = run * 3.75;

   float4 cOut = tex2D (tSource, texCoord + halfpix);

   for (int tap = 0; tap < 17; tap++) {               // Shouldn't this be 16?
      sincos (radians (angle), circle.y, circle.x);
      coord = texCoord + (circle * radius);
      color = tex2D (tSource, coord);
      cOut = max (color, cOut);
      angle += 22.5;
   }

   cOut.a = 1.0;

   return cOut;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the input and mask clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_Input, uv); }
float4 ps_initMsk (float2 uv : TEXCOORD2) : COLOR { return tex2D (s_Mask, uv); }

float4 FindBokeh (float2 Tex : TEXCOORD3) : COLOR
{
   float4 orig = tex2D (s0, Tex);
   float4 color = EMPTY;

   if (any (orig.rgb > thresh)) color = pow (orig, 1.0 / gamma);

   return color * strength;
}

float4 PSMain (float2 Tex : TEXCOORD3, uniform int test) : COLOR
{  
   float2 halfpix = float2 (0.5 / _OutputWidth, 0.5 / _OutputHeight);

   if (test == 0) return BlurDisc13FilterRGBA (s0, Tex, halfpix, focus, test);
   if (test == 1) return BlurDisc13FilterRGBA (s1, Tex, halfpix, focus, test);
   if (test == 2) return BlurDisc13FilterRGBA (s2, Tex, halfpix, focus, test);
   if (test == 3) return BlurDisc13FilterRGBA (s1, Tex, halfpix, focus, test);
   if (test == 4) return BlurDisc13FilterRGBA (s2, Tex, halfpix, focus, test);
   if (test == 5) return BlurDisc13FilterRGBA (s1, Tex, halfpix, focus, test);

   return (test == 6) ? BlurDisc13FilterRGBA (b2, Tex, halfpix, size / 4.0, 0)
                      : BlurDisc13FilterRGBA (b1, Tex, halfpix, size / 4.0, 1);
}

float4 PSBokeh (float2 Tex : TEXCOORD3, uniform int test) : COLOR
{  
   float2 pixsize = float2 (1.0 / _OutputWidth, 1.0 / _OutputHeight);
   float2 halfpix = pixsize / 2.0;

   if (test == 0) return BokehFilterRGBA (m0, Tex + halfpix, pixsize, size, test);
   if (test == 1) return BokehFilterRGBA (b1, Tex + halfpix, pixsize, size, test);
   if (test == 2) return BokehFilterRGBA (b2, Tex + halfpix, pixsize, size, test);
   if (test == 3) return BokehFilterRGBA (b1, Tex + halfpix, pixsize, size, test);
   if (test == 4) return BokehFilterRGBA (b2, Tex + halfpix, pixsize, size, test);

   return BokehFilterRGBA (b1, Tex + halfpix, pixsize, size, test);
}

float4 Combine (float2 uv : TEXCOORD1, float2 Tex : TEXCOORD3) : COLOR
{
   float2 halfpix = float2 (0.5 / _OutputWidth, 0.5 / _OutputHeight);

   float4 orig = MaskPixel (s0, Tex + halfpix, uv);

   if (smask) return MaskPixel (m0, Tex, uv);

   if ((focus > 0.0) || (size > 0.0)) {
      float4 blurred = pow (MaskPixel (s2, Tex + halfpix, uv), 1.0 / igamma);
      float4 bokeh = MaskPixel (b2, Tex + halfpix, uv);

      if (size == 0.0) bokeh = blurred;

      blurred *= bmix;
      orig = 1.0.xxxx - ((1.0.xxxx - bokeh) * (1.0.xxxx - blurred));
   }

  return orig;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Bokeh
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass Pma < string Script = "RenderColorTarget0 = FixMsk;"; > ExecuteShader (ps_initMsk)

   pass BokehPass  < string Script = "RenderColorTarget0 = Mask;"; > ExecuteShader (FindBokeh)
   pass BokehPass0 < string Script = "RenderColorTarget0 = Bokeh1;"; > ExecuteParam (PSBokeh, 0)
   pass BokehPass1 < string Script = "RenderColorTarget0 = Bokeh2;"; > ExecuteParam (PSBokeh, 1)
   pass BokehPass2 < string Script = "RenderColorTarget0 = Bokeh1;"; > ExecuteParam (PSBokeh, 2)
   pass BokehPass3 < string Script = "RenderColorTarget0 = Bokeh2;"; > ExecuteParam (PSBokeh, 3)
   pass BokehPass4 < string Script = "RenderColorTarget0 = Bokeh1;"; > ExecuteParam (PSBokeh, 4)
   pass BokehLast  < string Script = "RenderColorTarget0 = Bokeh2;"; > ExecuteParam (PSBokeh, 5)

   pass BokehBlur1 < string Script = "RenderColorTarget0 = Bokeh1;"; > ExecuteParam (PSMain, 6)
   pass BokehBlur2 < string Script = "RenderColorTarget0 = Bokeh2;"; > ExecuteParam (PSMain, 7)

   pass BlurPass0 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 0)
   pass BlurPass1 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 1)
   pass BlurPass2 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 2)
   pass BlurPass3 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 3)
   pass BlurPass4 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 4)
   pass BlurPass5 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 5)

   pass Last ExecuteShader (Combine)
}

