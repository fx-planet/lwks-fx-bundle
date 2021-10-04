// @Maintainer jwrl
// @Released 2021-08-11
// @Author jwrl
// @Created 2021-08-11
// @see https://www.lwks.com/media/kunena/attachments/6375/ExtrusionMatte_640.png

/**
 "Extrusion blend", as the name suggests, extrudes a foreground image either linearly or
 radially towards a centre point.  The extruded section can be shaded by the foreground
 image, colour shaded, or flat colour filled.  The edge shading can be inverted if desired.
 It is also possible to export the alpha channel for use in downstream effects.

 As part of the resolution independence support, it's also now possible to optionally
 crop the foreground to the boundaries of the background.  This is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExtrusionBlend.fx
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
   string Description = "Extrusion blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Extrudes a foreground image either linearly or radially towards a centre point";
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

#define ExecuteParam(SHD,PRM) { PixelShader = compile PROFILE SHD (PRM); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define SAMPLE   80
#define HALFWAY  40
#define SAMPLES  81

#define DELTANG  25
#define ALIASFIX 50
#define ANGLE    0.125664

#define B_SCALE  0.0075
#define L_SCALE  0.05
#define R_SCALE  0.00125

#define DEFAULT  0
#define COLOUR   1
#define MONO     2

#define LIN_OFFS 0.667333

float _OutputAspectRatio;
float _OutputWidth;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (fg, s_RawFg);
DefineInput (bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (blurPre, s_Blur);
DefineTarget (colorPre, s_Colour);
DefineTarget (blurProc, s_Processed);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Edge type";
   string Enum = "Radial,Radial shaded,Radial coloured,Linear,Linear shaded,Linear coloured";
> = 0;

float Opacity
<
   string Description = "Master opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amount
<
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float zoomAmount
<
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

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

float4 colour
<
   string Group = "Colour setup";
   string Description = "Edge colour";
   bool SupportsAlpha = true;
> = { 1.0, 0.3804, 1.0, -1.0 };

bool invShade
<
   string Description = "Invert shading";
> = false;

bool expAlpha
<
   string Description = "Export alpha channel";
> = false;

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

float4 ps_radial (float2 uv : TEXCOORD3, uniform int mode) : COLOR
{
   float4 retval = GetPixel (s_Foreground, uv);

   if (zoomAmount == 0.0) return retval;

   float scale, depth = zoomAmount * R_SCALE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = uv;
   float2 xy2 = depth * (uv - zoomCentre);

   retval.rgb = 1.0.xxx - retval.rgb;

   for (int i = 0; i <= SAMPLE; i++) {
      xy1 = uv + (xy2 * i);
      retval += GetPixel (s_Foreground, xy1);
   }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 ps_linear (float2 uv : TEXCOORD3, uniform int mode) : COLOR
{
   float4 retval = GetPixel (s_Foreground, uv);

   float2 offset, xy = uv;

   offset.x = (0.498 - Xcentre) * LIN_OFFS;
   offset.y = (Ycentre - 0.505) * LIN_OFFS;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (zoomAmount == 0.0)) return retval;

   float depth = zoomAmount * L_SCALE;

   retval.rgb = 1.0.xxx - retval.rgb;
   offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
   offset *= depth * B_SCALE;

   for (int i = 0; i < SAMPLES; i++) {
      retval += GetPixel (s_Foreground, xy);
      xy += offset;
      }

   retval.a = saturate (retval.a);

   if (mode == COLOUR) return float4 (colour.rgb, retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (((mode == DEFAULT) && !invShade) || ((mode != DEFAULT) && invShade))
      return retval;

   return float4 (1.0.xxx - retval.rgb, retval.a);
}

float4 ps_shaded (float2 uv : TEXCOORD3) : COLOR
{
   float4 blurImg = GetPixel (s_Blur, uv);
   float4 colrImg = GetPixel (s_Colour, uv);

   float alpha   = blurImg.a;
   float minColr = min (colrImg.r, min (colrImg.g, colrImg.b));
   float maxColr = max (colrImg.r, max (colrImg.g, colrImg.b));
   float delta   = maxColr - minColr;

   float3 hsv = 0.0.xxx;

   if (maxColr != 0.0) {
      hsv.y = 1.0 - (minColr / maxColr);
      hsv.x = (colrImg.r == maxColr) ? (colrImg.g - colrImg.b) / delta :
              (colrImg.g == maxColr) ? 2.0 + (colrImg.b - colrImg.r) / delta
                                     : 4.0 + (colrImg.r - colrImg.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   hsv.z = max (blurImg.r, max (blurImg.g, blurImg.b));

   if (hsv.y == 0.0) return float4 (hsv.zzz, alpha);

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float beta = hsv.x - (float) i;

   float4 retval = hsv.zzzz;

   retval.w *= (1.0 - hsv.y * (1.0 - beta));
   retval.y *= (1.0 - hsv.y);
   retval.z *= (1.0 - hsv.y * beta);

   if (i == 0) return float4 (retval.xwy, alpha);
   if (i == 1) return float4 (retval.zxy, alpha);
   if (i == 2) return float4 (retval.yxw, alpha);
   if (i == 3) return float4 (retval.yzx, alpha);
   if (i == 4) return float4 (retval.wyx, alpha);

   return float4 (retval.xyz, alpha);
}

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 fgImage = GetPixel (s_Foreground, uv3);
   float4 retval  = EMPTY;

   float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
   float2 offset, scale;

   float angle = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      retval += GetPixel (s_Processed, uv3 + offset);
      retval += GetPixel (s_Processed, uv3 - offset);
      angle += ANGLE;
   }

   retval  /= ALIASFIX;
   retval   = lerp (EMPTY, retval, retval.a);
   retval   = lerp (retval, fgImage, fgImage.a);
   retval.a = max (fgImage.a, retval.a * Amount);

   if (expAlpha) return retval;

   float4 bgImage = GetPixel (s_Background, uv3);

   retval = lerp (bgImage, retval, retval.a);

   return CropToBgd && Overflow (uv2) ? EMPTY
        : lerp (bgImage, float4 (retval.rgb, bgImage.a), Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Radial
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteParam (ps_radial, DEFAULT)
   pass P_2 ExecuteShader (ps_main)
}

technique RadialShaded
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurPre;"; > ExecuteParam (ps_radial, MONO)
   pass P_2 < string Script = "RenderColorTarget0 = colorPre;"; > ExecuteParam (ps_radial, COLOUR)
   pass P_3 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteShader (ps_shaded)
   pass P_4 ExecuteShader (ps_main)
}

technique RadialColour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteParam (ps_radial, COLOUR)
   pass P_2 ExecuteShader (ps_main)
}

technique Linear
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteParam (ps_linear, DEFAULT)
   pass P_2 ExecuteShader (ps_main)
}

technique LinearShaded
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurPre;"; > ExecuteParam (ps_linear, MONO)
   pass P_2 < string Script = "RenderColorTarget0 = colorPre;"; > ExecuteParam (ps_linear, COLOUR)
   pass P_3 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteShader (ps_shaded)
   pass P_4 ExecuteShader (ps_main)
}

technique LinearColour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = blurProc;"; > ExecuteParam (ps_linear, COLOUR)
   pass P_2 ExecuteShader (ps_main)
}

