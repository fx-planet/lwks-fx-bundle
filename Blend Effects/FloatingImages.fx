// @Maintainer jwrl
// @Released 2021-08-11
// @Author jwrl
// @Created 2021-08-11
// @see https://www.lwks.com/media/kunena/attachments/6375/FloatImages_640.png

/**
 "Floating images" generates up to four floating images from a single foreground
 image.  The foreground may have an alpha channel, a bad alpha channel or no alpha
 channel at all, the effect will still work.  The position, size and density of the
 floating images are fully adjustable.

 Unlike the earlier version, the size adjustment now follows a square law.  Range
 settings are from zero to the square root of ten (a little over three) but the scale
 facor is actually from zero to ten.  This has been done to make size adjustment more
 readily controllable.

 As part of the resolution independence support, it's also now possible to optionally
 crop the foreground to the boundaries of the background.  This is the default setting.

 NOTE:  A version of this effect was previously released in which the overlay positions
 didn't necessarily track.  This was a deliberate choice at the time - during testing
 of that version with differing image sizes and resolutions the overlayed images jumped
 as they were played across cuts.  That problem has now been identified and corrected.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FloatingImages.fx
//
// Version history:
//
// Rewrite 2021-08-11 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Floating images";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Generates up to four overlayed images from a foreground graphic";
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

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Source
<
   string Group = "Disconnect title and image key inputs";
   string Description = "Source selection";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image,Extracted foreground";
> = 1;

float A_Opac
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float A_Zoom
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float A_Xc
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float A_Yc
<
   string Group = "Overlay 1 (always enabled)";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool B_On
<
   string Group = "Overlay 2";
   string Description = "Enabled";
> = false;

float B_Opac
<
   string Group = "Overlay 2";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float B_Zoom
<
   string Group = "Overlay 2";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float B_Xc
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float B_Yc
<
   string Group = "Overlay 2";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool C_On
<
   string Group = "Overlay 3";
   string Description = "Enabled";
> = false;

float C_Opac
<
   string Group = "Overlay 3";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float C_Zoom
<
   string Group = "Overlay 3";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float C_Xc
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float C_Yc
<
   string Group = "Overlay 3";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool D_On
<
   string Group = "Overlay 4";
   string Description = "Enabled";
> = false;

float D_Opac
<
   string Group = "Overlay 4";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float D_Zoom
<
   string Group = "Overlay 4";
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 3.16227766;
> = 1.0;

float D_Xc
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float D_Yc
<
   string Group = "Overlay 4";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

bool CropToBgd
<
   string Description = "Crop to background";
> = true;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return GetPixel (s_RawBg, uv); }

float4 ps_initFg (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_RawFg, uv1);

   if (Fgd.a == 0.0) return EMPTY;

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      float4 Bgd = GetPixel (s_Background, uv3);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd, Bgnd = GetPixel (s_Background, uv3);

   float2 xy;

   if (D_On) {
      xy = ((uv3 - float2 (D_Xc, 1.0 - D_Yc)) / (D_Zoom *  D_Zoom)) + 0.5.xx;
      Fgnd = GetPixel (s_Foreground, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * D_Opac);
   }

   if (C_On) {
      xy = ((uv3 - float2 (C_Xc, 1.0 - C_Yc)) / (C_Zoom *  C_Zoom)) + 0.5.xx;
      Fgnd = GetPixel (s_Foreground, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * C_Opac);
   }

   if (B_On) {
      xy = ((uv3 - float2 (B_Xc, 1.0 - B_Yc)) / (B_Zoom *  B_Zoom)) + 0.5.xx;
      Fgnd = GetPixel (s_Foreground, xy);
      Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * B_Opac);
   }

   xy = ((uv3 - float2 (A_Xc, 1.0 - A_Yc)) / (A_Zoom *  A_Zoom)) + 0.5.xx;
   Fgnd = GetPixel (s_Foreground, xy);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * A_Opac);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FloatingImages
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 ExecuteShader (ps_main)
}

