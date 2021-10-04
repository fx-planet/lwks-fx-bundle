// @Maintainer jwrl
// @Released 2021-08-31
// @Author khaver
// @Released 2015-12-08
// @see https://www.lwks.com/media/kunena/attachments/6375/FocalBlur_640.png

/**
 This effect is a 3 pass 13 tap circular kernel blur.  The blur can be varied using the
 alpha channel or luma value of the source video or another video track.  It uses a depth
 map for the blur mask for faux depth of field, and is refocusable.

 NOTE: As with Lightworks' standard blur effects, this effect produces the blur at the
 sequence resolution.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Focal_blur.fx
//
// Version history:
//
// Updated 2021-08-31 jwrl:
// Update of the original effect to support LW 2021 resolution independence.
// Release date does not reflect upload date because of forum upload problems.
//
// Prior to 2020-11-09:
// Various updates mainly to improve cross-platform performance.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Focal blur";
   string Category    = "Stylize";
   string SubCategory = "Blurs and Sharpens";
   string Notes       = "This effect uses a depth map to create a faux depth of field";
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
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define LUMA float3(0.3, 0.59, 0.11)

float _OutputWidth;
float _OutputHeight;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

SetInputMode (V1, s_In_1, Mirror);
SetInputMode (V2, s_In_2, Mirror);

SetTargetMode (In_1, v1, Mirror);
SetTargetMode (In_2, v2, Mirror);

SetTargetMode (MaskPass, masktex, Mirror);

SetTargetMode (Pass1, s1, Mirror);
SetTargetMode (Pass2, s2, Mirror);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool swap
<
   string Description = "Swap Inputs";
> = false;

float blurry
<
   string Description = "De-Focus";
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

int focust
<
  string Description = "Focus Type";
  string Group = "Focus";
  string Enum = "None,Linear,Point";
> = 0;

float linfocus
<
   string Description = "Distance";
   string Group = "Focus";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float DoF
<
   string Description = "DoF";
   string Group = "Focus";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float FocusX
<
   string Description = "Point";
   string Flags = "SpecifiesPointX";
   string Group = "Focus";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float FocusY
<
   string Description = "Point";
   string Flags = "SpecifiesPointY";
   string Group = "Focus";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool show
<
   string Description = "Show";
   string Group = "Mask Adjustment";
> = false;

bool invert
<
   string Description = "Invert";
   string Group = "Mask Adjustment";
> = false;

int SetTechnique
<
   string Description = "Blur";
   string Enum = "No,Yes";
   string Group = "Mask Adjustment";
> = 0;

float mblur
<
   string Description = "Blur Strength";
   float MinVal = 0.0;
   float MaxVal = 100.0;
   string Group = "Mask Adjustment";
> = 0.0;

float adjust
<
   string Description = "Brightness";
   string Group = "Mask Adjustment";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float contrast
<
   string Description = "Contrast";
   string Group = "Mask Adjustment";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float thresh
<
   string Description = "Threshold";
   string Group = "Mask Adjustment";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 GrowablePoissonDisc13FilterRGBA (sampler tSource, float2 texCoord, float discRadius, int run)
{
   float angle = run * 0.1745329252;      // This was 10 degrees which was then converted to radians.  This is identical

   float2 radius = discRadius / (float2 (_OutputWidth, _OutputHeight) * 4.667);
   float2 circle, coord;

   float4 cOut = tex2D (tSource, texCoord);

   for (int tap = 0; tap < 12; tap++) {
      sincos (angle, circle.y, circle.x);
      coord  = saturate (texCoord + (circle * radius));
      cOut  += tex2D (tSource, coord);
      angle += 0.5235987756;              // Originally 30 degrees - see above comment
   }

   cOut /= 13.0;

   return cOut;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// These two passes map the video #1 and video #2 clips to TEXCOORD3, so that
// variations in clip geometry and rotation are handled without too much effort.

float4 ps_initV1 (float2 uv : TEXCOORD1) : COLOR { return tex2D (s_In_1, uv); }
float4 ps_initV2 (float2 uv : TEXCOORD2) : COLOR { return tex2D (s_In_2, uv); }

float4 Masking (float2 Tex : TEXCOORD3) : COLOR
{
   float DOF = (1.0 - DoF) * 2.0;
   float focusl = 1.0 - linfocus;
   float cont = (contrast + 1.0);

   if (cont > 1.0) cont = pow (cont,5.0);

   float4 orig, aff, opoint, mpoint;

   if (swap) {
      orig = tex2D (v2, Tex);
      aff = tex2D (v1, Tex);
      opoint = tex2D (v2, float2 (FocusX, 1.0 - FocusY));
      mpoint = tex2D (v1, float2 (FocusX, 1.0 - FocusY));
   }
   else {
      orig = tex2D (v1, Tex);
      aff = tex2D (v2, Tex);
      opoint = tex2D (v1, float2 (FocusX, 1.0 - FocusY));
      mpoint = tex2D (v2, float2 (FocusX, 1.0 - FocusY));
   }

   float themask;

   if (alpha == 0) themask = 0.0;
   else if (alpha == 1) {
      if (focust == 0) themask - orig.a;
      else if (focust == 1) themask = 1.0 - abs (orig.a - focusl);
      else themask = 1.0 - abs (orig.a - opoint.a);
   }
   else if (alpha == 2) {
      if (focust == 0) themask = (orig.r + orig.g + orig.b) / 3.0;
      else if (focust == 1) themask = 1.0 - abs (dot (orig.rgb, LUMA) - focusl);
      else themask = 1.0 - abs (dot (orig.rgb, LUMA) - dot (opoint.rgb, LUMA));
   }
   else if (alpha == 3) {
      if (focust == 0) themask = aff.a;
      else if (focust == 1) themask = 1.0 - abs (aff.a - focusl);
      else themask = 1.0 - abs (aff.a - mpoint.a);
   }
   else {
      if (focust == 0) themask = (aff.r + aff.g + aff.b) / 3.0;
      else if (focust == 1) themask = 1.0 - abs (((aff.r + aff.g + aff.b) / 3.0) - focusl);
      else themask = 1.0 - abs ((aff.r - mpoint.r + aff.g - mpoint.g + aff.b - mpoint.b) / 3.0);
   }

   themask = pow (themask, DOF);
   themask = saturate (((themask - 0.5) * max (cont, 0.0)) + adjust + 0.5);

   if ((thresh > 0.0) && (themask < thresh)) themask = 0.0;

   if ((thresh < 0.0) && (themask > 1.0 + thresh)) themask = 1.0;

   if (invert) themask = 1.0 - themask;

   return themask.xxxx;
}

float4 PSMask (float2 Tex : TEXCOORD3, uniform int test) : COLOR
{  
   if (test == 0) return GrowablePoissonDisc13FilterRGBA (masktex, Tex, mblur, test);

   if (test == 1) return GrowablePoissonDisc13FilterRGBA (s1, Tex, mblur, test);

   return GrowablePoissonDisc13FilterRGBA (s2, Tex, mblur, test);
}

float4 PSMain (float2 Tex : TEXCOORD3, uniform int test) : COLOR
{  
   float blur = big ? blurry * 10.0 : blurry;

   blur *= 1.0 - tex2D (masktex, Tex).a;

   if (test == 0) {
      if (!swap) return GrowablePoissonDisc13FilterRGBA (v1, Tex, blur, test);

      return GrowablePoissonDisc13FilterRGBA (v2, Tex, blur, test);
   }

   if (test == 1) return GrowablePoissonDisc13FilterRGBA (s1, Tex, blur, test);

   return GrowablePoissonDisc13FilterRGBA (s2, Tex, blur, test);
}

float4 Combine (float2 uv : TEXCOORD1, float2 Tex : TEXCOORD3) : COLOR
{
   if (Overflow (uv)) return EMPTY;

   if (show) return GetPixel (masktex, Tex);

   if (blurry > 0.0) return GetPixel (s1, Tex);

   return swap ? GetPixel (v2, Tex) : GetPixel (v1, Tex);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique No
{
   pass Pv1 < string Script = "RenderColorTarget0 = In_1;"; > ExecuteShader (ps_initV1)
   pass Pv2 < string Script = "RenderColorTarget0 = In_2;"; > ExecuteShader (ps_initV2)

   pass PassMask < string Script = "RenderColorTarget0 = MaskPass;"; > ExecuteShader (Masking)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 0)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 1)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 2)

   pass Last ExecuteShader (Combine)
}

technique Yes
{
   pass Pv1 < string Script = "RenderColorTarget0 = In_1;"; > ExecuteShader (ps_initV1)
   pass Pv2 < string Script = "RenderColorTarget0 = In_2;"; > ExecuteShader (ps_initV2)

   pass PassMask < string Script = "RenderColorTarget0 = MaskPass;"; > ExecuteShader (Masking)

   pass MBlur1 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMask, 0)
   pass MBlur2 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMask, 1)
   pass MBlur3 < string Script = "RenderColorTarget0 = MaskPass;"; > ExecuteParam (PSMask, 2)

   pass Pass1 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 0)
   pass Pass2 < string Script = "RenderColorTarget0 = Pass2;"; > ExecuteParam (PSMain, 1)
   pass Pass3 < string Script = "RenderColorTarget0 = Pass1;"; > ExecuteParam (PSMain, 2)

   pass Last ExecuteShader (Combine)
}

