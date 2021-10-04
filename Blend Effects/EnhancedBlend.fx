// @Maintainer jwrl
// @Released 2021-08-11
// @Author jwrl
// @Created 2021-08-11
// @see https://www.lwks.com/media/kunena/attachments/6375/EnhancedBlend_640.png

/**
 "Enhanced blend" is a variant of the Lightworks blend effect with the option to boost the
 alpha channel (transparency) to match the blending used by title effects.  It can help
 when using titles with their inputs disconnected and used with other effects such as DVEs.
 It also closely emulates most of the Photoshop blend modes.

 As part of the resolution independence support, it's also now possible to optionally
 crop the foreground to the boundaries of the background.  This is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// User effect EnhancedBlend.fx
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
   string Description = "Enhanced blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "This is a customised blend for use in conjunction with other effects.";
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

#define CrR    0.439
#define CrG    0.368
#define CrB    0.071

#define CbR    0.148
#define CbG    0.291
#define CbB    0.439

#define Rr_R   1.596
#define Rg_R   0.813
#define Rg_B   0.391
#define Rb_B   2.018

#define WHITE  1.0.xxxx

#define LUMA    float4(0.2989, 0.5866, 0.1145, 0.0)

#define TITLE_FX  0
#define DELTA_KEY 2

//-----------------------------------------------------------------------------------------//
// Inputs and samplers
//-----------------------------------------------------------------------------------------//

DefineInput (fg, s_RawFg);
DefineInput (bg, s_RawBg);

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
> = TITLE_FX;

float Amount
<
   string Description = "Fg Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Description = "Blend mode";
   string Enum = "Normal,Export fg with alpha,____________________,Darken,Multiply,Colour Burn,Linear Burn,Darker Colour,____________________,Lighten,Screen,Colour Dodge,Linear Dodge (Add),Lighter Colour,____________________,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Hard Mix,____________________,Difference,Exclusion,Subtract,Divide,____________________,Hue,Saturation,Colour,Luminosity";
> = 0;

bool CropToBgd
<
   string Description = "Crop to background";
> = true;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

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

//-------------------------------------- ^^ INIT ^^ ---------------------------------------//

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_multiply (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb *= Bgnd.rgb;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourBurn (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   if (Fgnd.r > 0.0) Fgnd.r = 1.0 - ((1.0 - Bgnd.r) / Fgnd.r);
   if (Fgnd.g > 0.0) Fgnd.g = 1.0 - ((1.0 - Bgnd.g) / Fgnd.g);
   if (Fgnd.b > 0.0) Fgnd.b = 1.0 - ((1.0 - Bgnd.b) / Fgnd.b);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearBurn (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = max (Fgnd.rgb + Bgnd.rgb - 1.0.xxx, 0.0.xxx);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_darkerColour (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) > luma) Fgnd.rgb = Bgnd.rgb;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_screen (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_colourDodge (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (1.0 - Fgnd.r);
   Fgnd.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (1.0 - Fgnd.g);
   Fgnd.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (1.0 - Fgnd.b);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, min (Fgnd, WHITE), Fgnd.a * Amount);
}

float4 ps_linearDodge (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_lighterColour (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float  luma = dot (Bgnd, LUMA);

   if (dot (Fgnd, LUMA) < luma) Fgnd.rgb = Bgnd.rgb;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMin = 2.0 * Bgnd.rgb * Fgnd.rgb;
   float3 retMax = 1.0.xxx - 2.0 * (1.0.xxx - Fgnd.rgb) * (1.0.xxx - Bgnd.rgb);

   Fgnd.r = (Bgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Bgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Bgnd.b <= 0.5) ? retMin.b : retMax.b;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_softLight (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMax = (2.0 * Fgnd.rgb) - 1.0.xxx;
   float3 retMin = Bgnd.rgb * (retMax * (1.0.xxx - Bgnd.rgb) + 1.0.xxx);

   retMax *= sqrt (Bgnd.rgb) - Bgnd.rgb;
   retMax += Bgnd.rgb;

   Fgnd.r = (Fgnd.r <= 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g <= 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b <= 0.5) ? retMin.b : retMax.b;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardLight (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMin = saturate (2.0 * Bgnd.rgb * Fgnd.rgb);
   float3 retMax = saturate (1.0.xxx - 2.0 * (1.0.xxx - Bgnd.rgb) * (1.0.xxx - Fgnd.rgb));

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_vividLight (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMax, retMin;

   retMin.r = (Fgnd.r == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.r) / (2.0 * Fgnd.r)), 0.0);
   retMin.g = (Fgnd.g == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.g) / (2.0 * Fgnd.g)), 0.0);
   retMin.b = (Fgnd.b == 0.0) ? 0.0 : max (1.0 - ((1.0 - Bgnd.b) / (2.0 * Fgnd.b)), 0.0);

   retMax.r = (Fgnd.r == 1.0) ? 1.0 : Bgnd.r / (2.0 * (1.0 - Fgnd.r));
   retMax.g = (Fgnd.g == 1.0) ? 1.0 : Bgnd.g / (2.0 * (1.0 - Fgnd.g));
   retMax.b = (Fgnd.b == 1.0) ? 1.0 : Bgnd.b / (2.0 * (1.0 - Fgnd.b));

   retMin = min (retMin, (1.0).xxx);
   retMax = min (retMax, (1.0).xxx);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_linearLight (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 retMin = max ((2.0 * Fgnd) + Bgnd - WHITE, EMPTY);
   float4 retMax = min ((2.0 * Fgnd) + Bgnd - WHITE, WHITE);

   Fgnd.r = (Fgnd.r < 0.5) ? retMin.r : retMax.r;
   Fgnd.g = (Fgnd.g < 0.5) ? retMin.g : retMax.g;
   Fgnd.b = (Fgnd.b < 0.5) ? retMin.b : retMax.b;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_pinLight (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 retMax = 2.0 * Fgnd.rgb;
   float3 retMin = retMax - 1.0.xxx;

   Fgnd.r = (Bgnd.r > retMax.r) ? retMax.r : (Bgnd.r < retMin.r) ? retMin.r : Bgnd.r;
   Fgnd.g = (Bgnd.g > retMax.g) ? retMax.g : (Bgnd.g < retMin.g) ? retMin.g : Bgnd.g;
   Fgnd.b = (Bgnd.b > retMax.b) ? retMax.b : (Bgnd.b < retMin.b) ? retMin.b : Bgnd.b;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, saturate (Fgnd), Fgnd.a * Amount);
}

float4 ps_hardMix (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   float3 ref = 1.0.xxx - Bgnd.rgb;

   Fgnd.r = (Fgnd.r < ref.r) ? 0.0 : 1.0;
   Fgnd.g = (Fgnd.g < ref.g) ? 0.0 : 1.0;
   Fgnd.b = (Fgnd.b < ref.b) ? 0.0 : 1.0;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_exclusion (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (1.0.xxx - (2.0 * Fgnd.rgb)));

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_subtract (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, 0.0.xxx);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

float4 ps_divide (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);

   Fgnd.r = (Fgnd.r == 0.0) ? 1.0 : min (Bgnd.r / Fgnd.r, 1.0);
   Fgnd.g = (Fgnd.g == 0.0) ? 1.0 : min (Bgnd.g / Fgnd.g, 1.0);
   Fgnd.b = (Fgnd.b == 0.0) ? 1.0 : min (Bgnd.b / Fgnd.b, 1.0);

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, Fgnd, Fgnd.a * Amount);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.xw = (fn_rgb2hsv (Fgnd)).xw;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_saturation (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.yw = fn_rgb2hsv (Fgnd).yw;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_colour (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Fgnd);

   blnd.x = (fn_rgb2hsv (Bgnd)).x;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

float4 ps_luminosity (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv3);
   float4 Bgnd = GetPixel (s_Background, uv3);
   float4 blnd = fn_rgb2hsv (Bgnd);

   blnd.zw = (fn_rgb2hsv (Fgnd)).zw;

   return CropToBgd && Overflow (uv2) ? EMPTY : lerp (Bgnd, fn_hsv2rgb (blnd), Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//;
// Techniques;
//-----------------------------------------------------------------------------------------//;

technique Normal
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_01 ExecuteShader (ps_main)
}

technique Export
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass P_02 ExecuteShader (ps_initFg)
}

//--------------------------------------- GROUP 1 -----------------------------------------//

technique Group_1 { pass P_10 ExecuteShader (ps_initBg) }

technique Darken
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_11 ExecuteShader (ps_darken)
}

technique Multiply
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_12 ExecuteShader (ps_multiply)
}

technique ColourBurn
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_13 ExecuteShader (ps_colourBurn)
}

technique LinearBurn
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_14 ExecuteShader (ps_linearBurn)
}

technique DarkerColour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_15 ExecuteShader (ps_darkerColour)
}

//--------------------------------------- GROUP 2 -----------------------------------------//

technique Group_2 { pass P_20 ExecuteShader (ps_initBg) }

technique Lighten
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_21 ExecuteShader (ps_lighten)
}

technique Screen
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_22 ExecuteShader (ps_screen)
}

technique ColourDodge
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_23 ExecuteShader (ps_colourDodge)
}

technique LinearDodge
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_24 ExecuteShader (ps_linearDodge)
}

technique LighterColour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_25 ExecuteShader (ps_lighterColour)
}

//--------------------------------------- GROUP 3 -----------------------------------------//

technique Group_3 { pass P_30 ExecuteShader (ps_initBg) }

technique Overlay
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_31 ExecuteShader (ps_overlay)
}

technique SoftLight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_32 ExecuteShader (ps_softLight)
}

technique Hardlight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_33 ExecuteShader (ps_hardLight)
}

technique Vividlight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_34 ExecuteShader (ps_vividLight)
}

technique Linearlight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_35 ExecuteShader (ps_linearLight)
}

technique Pinlight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_36 ExecuteShader (ps_pinLight)
}

technique HardMix
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_37 ExecuteShader (ps_hardMix)
}

//--------------------------------------- GROUP 4 -----------------------------------------//

technique Group_4 { pass P_40 ExecuteShader (ps_initBg) }

technique Difference
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_41 ExecuteShader (ps_difference)
}

technique Exclusion
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_42 ExecuteShader (ps_exclusion)
}

technique Subtract
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_43 ExecuteShader (ps_subtract)
}

technique Divide
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_44 ExecuteShader (ps_divide)
}

//--------------------------------------- GROUP 5 -----------------------------------------//

technique Group_5 { pass P_50 ExecuteShader (ps_initBg) }

technique Hue
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_51 ExecuteShader (ps_hue)
}

technique Saturation
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_52 ExecuteShader (ps_saturation)
}

technique Colour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_53 ExecuteShader (ps_colour)
}

technique Luminosity
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_54 ExecuteShader (ps_luminosity)
}

