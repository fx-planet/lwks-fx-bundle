//--------------------------------------------------------------//
// Lightworks user effect DropShadowPlus.fx
//
// Created by LW user jwrl 1 April 2016.
//
// Moved alpha export to its own independent setting
// Rewrote several blend modes
//
// 20 April 2015 : Fixed a minor bug in the overlay blend
// which would have biassed the colour towards red.
//
// This effect is a drop shadow and border generator.  It has
// drop shadow blur, and independent colour settings for border
// and shadow.  Two border generation modes and optional border
// anti-aliassing are also provided.  Additionally, the border
// centering, width and height can also be independently
// adjusted (thanks Igor).
//
// The effect can also output the foreground, border and drop
// shadow alone, with the appropriate alpha channel.  When doing
// so any background input to the effect will not be displayed.
//
// The blend mode of the drop shadow and/or border and/or
// foreground can also be adjusted.  This section of the effect
// attempts to match as closely as possible Photoshop's blends.
// Because that is built around an entirely different colour
// model and I have no definite knowledge of the algorithms used,
// absolute accuracy isn't claimed and can't be guaranteed.
//
// LW 14+ version by jwrl 11 January 2017.
// Category changed from "Keying" to "Key", subcategory "Edge
// Effects" added.
//
// Bug fix 26 February 2017 by jwrl:
// This addresses a bug with Lightworks' handling of interlaced
// media.  The height parameter in Lightworks returns half the
// true frame height but only when interlaced media is playing.
// That has been fixed in this code.
//
// Bug fix 21 July 2017 by jwrl:
// This addresses a cross platform issue which could cause the
// effect to not behave as expected on Linux and Mac systems.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Drop shadow plus";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

