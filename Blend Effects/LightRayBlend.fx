// @Maintainer jwrl
// @Released 2021-08-11
// @Author jwrl
// @Created 2021-08-11
// @see https://www.lwks.com/media/kunena/attachments/6375/LightRayKeys_640.png

/**
 This effect adds directional blurs to a key or any image with an alpha channel.  The
 default is to apply a radial blur away from the effect centre.  That centre can be put
 up to one frame height and/or frame width outside the frame.  Optionally it can  also
 produce a blur that points to the centre, or a linear directional blur.

 The angle of the linear (directional) blur is set by dragging the effect centre away
 from the frame centre.  The angle of displacement is all that's used in this mode, and
 the amount of that displacement is ignored.  It can help in setting up, because moving
 the effect centre further away from the frame centre in linear mode will enhance the
 angular precision.

 If there is no alpha channel available this can be used to apply an overall blur to
 an image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LightRayBlend.fx
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
   string Description = "Light ray blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Adds directional blurs to a key or any image with an alpha channel";
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

#define R_VAL    0.2989
#define G_VAL    0.5866
#define B_VAL    0.1145

#define SAMPLE   80

#define SAMPLES  81.0

#define B_SCALE  0.0075

#define L_SCALE  0.00375
#define LIN_OFFS 1.001
#define LUMAOFFS 0.015
#define L_SAMPLE 20.0

#define ADD      0
#define SCREEN   1
#define DARKEN   2
#define SUBTRACT 3
#define SOLID    4

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);
DefineTarget (blurProc, s_Processed);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Blur type";
   string Enum = "Radial from centre,Radial to centre,Linear directional";
> = 0;

int recoverFg
<
   string Description = "Foreground blend";
   string Enum = "Add,Screen,Darken,Subtract,Solid,None";
> = 4;

int rayType
<
   string Description = "Rays";
   string Enum = "Add,Screen,Darken,Subtract";
> = 0;

float zoomAmount
<
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Opacity
<
   string Description = "Master opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Fgd_amt
<
   string Group = "Opacity";
   string Description = "Foreground";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Group = "Opacity";
   string Description = "Rays";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

int Source
<
   string Group = "Disconnect title and image key inputs";
   string Description = "Source selection";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image,Extracted foreground";
> = 1;

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

float4 ps_out (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = GetPixel (s_Foreground, uv); }
   else {
      float z_Amount = zoomAmount / 2;

      float2 zoomCentre = float2 ((Xcentre * 3) - 1.0, 2.0 - (Ycentre * 3));
      float2 xy = uv - zoomCentre;

      retval = EMPTY;

      for (int i = SAMPLE; i >= 0; i--) {
         scale = 1.0 - z_Amount * ((float)i / SAMPLE);

         retval += GetPixel (s_Foreground, (xy * scale) + zoomCentre);
      }

      retval /= SAMPLES;
   }

   return retval;
}

float4 ps_in (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval;

   float scale;

   if (zoomAmount == 0.0) { retval = GetPixel (s_Foreground, uv); }
   else {
      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy = uv - zoomCentre;

      retval = EMPTY;

      for (int i = 0; i <= SAMPLE; i++) {
         scale = 1.0 + zoomAmount * ((float)i / SAMPLE);

         retval += GetPixel (s_Foreground, (xy * scale) + zoomCentre);
      }

      retval /= SAMPLES;
   }

   return retval;
}

float4 ps_linear (float2 uv : TEXCOORD3) : COLOR
{
   float2 offset;
   float4 retval;

   offset.x = 0.5 - saturate (Xcentre * LIN_OFFS);
   offset.y = saturate (Ycentre * LIN_OFFS) - 0.5;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) {
      retval = GetPixel (s_Foreground, uv);
   }
   else {
      offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
      offset *= zoomAmount * L_SCALE;
      retval  = 0.0.xxxx;

      float2 xy = uv;

      float luminosity = 1.0;

      for (int i = 0; i < SAMPLES; i++) {
         retval += GetPixel (s_Foreground, xy) * luminosity;
         xy += offset;
         luminosity -= LUMAOFFS;
         }

      retval /= ((1.5 - zoomAmount) * L_SAMPLE);
   }

   return retval;
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 fgImage = GetPixel (s_Foreground, uv3);
   float4 bgImage = GetPixel (s_Background, uv3);
   float4 blurred = GetPixel (s_Processed, uv3);

   float inv_luma = 1.0 - dot (blurred.rgb, float3 (R_VAL, G_VAL, B_VAL));

   float4 retval = (rayType == ADD)    ? saturate (bgImage + blurred)
                 : (rayType == SCREEN) ? 1.0 - ((1.0 - blurred) * (1.0 - bgImage))
                 : (rayType == DARKEN) ? bgImage * inv_luma
                                       : saturate (bgImage - blurred);  // Fall through to SUBTRACT

   inv_luma = 1.0 - dot (fgImage.rgb, float3 (R_VAL, G_VAL, B_VAL));

   float4 FxImage = (recoverFg == ADD)      ? saturate (fgImage + bgImage)
                  : (recoverFg == SCREEN)   ? 1.0 - ((1.0 - fgImage) * (1.0 - bgImage))
                  : (recoverFg == DARKEN)   ? bgImage * inv_luma
                  : (recoverFg == SUBTRACT) ? saturate (bgImage - fgImage)
                  : (recoverFg == SOLID)    ? fgImage
                                            : bgImage;                  // Fall through to none

   FxImage = lerp (retval, FxImage, Fgd_amt);
   retval  = lerp (bgImage, retval, Amount * blurred.a);
   retval  = lerp (retval, FxImage, fgImage.a);
   retval  = lerp (bgImage, retval, Opacity);

   return CropToBgd && Overflow (uv2) ? EMPTY : float4 (retval.rgb, bgImage.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FromCentre
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteShader (ps_out)
   pass P_2 ExecuteShader (ps_main)
}

technique ToCentre
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteShader (ps_in)
   pass P_2 ExecuteShader (ps_main)
}

technique Linear
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteShader (ps_linear)
   pass P_2 ExecuteShader (ps_main)
}

