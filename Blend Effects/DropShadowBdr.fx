// @Maintainer jwrl
// @Released 2021-08-11
// @Author jwrl
// @Created 2021-08-11
// @see https://www.lwks.com/media/kunena/attachments/6375/DropShadowAndBorder_640.png

/**
 "Drop shadow and border" is a drop shadow and border generator.  It provides drop shadow
 softness and independent colour settings for border and shadow.  Two border generation
 modes and full border anti-aliassing are provided.  The border centering can be offset
 to make the border assymetrical (thanks Igor for the suggestion).  In previous builds of
 this effect the range of centering adjustment was absurd.  In this version it has been
 considerably reduced.

 The effect can also output the foreground, border and/or drop shadow alone, with the
 appropriate alpha channel.  When doing so any background input to the effect will not
 be displayed.  This allows it to be used with downstream alpha handling effects.

 As part of the resolution independence support, it's also now possible to optionally
 crop the foreground to the boundaries of the background.  This is the default setting.
 When using alpha export mode this setting is ignored.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect DropShadowBdr.fx
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
   string Description = "Drop shadow and border";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Drop shadow and border generator for text graphics";
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

#define F_SCALE    2
#define B_SCALE    10
#define S_SCALE    1.75
#define OFFS_SCALE 0.04

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
DefineTarget (Border, s_Border);
DefineTarget (Alias, s_Alias);
DefineTarget (Shadow, s_Shadow);

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
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float B_centre_Y
<
   string Group = "Border";
   string Description = "Border centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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
> = { 0.0, 0.0, 0.0, 1.0 };

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

float4 ps_main (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float4 retval = GetPixel (s_Shadow, uv3);

   if ((S_amount != 0.0) && (S_feather != 0.0)) {
      float2 offset = float2 (0.0, S_feather * F_SCALE * _OutputAspectRatio / _OutputWidth);
      float2 xy1 = uv3 + offset;

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
      xy1 = uv3 - offset;
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

   retval = GetPixel (s_Border, uv3);
   alpha  = max (alpha, retval.a);
   retval = lerp (S_colour, retval, retval.a);
   retval.a = alpha * Amount;

   if (AlphaMode) return retval;

   if (CropToBgd && Overflow (uv2)) retval = EMPTY;

   return float4 (lerp (GetPixel (s_Background, uv3), retval, retval.a).rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DropShadowBdr
{
   pass Pbg < string Script = "RenderColorTarget0 = RawBg;"; > ExecuteShader (ps_initBg)
   pass Pfg < string Script = "RenderColorTarget0 = RawFg;"; > ExecuteShader (ps_initFg)
   pass P_1 < string Script = "RenderColorTarget0 = RawBdr;"; > ExecuteShader (ps_border_A)
   pass P_2 < string Script = "RenderColorTarget0 = Alias;"; > ExecuteShader (ps_border_B)
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > ExecuteShader (ps_border_C)
   pass P_4 < string Script = "RenderColorTarget0 = Shadow;"; > ExecuteShader (ps_shadow)
   pass P_5 ExecuteShader (ps_main)
}