texture brdrInp : RenderColorTarget;
texture aliased : RenderColorTarget;
texture brdrOut : RenderColorTarget;
texture fthr_in : RenderColorTarget;
texture shadOut : RenderColorTarget;
texture compose : RenderColorTarget;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler b_inSampler = sampler_state {
   Texture = <brdrInp>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler hardSampler = sampler_state {
   Texture   = <aliased>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler fthrSampler = sampler_state {
   Texture = <fthr_in>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler borderSampler = sampler_state {
   Texture = <brdrOut>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler shadowSampler = sampler_state {
   Texture = <shadOut>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler compedSampler = sampler_state {
   Texture   = <compose>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.00;

int BorderEdge
<
   string Group = "Border";
   string Description = "Border mode";
   string Enum = "Fully sampled,Full no anti-alias,Square edged,Square no anti-alias";
> = 0;

bool BorderLocked
<
   string Group = "Border";
   string Description = "Lock height to width";
> = true;

float BorderOpacity
<
   string Group = "Border";
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.00;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float BorderHeight
<
   string Group = "Border";
   string Description = "Height";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float BorderCentreX
<
   string Group = "Border";
   string Description = "Border centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float BorderCentreY
<
   string Group = "Border";
   string Description = "Border centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float4 BorderColour
<
   string Group = "Border";
   string Description = "Colour";
> = { 0.4784, 0.3961, 1.0, 0.7 };

float ShadowOpacity
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.50;

float ShadowFeather
<
   string Group = "Shadow";
   string Description = "Feather";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.3333;

float ShadowOffsetX
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = 0.20;

float ShadowOffsetY
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.00;
   float MaxVal = 1.00;
> = -0.20;

float4 ShadowColour
<
   string Group = "Shadow";
   string Description = "Colour";
> = { 0.0, 0.0, 0.0, 0.0 };

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

bool alphaMode
<
   string Group = "Border and shadow modes";
   string Description = "Don't export background alpha";
> = false;

//--------------------------------------------------------------//
// Definitions and stuff
//--------------------------------------------------------------//

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

#define OutputHeight (_OutputWidth/_OutputAspectRatio)

float _OutputPixelWidth  = 1.0;
float _OutputPixelHeight = 1.0;

const float sin_0 [] = { 0.0, 0.2588, 0.5, 0.7071, 0.866, 0.9659, 1.0 };
const float cos_0 [] = { 1.0, 0.9659, 0.866, 0.7071, 0.5, 0.2588, 0.0 };

const float sin_1 [] = { 0.1305, 0.3827, 0.6088, 0.7934, 0.9239, 0.9914 };
const float cos_1 [] = { 0.9914, 0.9239, 0.7934, 0.6088, 0.3827, 0.1305 };

const float _pascal [] = { 0.00000006, 0.00000143, 0.00001645, 0.00012064, 0.00063336, 0.00253344, 0.00802255, 0.02062941, 0.04383749, 0.07793331, 0.11689997, 0.14878178, 0.16118026 };

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// HSV functions
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 border_A (float2 xy : TEXCOORD1) : COLOR
{
   if (BorderOpacity == 0.0) return tex2D (FgSampler, xy);

   float edgeX, edgeY;

   if (BorderEdge < 2) {
      edgeX = B_SCALE / _OutputWidth;
      edgeY = edgeX * _OutputAspectRatio;
   }
   else {
      edgeX = B_SCALE * S_SCALE / _OutputWidth;
      edgeY = 0.0;
   }

   float2 offset;
   float2 refXY = xy + float2 (edgeX * (0.5 - BorderCentreX), edgeY * (BorderCentreY - 0.5)) * 2.0;

   float4 retval = tex2D (FgSampler, refXY);

   edgeX *= BorderWidth;
   edgeY *= BorderLocked ? BorderWidth : BorderHeight;

   for (int i = 0; i < 7; i++) {
      offset.x = edgeX * sin_0 [i];
      offset.y = edgeY * cos_0 [i];

      retval += tex2D (FgSampler, refXY + offset);
      retval += tex2D (FgSampler, refXY - offset);

      offset.y = -offset.y;

      retval += tex2D (FgSampler, refXY + offset);
      retval += tex2D (FgSampler, refXY - offset);
   }

   return saturate (retval);
}

float4 border_B (float2 xy : TEXCOORD1) : COLOR
{
   if (BorderOpacity == 0.0) return tex2D (FgSampler, xy);

   float edgeX, edgeY;

   if (BorderEdge < 2) {
      edgeX = B_SCALE / _OutputWidth;
      edgeY = edgeX * _OutputAspectRatio;
   }
   else {
      edgeX = 0.0;
      edgeY = B_SCALE * S_SCALE * _OutputAspectRatio / _OutputWidth;
   }

   float2 offset;
   float2 refXY = xy + float2 (edgeX * (0.5 - BorderCentreX), edgeY * (BorderCentreY - 0.5)) * 2.0;

   float4 retval = tex2D (b_inSampler, refXY);

   edgeX *= BorderWidth;
   edgeY *= BorderLocked ? BorderWidth : BorderHeight;

   for (int i = 0; i < 6; i++) {
      offset.x = edgeX * sin_1 [i];
      offset.y = edgeY * cos_1 [i];

      retval += tex2D (b_inSampler, refXY + offset);
      retval += tex2D (b_inSampler, refXY - offset);

      offset.y = -offset.y;

      retval += tex2D (b_inSampler, refXY + offset);
      retval += tex2D (b_inSampler, refXY - offset);
   }

   return saturate (retval);
}

float4 border_C (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (hardSampler, xy);

   if (BorderOpacity == 0.0) return retval;

   if ((BorderEdge == 0) || (BorderEdge == 2)) {
      float2 offset = max (_OutputPixelHeight * _OutputAspectRatio, _OutputPixelWidth).xx / (_OutputWidth * 2.0);

      retval += tex2D (hardSampler, xy + offset);
      retval += tex2D (hardSampler, xy - offset);

      offset.x = -offset.x;

      retval += tex2D (hardSampler, xy + offset);
      retval += tex2D (hardSampler, xy - offset);
      retval /= 5.0;
   }

   float4 fgnd = tex2D (FgSampler, xy);

   retval.a   = max (fgnd.a, retval.a * BorderOpacity);
   retval.rgb = lerp (BorderColour.rgb, fgnd.rgb, fgnd.a);

   return retval;
}

float4 makeShadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy = uv - float2 (ShadowOffsetX / _OutputAspectRatio, -ShadowOffsetY) * OFFS_SCALE;

   float4 retval = tex2D (borderSampler, xy);

   if ((ShadowOpacity != 0.0) && (ShadowFeather != 0.0)) {
      float offset = (ShadowFeather * F_SCALE) / _OutputWidth;

      float pos_b = xy.x  + offset;
      float pos_a = pos_b + offset;
      float pos_9 = pos_a + offset;
      float pos_8 = pos_9 + offset;
      float pos_7 = pos_8 + offset;
      float pos_6 = pos_7 + offset;
      float pos_5 = pos_6 + offset;
      float pos_4 = pos_5 + offset;
      float pos_3 = pos_4 + offset;
      float pos_2 = pos_3 + offset;
      float pos_1 = pos_2 + offset;
      float pos_0 = pos_1 + offset;

      float neg_b = xy.x  - offset;
      float neg_a = neg_b - offset;
      float neg_9 = neg_a - offset;
      float neg_8 = neg_9 - offset;
      float neg_7 = neg_8 - offset;
      float neg_6 = neg_7 - offset;
      float neg_5 = neg_6 - offset;
      float neg_4 = neg_5 - offset;
      float neg_3 = neg_4 - offset;
      float neg_2 = neg_3 - offset;
      float neg_1 = neg_2 - offset;
      float neg_0 = neg_1 - offset;

      retval *= _pascal [12];

      retval += tex2D (borderSampler, float2 (pos_b, xy.y)) * _pascal [11];
      retval += tex2D (borderSampler, float2 (pos_a, xy.y)) * _pascal [10];
      retval += tex2D (borderSampler, float2 (pos_9, xy.y)) * _pascal [9];
      retval += tex2D (borderSampler, float2 (pos_8, xy.y)) * _pascal [8];
      retval += tex2D (borderSampler, float2 (pos_7, xy.y)) * _pascal [7];
      retval += tex2D (borderSampler, float2 (pos_6, xy.y)) * _pascal [6];
      retval += tex2D (borderSampler, float2 (pos_5, xy.y)) * _pascal [5];
      retval += tex2D (borderSampler, float2 (pos_4, xy.y)) * _pascal [4];
      retval += tex2D (borderSampler, float2 (pos_3, xy.y)) * _pascal [3];
      retval += tex2D (borderSampler, float2 (pos_2, xy.y)) * _pascal [2];
      retval += tex2D (borderSampler, float2 (pos_1, xy.y)) * _pascal [1];
      retval += tex2D (borderSampler, float2 (pos_0, xy.y)) * _pascal [0];
      retval += tex2D (borderSampler, float2 (neg_b, xy.y)) * _pascal [11];
      retval += tex2D (borderSampler, float2 (neg_a, xy.y)) * _pascal [10];
      retval += tex2D (borderSampler, float2 (neg_9, xy.y)) * _pascal [9];
      retval += tex2D (borderSampler, float2 (neg_8, xy.y)) * _pascal [8];
      retval += tex2D (borderSampler, float2 (neg_7, xy.y)) * _pascal [7];
      retval += tex2D (borderSampler, float2 (neg_6, xy.y)) * _pascal [6];
      retval += tex2D (borderSampler, float2 (neg_5, xy.y)) * _pascal [5];
      retval += tex2D (borderSampler, float2 (neg_4, xy.y)) * _pascal [4];
      retval += tex2D (borderSampler, float2 (neg_3, xy.y)) * _pascal [3];
      retval += tex2D (borderSampler, float2 (neg_2, xy.y)) * _pascal [2];
      retval += tex2D (borderSampler, float2 (neg_1, xy.y)) * _pascal [1];
      retval += tex2D (borderSampler, float2 (neg_0, xy.y)) * _pascal [0];
   }

   return retval;
}

float4 feather_it (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (fthrSampler, xy);

   if ((ShadowOpacity != 0.0) && (ShadowFeather != 0.0)) {
      float offset = (ShadowFeather * F_SCALE) / OutputHeight;

      float pos_b = xy.y  + offset;
      float pos_a = pos_b + offset;
      float pos_9 = pos_a + offset;
      float pos_8 = pos_9 + offset;
      float pos_7 = pos_8 + offset;
      float pos_6 = pos_7 + offset;
      float pos_5 = pos_6 + offset;
      float pos_4 = pos_5 + offset;
      float pos_3 = pos_4 + offset;
      float pos_2 = pos_3 + offset;
      float pos_1 = pos_2 + offset;
      float pos_0 = pos_1 + offset;

      float neg_b = xy.y  - offset;
      float neg_a = neg_b - offset;
      float neg_9 = neg_a - offset;
      float neg_8 = neg_9 - offset;
      float neg_7 = neg_8 - offset;
      float neg_6 = neg_7 - offset;
      float neg_5 = neg_6 - offset;
      float neg_4 = neg_5 - offset;
      float neg_3 = neg_4 - offset;
      float neg_2 = neg_3 - offset;
      float neg_1 = neg_2 - offset;
      float neg_0 = neg_1 - offset;

      retval *= _pascal [12];

      retval += tex2D (fthrSampler, float2 (xy.x, pos_b)) * _pascal [11];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_a)) * _pascal [10];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_9)) * _pascal [9];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_8)) * _pascal [8];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_7)) * _pascal [7];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_6)) * _pascal [6];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_5)) * _pascal [5];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_4)) * _pascal [4];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_3)) * _pascal [3];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_2)) * _pascal [2];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_1)) * _pascal [1];
      retval += tex2D (fthrSampler, float2 (xy.x, pos_0)) * _pascal [0];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_b)) * _pascal [11];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_a)) * _pascal [10];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_9)) * _pascal [9];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_8)) * _pascal [8];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_7)) * _pascal [7];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_6)) * _pascal [6];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_5)) * _pascal [5];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_4)) * _pascal [4];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_3)) * _pascal [3];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_2)) * _pascal [2];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_1)) * _pascal [1];
      retval += tex2D (fthrSampler, float2 (xy.x, neg_0)) * _pascal [0];
   }

   float alpha = retval.a * ShadowOpacity;

   retval = tex2D (borderSampler, xy);
   alpha  = max (alpha, retval.a);
   retval = lerp (ShadowColour, retval, retval.a);

   return float4 (retval.rgb, alpha);
}

