// @Maintainer jwrl
// @Released 2021-09-01
// @Author jwrl
// @Created 2021-09-01
// @see https://www.lwks.com/media/kunena/attachments/6375/DropShadowPlus_640.png

/**
 "Drop shadow plus blend" is a complex drop shadow and border generator.  It provides drop
 shadow blur softness control, and independent colour settings for border and shadow.  Two
 border generation modes and optional border anti-aliassing are also provided.  The border
 centering, width and height can also be independently adjusted.

 The effect can also output the foreground, border and drop shadow alone, along with the
 appropriate alpha channel.  When doing so any background input to the effect will not be
 displayed.

 The blend mode of the drop shadow and/or border and/or foreground can also be adjusted.
 This section of the effect attempts to match as closely as possible Photoshop's blends.
 Because that is built around an entirely different colour model and I have no definite
 knowledge of the algorithms used, absolute accuracy isn't claimed or guaranteed.

 As part of the resolution independence support, it's also now possible to optionally
 crop the foreground to the boundaries of the background.  This is the default setting.
 When using alpha export mode this setting is ignored, as are the blend modes.

 NOTE:  Because of the extreme complexity of this effect it will be slow to compile on
 some systems.  Regardless of that, it will preview as efficiently as other blend effects.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DropShadowBlend.fx
//
// Version history:
//
// Rewrite 2021-09-01 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Drop shadow plus blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Drop shadow and border generator for text graphics with blend modes";
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

#define GetAlpha(SHADER,XY) (Overflow(XY) ? 0.0 : tex2D(SHADER, XY).a)

#define SHADOW         0
#define BORDER_SHADOW  1
#define FGD_BDR_SHADOW 2
#define FGD_SHADOW     3
#define FGD_BORDER     4
#define FOREGROUND     5
#define BORDER         6

#define F_SCALE        2
#define B_SCALE        10
#define S_SCALE        1.75
#define OFFS_SCALE     0.04

#define LUMA_RED       0.299
#define LUMA_GREEN     0.587
#define LUMA_BLUE      0.114

float _OutputAspectRatio;
float _OutputWidth  = 1.0;

float _OutputPixelWidth  = 1.0;
float _OutputPixelHeight = 1.0;

float _sin_0 [] = { 0.0, 0.2588, 0.5, 0.7071, 0.866, 0.9659, 1.0 };
float _cos_0 [] = { 1.0, 0.9659, 0.866, 0.7071, 0.5, 0.2588, 0.0 };

float _sin_1 [] = { 0.1305, 0.3827, 0.6088, 0.7934, 0.9239, 0.9914 };
float _cos_1 [] = { 0.9914, 0.9239, 0.7934, 0.6088, 0.3827, 0.1305 };

float _pascal [] = { 0.00000006, 0.00000143, 0.00001645, 0.00012064, 0.00063336,
                     0.00253344, 0.00802255, 0.02062941, 0.04383749, 0.07793331,
                     0.11689997, 0.14878178, 0.16118026 };

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (RawFg, s_Foreground);
DefineTarget (RawBg, s_Background);

DefineTarget (RawBdr, s_RawBorder);
DefineTarget (Alias, s_Alias);
DefineTarget (Border, s_Border);

DefineTarget (Feather, s_Feather);
DefineTarget (Shadow, s_Shadow);
DefineTarget (Comp, s_Composite);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.00;

float F_amount
<
   string Description = "Foreground";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int B_edge
<
   string Group = "Border";
   string Description = "Border mode";
   string Enum = "Fully sampled,Full no anti-alias,Square edged,Square no anti-alias";
> = 0;

bool B_lock
<
   string Group = "Border";
   string Description = "Lock height to width";
> = true;

float B_amount
<
   string Group = "Border";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.00;

float B_width
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float B_height
<
   string Group = "Border";
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float B_centre_X
<
   string Group = "Border";
   string Description = "Border centre";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = 0.45;
   float MaxVal = 0.55;
> = 0.5;

float B_centre_Y
<
   string Group = "Border";
   string Description = "Border centre";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = 0.45;
   float MaxVal = 0.55;
> = 0.5;

float4 B_colour
<
   string Group = "Border";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.4784, 0.3961, 1.0, 1.0 };

float S_amount
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float S_feather
<
   string Group = "Shadow";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.3333;

float S_offset_X
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.20;

float S_offset_Y
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.20;

float4 S_colour
<
   string Group = "Shadow";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, -1.0 };

int blendMode
<
   string Group = "Border and shadow modes";
   string Description = "Blend coverage";
   string Enum = "Drop shadow only,Border and shadow,Foreground/border/shadow,Shadow and foreground,Border and foreground,Foreground only,Border only";
> = 0;

int SetTechnique
<
   string Group = "Border and shadow modes";
   string Description = "Blend mode";
   string Enum = "Normal,Darken,Multiply,Colour burn,Linear burn,Darker colour,Lighten,Screen,Add,Colour dodge,Linear dodge,Lighter colour,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Hard mix,Difference,Exclusion,Subtract,Divide,Hue,Saturation,Colour,Luminosity,Negate";
> = 0;

int AlphaMode
<
   string Description = "Output mode";
   string Enum = "Normal (no alpha),Foreground with alpha";
> = 0;

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
// Functions
//-----------------------------------------------------------------------------------------//

float4 rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float2 (0.0, Cmax).xxyx;

   if (Cmax != 0.0) {
      hsv.y = 1.0 - (Cmin / Cmax);

      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
   }

   return hsv;
}

float4 hsv2rgb (float4 hsv)
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

float4 ps_border_A (float2 uv : TEXCOORD3) : COLOR
{
   if (B_amount == 0.0) return GetPixel (s_Foreground, uv);

   float edgeX, edgeY;

   if (B_edge < 2) {
      edgeX = B_SCALE / _OutputWidth;
      edgeY = edgeX * _OutputAspectRatio;
   }
   else {
      edgeX = B_SCALE * S_SCALE / _OutputWidth;
      edgeY = 0.0;
   }

   float2 offset;
   float2 xy = uv + float2 (edgeX * (0.5 - B_centre_X), edgeY * (B_centre_Y - 0.5)) * 2.0;

   float4 retval = GetPixel (s_Foreground, xy);

   edgeX *= B_width;
   edgeY *= B_lock ? B_width : B_height;

   for (int i = 0; i < 7; i++) {
      offset.x = edgeX * _sin_0 [i];
      offset.y = edgeY * _cos_0 [i];

      retval += GetPixel (s_Foreground, xy + offset);
      retval += GetPixel (s_Foreground, xy - offset);

      offset.y = -offset.y;

      retval += GetPixel (s_Foreground, xy + offset);
      retval += GetPixel (s_Foreground, xy - offset);
   }

   return saturate (retval);
}

float4 ps_border_B (float2 uv : TEXCOORD3) : COLOR
{
   if (B_amount == 0.0) return GetPixel (s_Foreground, uv);

   float edgeX, edgeY;

   if (B_edge < 2) {
      edgeX = B_SCALE / _OutputWidth;
      edgeY = edgeX * _OutputAspectRatio;
   }
   else {
      edgeX = 0.0;
      edgeY = B_SCALE * S_SCALE * _OutputAspectRatio / _OutputWidth;
   }

   float2 offset;
   float2 xy = uv + float2 (edgeX * (0.5 - B_centre_X), edgeY * (B_centre_Y - 0.5)) * 2.0;

   float4 retval = GetPixel (s_RawBorder, xy);

   edgeX *= B_width;
   edgeY *= B_lock ? B_width : B_height;

   for (int i = 0; i < 6; i++) {
      offset.x = edgeX * _sin_1 [i];
      offset.y = edgeY * _cos_1 [i];

      retval += GetPixel (s_RawBorder, xy + offset);
      retval += GetPixel (s_RawBorder, xy - offset);

      offset.y = -offset.y;

      retval += GetPixel (s_RawBorder, xy + offset);
      retval += GetPixel (s_RawBorder, xy - offset);
   }

   return saturate (retval);
}

float4 ps_border_C (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Alias, uv);
   float4 Fgnd = GetPixel (s_Foreground, uv);

   if (B_amount > 0.0) {

      if ((B_edge == 0) || (B_edge == 2)) {
         float2 offset = max (_OutputPixelHeight * _OutputAspectRatio, _OutputPixelWidth).xx / (_OutputWidth * 2.0);

         retval += GetPixel (s_Alias, uv + offset);
         retval += GetPixel (s_Alias, uv - offset);

         offset.x = -offset.x;

         retval += GetPixel (s_Alias, uv + offset);
         retval += GetPixel (s_Alias, uv - offset);
         retval /= 5.0;
      }

      float alpha = max (Fgnd.a, retval.a * B_amount);

      retval = lerp (B_colour, Fgnd, Fgnd.a);
      retval.a = alpha;
   }

   retval.a = saturate (retval.a - (Fgnd.a * (1.0 - F_amount)));

   return retval;
}

float4 ps_shadow (float2 uv : TEXCOORD3) : COLOR
{
   float2 xy = uv - float2 (S_offset_X / _OutputAspectRatio, -S_offset_Y) * OFFS_SCALE;

   float4 retval = GetPixel (s_Border, xy);

   if ((S_amount != 0.0) && (S_feather != 0.0)) {
      float2 offset = float2 (S_feather * F_SCALE / _OutputWidth, 0.0);
      float2 xy1 = xy + offset;

      retval *= _pascal [12];
      retval += GetPixel (s_Border, xy1) * _pascal [11]; xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [10]; xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [9];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [8];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [7];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [6];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [5];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [4];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [3];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [2];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [1];  xy1 += offset;
      retval += GetPixel (s_Border, xy1) * _pascal [0];
      xy1 = xy - offset;
      retval += GetPixel (s_Border, xy1) * _pascal [11]; xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [10]; xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [9];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [8];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [7];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [6];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [5];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [4];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [3];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [2];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [1];  xy1 -= offset;
      retval += GetPixel (s_Border, xy1) * _pascal [0];
   }

   return retval;
}

float4 ps_feather (float2 uv : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Shadow, uv);

   if ((S_amount != 0.0) && (S_feather != 0.0)) {
      float2 offset = float2 (0.0, S_feather * F_SCALE * _OutputAspectRatio / _OutputWidth);
      float2 xy1 = uv + offset;

      retval *= _pascal [12];
      retval += GetPixel (s_Shadow, xy1) * _pascal [11]; xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [10]; xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [9];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [8];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [7];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [6];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [5];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [4];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [3];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [2];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [1];  xy1 += offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [0];
      xy1 = uv - offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [11]; xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [10]; xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [9];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [8];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [7];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [6];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [5];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [4];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [3];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [2];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [1];  xy1 -= offset;
      retval += GetPixel (s_Shadow, xy1) * _pascal [0];
   }

   float alpha = retval.a * S_amount;

   retval = GetPixel (s_Border, uv);
   alpha  = max (alpha, retval.a);
   retval = lerp (S_colour, retval, retval.a);
   retval.a = alpha;

   return retval;
}

//----------------------- From here on are the various blend modes ------------------------//

float4 ps_normal (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv3);

   if (AlphaMode) return Fgd;

   float4 Bgd = GetPixel (s_Background, uv3);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   return CropToBgd && Overflow (uv2) ? EMPTY : float4 (retval.rgb, Bgd.a);
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = lerp (Bgd, min (Fgd, Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_multiply (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = lerp (Bgd, Bgd * Fgd, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_colourBurn (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Fgd == 0.0) ? 0.0 : 1.0 - ((1.0 - Bgd) / Fgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_linearBurn (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;

   retval = (retval == 0.0) ? 0.0 : 1.0 - ((1.0 - Bgd) / retval);
   retval = lerp (Bgd, (Bgd * retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_darkerColour (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Bgd == 1.0) ? 1.0 : Fgd * Fgd / (1.0 - Bgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = lerp (Bgd, max (Fgd, Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_screen (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = max (min ((Bgd * (1.0 - Fgd) + Fgd), 1.0), 0.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_add (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = min ((Fgd + Bgd), 1.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_colourDodge (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Fgd == 1.0) ? 1.0 : min ((Bgd / (1.0 - Fgd)), 1.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_linearDodge (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;

   retval = (retval == 1.0) ? 1.0 : Bgd / (1.0 - retval);
   retval = (Fgd == 1.0) ? 1.0 : retval / (1.0 - Fgd);
   retval = lerp (Bgd, min (max (retval, 0.0), 1.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_lighterColour (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;
   float4 Bgdcol = float2 ((LUMA_RED * Bgd.r) + (LUMA_GREEN * Bgd.g) + (LUMA_BLUE * Bgd.b), 0.0).xxxy;

   retval = (retval > Bgdcol) ? Fgd : Bgd;

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Bgd < 0.5) ? 2.0 * Bgd * Fgd : 2.0 * Bgd * (Fgd - 1.0) - Fgd;

   retval = lerp (Bgd, min (retval, 1.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_softLight (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = Fgd - 0.5;

   retval = (Fgd < 0.5) ? Bgd * (Fgd - Bgd * retval) : sqrt (Bgd) * retval - Bgd * (Fgd - 1.0);
   retval = lerp (Bgd, max (min ((2.0 * retval), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_hardLight (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Fgd < 0.5) ? 2.0 * Bgd * Fgd : 2.0 * ((Bgd * Fgd) - Fgd) - Bgd;

   retval = lerp (Bgd, max (min ((2.0 * retval), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_vividLight (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Fgd < 0.5) ? ((Fgd == 0.0) ? Fgd : max ((1.0 - ((1.0 - Bgd) / (2.0 * Fgd))), 0.0))
                               : ((Fgd == 1.0) ? Fgd : min (Bgd / (2.0 * (1.0 - Fgd)), 1.0));

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_linearLight (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = max (min ((2.0 * Fgd) + Bgd - 1.0, 1.0), 0.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_pinLight (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Fgd < 0.5) ? min (Bgd, (2.0 * Fgd)) : max (Bgd, ((2.0 * Fgd) - 1.0));

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_hardMix (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Bgd > 0.5) ? 2.0 * Bgd * (Fgd - 1.0) - Fgd : 2.0 * Fgd * Bgd;

   retval = (retval > 0.5) ? (2.0 * retval * (Bgd - 1.0)) - Bgd + 2.0 : 2.0 * retval * Bgd;
   retval = lerp (Bgd, max (min ((2.0 * retval), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = lerp (Bgd, abs (Fgd - Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_exclude (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = Fgd + Bgd - (2.0 * Fgd * Bgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_subtract (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = lerp (Bgd, max ((Bgd - Fgd), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_divide (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = (Fgd == 0.0) ? Bgd : min ((Bgd / Fgd), 1.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = rgb2hsv (Bgd);

   retval.x = (rgb2hsv (Fgd)).x;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

float4 ps_saturation (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = rgb2hsv (Bgd);

   retval.y = retval.y + (rgb2hsv (Fgd)).y;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

float4 ps_colour (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = rgb2hsv (Bgd);

   retval.xy = retval.xy + (rgb2hsv (Fgd)).xy;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

float4 ps_luminance (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = rgb2hsv (Bgd);

   retval.z = (rgb2hsv (Fgd)).z;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

//------------------------------------- NON_PHOTOSHOP -------------------------------------//

float4 ps_negate (float2 uv : TEXCOORD3) : COLOR
{
   float4 Fgd = GetPixel (s_Shadow, uv);
   float4 Bgd = GetPixel (s_Background, uv);
   float4 retval = 1.0 - abs (1.0 - Fgd - Bgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? GetPixel (s_Foreground, uv) : GetPixel (s_Border, uv);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//---------------------------------- End of blend modes -----------------------------------//

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 shadow = GetPixel (s_Shadow, uv3);

   if (AlphaMode) return shadow;

   float4 Fgd = GetPixel (s_Foreground, uv3);
   float4 Bgd = GetPixel (s_Background, uv3);
   float4 border = GetPixel (s_Border, uv3);
   float4 composite = GetPixel (s_Composite, uv3);
   float4 retval;

   if (blendMode <= FGD_BDR_SHADOW) { retval = composite; }
   else if (blendMode == FGD_SHADOW) {
      retval = lerp (composite, Bgd, border.a);
      retval = lerp (retval, border, border.a * Amount);
      retval = lerp (retval, composite, Fgd.a);
   }
   else {
      retval = lerp (Bgd, shadow, shadow.a * Amount);

      if (blendMode == FOREGROUND) {
         retval = lerp (retval, composite, Fgd.a);
      }
      else {
         retval = lerp (retval, composite, border.a);

         if (blendMode == BORDER) retval = lerp (retval, Fgd, Fgd.a * Amount);
      }
   }

   return CropToBgd && Overflow (uv2) ? EMPTY : float4 (retval.rgb, Bgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique normal
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 ExecuteShader (ps_normal)
}

technique darken
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_darken)
   pass P_7 ExecuteShader (ps_main)
}

technique multiply
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_multiply)
   pass P_7 ExecuteShader (ps_main)
}

technique colourBurn
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_colourBurn)
   pass P_7 ExecuteShader (ps_main)
}

technique linearBurn
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_linearBurn)
   pass P_7 ExecuteShader (ps_main)
}

technique darkerColour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_darkerColour)
   pass P_7 ExecuteShader (ps_main)
}

technique lighten
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_lighten)
   pass P_7 ExecuteShader (ps_main)
}

technique screen
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_screen)
   pass P_7 ExecuteShader (ps_main)
}

technique add
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_add)
   pass P_7 ExecuteShader (ps_main)
}

technique colourDodge
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_colourDodge)
   pass P_7 ExecuteShader (ps_main)
}

technique linearDodge
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_linearDodge)
   pass P_7 ExecuteShader (ps_main)
}

technique lighterColour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_lighterColour)
   pass P_7 ExecuteShader (ps_main)
}

technique overlay
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_overlay)
   pass P_7 ExecuteShader (ps_main)
}

technique softLight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_softLight)
   pass P_7 ExecuteShader (ps_main)
}

technique hardlight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_hardLight)
   pass P_7 ExecuteShader (ps_main)
}

technique vividLight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_vividLight)
   pass P_7 ExecuteShader (ps_main)
}

technique linearLight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_linearLight)
   pass P_7 ExecuteShader (ps_main)
}

technique pinLight
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_pinLight)
   pass P_7 ExecuteShader (ps_main)
}

technique hardMix
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_hardMix)
   pass P_7 ExecuteShader (ps_main)
}

technique difference
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_difference)
   pass P_7 ExecuteShader (ps_main)
}

technique exclude
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_exclude)
   pass P_7 ExecuteShader (ps_main)
}

technique subtract
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_subtract)
   pass P_7 ExecuteShader (ps_main)
}

technique divide
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_divide)
   pass P_7 ExecuteShader (ps_main)
}

technique hue
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_hue)
   pass P_7 ExecuteShader (ps_main)
}

technique saturation
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_saturation)
   pass P_7 ExecuteShader (ps_main)
}

technique colour
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_colour)
   pass P_7 ExecuteShader (ps_main)
}

technique luminance
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_luminance)
   pass P_7 ExecuteShader (ps_main)
}

technique negate
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Feather;"; > ExecuteShader (ps_shadow)
   pass P_5 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_feather)
   pass P_6 < string Script = "RenderColorTarget0 = Comp;"; > ExecuteShader (ps_negate)
   pass P_7 ExecuteShader (ps_main)
}