//--------------------------------------------------------------//
// From here on are the various blend modes
//--------------------------------------------------------------//

float4 ps_normal (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);

   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------------------------------//

float4 ps_darken (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = lerp (Bgd, min (Fgd, Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_multiply (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = lerp (Bgd, Bgd * Fgd, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_colourBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Fgd == 0.0) ? 0.0 : 1.0 - ((1.0 - Bgd) / Fgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_linearBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;

   retval = (retval == 0.0) ? 0.0 : 1.0 - ((1.0 - Bgd) / retval);
   retval = lerp (Bgd, (Bgd * retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_darkerColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Bgd == 1.0) ? 1.0 : Fgd * Fgd / (1.0 - Bgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------------------------------//

float4 ps_lighten (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = lerp (Bgd, max (Fgd, Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_screen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = max (min ((Bgd * (1.0 - Fgd) + Fgd), 1.0), 0.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_add (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = min ((Fgd + Bgd), 1.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_colourDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Fgd == 1.0) ? 1.0 : min ((Bgd / (1.0 - Fgd)), 1.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_linearDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;

   retval = (retval == 1.0) ? 1.0 : Bgd / (1.0 - retval);
   retval = (Fgd == 1.0) ? 1.0 : retval / (1.0 - Fgd);
   retval = lerp (Bgd, min (max (retval, 0.0), 1.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_lighterColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;
   float4 Bgdcol = float2 ((LUMA_RED * Bgd.r) + (LUMA_GREEN * Bgd.g) + (LUMA_BLUE * Bgd.b), 0.0).xxxy;

   retval = (retval > Bgdcol) ? Fgd : Bgd;

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------------------------------//

float4 ps_overlay (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Bgd < 0.5) ? 2.0 * Bgd * Fgd : 2.0 * Bgd * (Fgd - 1.0) - Fgd;

   retval = lerp (Bgd, min (retval, 1.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_softLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = Fgd - 0.5;

   retval = (Fgd < 0.5) ? Bgd * (Fgd - Bgd * retval) : sqrt (Bgd) * retval - Bgd * (Fgd - 1.0);
   retval = lerp (Bgd, max (min ((2.0 * retval), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_hardLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Fgd < 0.5) ? 2.0 * Bgd * Fgd : 2.0 * ((Bgd * Fgd) - Fgd) - Bgd;

   retval = lerp (Bgd, max (min ((2.0 * retval), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_vividLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Fgd < 0.5) ? ((Fgd == 0.0) ? Fgd : max ((1.0 - ((1.0 - Bgd) / (2.0 * Fgd))), 0.0))
                               : ((Fgd == 1.0) ? Fgd : min (Bgd / (2.0 * (1.0 - Fgd)), 1.0));

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_linearLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = max (min ((2.0 * Fgd) + Bgd - 1.0, 1.0), 0.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_pinLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Fgd < 0.5) ? min (Bgd, (2.0 * Fgd)) : max (Bgd, ((2.0 * Fgd) - 1.0));

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_hardMix (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Bgd > 0.5) ? 2.0 * Bgd * (Fgd - 1.0) - Fgd : 2.0 * Fgd * Bgd;

   retval = (retval > 0.5) ? (2.0 * retval * (Bgd - 1.0)) - Bgd + 2.0 : 2.0 * retval * Bgd;
   retval = lerp (Bgd, max (min ((2.0 * retval), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------------------------------//

float4 ps_difference (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = lerp (Bgd, abs (Fgd - Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_exclude (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = Fgd + Bgd - (2.0 * Fgd * Bgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_subtract (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = lerp (Bgd, max ((Bgd - Fgd), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_divide (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = (Fgd == 0.0) ? Bgd : min ((Bgd / Fgd), 1.0);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------------------------------//

float4 ps_hue (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = rgb2hsv (Bgd);

   retval.x = (rgb2hsv (Fgd)).x;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

float4 ps_saturation (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = rgb2hsv (Bgd);

   retval.y = retval.y + (rgb2hsv (Fgd)).y;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

float4 ps_colour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = rgb2hsv (Bgd);

   retval.xy = retval.xy + (rgb2hsv (Fgd)).xy;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

float4 ps_luminance (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = rgb2hsv (Bgd);

   retval.z = (rgb2hsv (Fgd)).z;

   retval = lerp (Bgd, hsv2rgb (retval), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.xyz, 1.0);
}

//--------------------------------------------------------------//

float4 ps_negate (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (shadowSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);
   float4 retval = 1.0 - abs (1.0 - Fgd - Bgd);

   retval = lerp (Bgd, retval, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (FgSampler, xy1) : tex2D (borderSampler, xy1);
      retval = lerp (retval, Fgd, Fgd.a);
   }

   retval = lerp (Bgd, retval, Amount);

   return float4 (retval.rgb, 1.0);
}

//--------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (FgSampler, xy1);
   float4 Bgd = tex2D (BgSampler, xy2);

   float4 border = tex2D (borderSampler, xy1);
   float4 shadow = tex2D (shadowSampler, xy1);
   float4 composite = tex2D (compedSampler, xy2);

   if (alphaMode) {
      composite.a = shadow.a;
      Bgd.a = shadow.a;
   }

   if (blendMode <= FGD_BDR_SHADOW) return composite;

   float4 retval;

   if (blendMode == FGD_SHADOW) {
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

   return float4 (retval.rgb, Bgd.a);
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique normal
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 { PixelShader = compile PROFILE ps_normal (); }
}

technique darken
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_darken (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique multiply
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_multiply (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique colourBurn
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_colourBurn (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique linearBurn
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_linearBurn (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique darkerColour
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_darkerColour (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique lighten
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_lighten (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique screen
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_screen (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique add
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_add (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique colourDodge
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_colourDodge (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique linearDodge
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_linearDodge (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique lighterColour
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_lighterColour (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique overlay
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_overlay (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique softLight
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_softLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique hardlight
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_hardLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique vividLight
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_vividLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique linearLight
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_linearLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique pinLight
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_pinLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique hardMix
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_hardMix (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique difference
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_difference (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique exclude
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_exclude (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique subtract
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_subtract (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique divide
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_divide (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique hue
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_hue (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique saturation
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_saturation (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique colour
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_colour (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique luminance
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_luminance (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique negate
{
   pass P_1 < string Script = "RenderColorTarget0 = brdrInp;"; > { PixelShader = compile PROFILE border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = aliased;"; > { PixelShader = compile PROFILE border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = brdrOut;"; > { PixelShader = compile PROFILE border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = fthr_in;"; > { PixelShader = compile PROFILE makeShadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = shadOut;"; > { PixelShader = compile PROFILE feather_it (); }
   pass P_6 < string Script = "RenderColorTarget0 = compose;"; > { PixelShader = compile PROFILE ps_negate (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

