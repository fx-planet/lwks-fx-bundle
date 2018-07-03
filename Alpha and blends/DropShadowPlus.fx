// @Maintainer jwrl
// @Released 2018-07-03
// @Author jwrl
// @Created 2016-04-01
// @see https://www.lwks.com/media/kunena/attachments/6375/DropShadowPlus_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect DropShadowPlus.fx
//
// This effect is a drop shadow and border generator.  It has drop shadow blur, and
// independent colour settings for border and shadow.  Two border generation modes and
// optional border anti-aliassing are also provided.  Additionally, the border centering,
// width and height can also be independently adjusted.
//
// The effect can also output the foreground, border and drop shadow alone, with the
// appropriate alpha channel.  When doing so any background input to the effect will not
// be displayed.
//
// The blend mode of the drop shadow and/or border and/or foreground can also be adjusted.
// This section of the effect attempts to match as closely as possible Photoshop's blends.
// Because that is built around an entirely different colour model and I have no definite
// knowledge of the algorithms used, absolute accuracy isn't claimed or guaranteed.
//
// Bug fixes 20 April 2015
// Fixed a minor bug in the overlay blend which biassed the colour towards red.
// Moved alpha export to its own independent setting.
// Rewrote several blend modes.
//
// LW 14+ version by jwrl 11 January 2017.
// Category changed from "Keying" to "Key", subcategory "Edge Effects" added.
//
// Bug fix 21 July 2017
// Corrected a cross platform issue which could cause the effect to not behave as
// expected on Linux and Mac systems.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 3 July 2018 jwrl.
// Simplified border generation as much as possible while correcting a mismatch between
// sampled and square-edged defaults.
// Changed border generation and drop shadow blur to be frame dependent rather than pixel
// dependent.  Those settings now have the same effect regardless of frame size.
// Reduced the number of samplers required.
// The blur used for the drop shadow now uses the same algorithm as the border generation
// component instead of as previously, Pascal's triangle blur.
// Increased the resolution of the blur/rotation lookup tables.  This is a UHD/8K fix, and
// will have little noticeable effect at lower frame sizes.
// Altered various parameter defaults to more closely match current practice.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Drop shadow plus";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
   string Notes       = "Drop shadow and border generator for text graphics with blend modes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Part_1 : RenderColorTarget;
texture Part_2 : RenderColorTarget;
texture Border : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state {
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Part_1 = sampler_state {
   Texture   = <Part_1>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Part_2 = sampler_state {
   Texture   = <Part_2>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Border = sampler_state {
   Texture   = <Border>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.00;

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
> = 1.0;

float B_width
<
   string Group = "Border";
   string Description = "Width";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

float B_height
<
   string Group = "Border";
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.05;

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
> = { 0.0, 0.0, 0.0, 0.0 };

float S_amount
<
   string Group = "Shadow";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float S_feather
<
   string Group = "Shadow";
   string Description = "Feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.33333333;

float S_offset_X
<
   string Group = "Shadow";
   string Description = "X offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.2;

float S_offset_Y
<
   string Group = "Shadow";
   string Description = "Y offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = -0.2;

float4 S_colour
<
   string Group = "Shadow";
   string Description = "Colour";
   bool SupportsAlpha = false;
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BORDER_SHADOW  1
#define FGD_BDR_SHADOW 2
#define FGD_SHADOW     3
#define FOREGROUND     5
#define BORDER         6

#define LUMA_RED       0.299
#define LUMA_GREEN     0.587
#define LUMA_BLUE      0.114

#define W_SCALE        4000.0
#define X_SCALE        0.005
#define Y_SCALE        0.0088888889

#define F_SCALE        0.005
#define S_SCALE        0.015

#define OFFS_SCALE     0.04

float _OutputAspectRatio;

float2 _rot_0 [] = { { 0.0, 1.0 }, { 0.2588190451, 0.9659258263 }, { 0.5, 0.8660254038 },
                     { 0.7071067812, 0.7071067812 }, { 0.8660254038, 0.5 },
                     { 0.9659258263, 0.2588190451 }, { 1.0, 0.0 } };

float2 _rot_1 [] = { { 0.1305261922, 0.9914448614 }, { 0.3826834324, 0.9238795325 },
                     { 0.6087614290, 0.7933533403 }, { 0.7933533403, 0.6087614290 },
                     { 0.9238795325, 0.3826834324 }, { 0.9914448614, 0.1305261922 } };

//-----------------------------------------------------------------------------------------//
// HSV functions
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

float4 ps_border_A (float2 uv : TEXCOORD1) : COLOR
{
   if (B_amount <= 0.0) return tex2D (s_Foreground, uv);

   float2 offset;
   float2 edge = (B_edge < 2) ? float2 (1.0, _OutputAspectRatio) * X_SCALE
                              : float2 (S_SCALE, 0.0);
   float2 xy = uv + edge * float2 (0.5 - B_centre_X, B_centre_Y - 0.5) * 2.0;

   float alpha = tex2D (s_Foreground, xy).a;

   edge *= B_lock ? B_width : float2 (B_width, B_height);

   for (int i = 0; i < 7; i++) {
      offset = edge * _rot_0 [i];

      alpha += tex2D (s_Foreground, xy + offset).a;
      alpha += tex2D (s_Foreground, xy - offset).a;

      offset.y = -offset.y;

      alpha += tex2D (s_Foreground, xy + offset).a;
      alpha += tex2D (s_Foreground, xy - offset).a;
   }

   return saturate (alpha).xxxx;
}

float4 ps_border_B (float2 uv : TEXCOORD1) : COLOR
{
   if (B_amount <= 0.0) return tex2D (s_Foreground, uv);

   float2 offset;
   float2 edge = (B_edge < 2) ? float2 (_OutputAspectRatio, 1.0) * X_SCALE
                              : float2 (0.0, S_SCALE * _OutputAspectRatio);
   float2 xy = uv + edge * float2 (0.5 - B_centre_X, B_centre_Y - 0.5) * 2.0;

   float alpha = tex2D (s_Part_1, xy).a;

   edge *= B_lock ? B_width : float2 (B_width, B_height);

   for (int i = 0; i < 6; i++) {
      offset = edge * _rot_1 [i];

      alpha += tex2D (s_Part_1, xy + offset).a;
      alpha += tex2D (s_Part_1, xy - offset).a;

      offset.y = -offset.y;

      alpha += tex2D (s_Part_1, xy + offset).a;
      alpha += tex2D (s_Part_1, xy - offset).a;
   }

   return saturate (alpha).xxxx;
}

float4 ps_border_C (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   if (B_amount <= 0.0) return Fgnd;

   float alpha = tex2D (s_Part_2, uv).a;

   if ((B_edge == 0) || (B_edge == 2)) {
      float2 xy = max (Y_SCALE * _OutputAspectRatio, X_SCALE).xx / W_SCALE;

      alpha += tex2D (s_Part_2, uv + xy).a;
      alpha += tex2D (s_Part_2, uv - xy).a;

      xy.x = -xy.x;

      alpha += tex2D (s_Part_2, uv + xy).a;
      alpha += tex2D (s_Part_2, uv - xy).a;
      alpha /= 5.0;
   }

   alpha = max (Fgnd.a, alpha * B_amount);
   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

float4 ps_shadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 scale = float2 (1.0, _OutputAspectRatio) * S_feather * F_SCALE;
   float2 xy2, xy1 = uv - float2 (S_offset_X / _OutputAspectRatio, -S_offset_Y) * OFFS_SCALE;

   float alpha = tex2D (s_Border, xy1).a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      for (int i = 0; i < 7; i++) {
         xy2 = scale * _rot_0 [i];

         alpha += tex2D (s_Border, xy1 + xy2).a;
         alpha += tex2D (s_Border, xy1 - xy2).a;

         xy2.y = -xy2.y;

         alpha += tex2D (s_Border, xy1 + xy2).a;
         alpha += tex2D (s_Border, xy1 - xy2).a;
      }

   alpha /= 29.0;
   }

   return alpha.xxxx;
}

float4 ps_feather (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Part_1, uv);

   float2 xy, scale = float2 (1.0, _OutputAspectRatio) * S_feather * F_SCALE;

   float alpha = retval.a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      for (int i = 0; i < 6; i++) {
         xy = scale * _rot_1 [i];

         alpha += tex2D (s_Part_1, uv + xy).a;
         alpha += tex2D (s_Part_1, uv - xy).a;

         xy.y = -xy.y;

         alpha += tex2D (s_Part_1, uv + xy).a;
         alpha += tex2D (s_Part_1, uv - xy).a;
      }

   alpha /= 25.0;
   }

   alpha *= S_amount;

   retval = tex2D (s_Border, uv);
   alpha  = max (alpha, retval.a);
   retval = lerp (S_colour, retval, retval.a);

   return float4 (retval.rgb, alpha);
}

//-----------------------------------------------------------------------------------------//
// From here on are the various blend modes
//-----------------------------------------------------------------------------------------//

float4 ps_normal (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);

   float3 ret = lerp (tex2D (s_Background, xy2).rgb, Fgd.rgb, Fgd.a * Amount);

   return float4 (ret, 1.0);
}

//-----------------------------------------------------------------------------------------//

float4 ps_darken (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = lerp (Bgd, min (Fgd, Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_multiply (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = lerp (Bgd, Bgd * Fgd, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_colourBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Fgd == 0.0) ? 0.0 : 1.0 - ((1.0 - Bgd) / Fgd);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_linearBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;

   ret = (ret == 0.0) ? 0.0 : 1.0 - ((1.0 - Bgd) / ret);
   ret = lerp (Bgd, (Bgd * ret), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_darkerColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Bgd == 1.0) ? 1.0 : Fgd * Fgd / (1.0 - Bgd);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//

float4 ps_lighten (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = lerp (Bgd, max (Fgd, Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_screen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = max (min ((Bgd * (1.0 - Fgd) + Fgd), 1.0), 0.0);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_add (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = min ((Fgd + Bgd), 1.0);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_colourDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Fgd == 1.0) ? 1.0 : min ((Bgd / (1.0 - Fgd)), 1.0);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_linearDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;

   ret = (ret == 1.0) ? 1.0 : Bgd / (1.0 - ret);
   ret = (Fgd == 1.0) ? 1.0 : ret / (1.0 - Fgd);
   ret = lerp (Bgd, min (max (ret, 0.0), 1.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_lighterColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = float2 ((LUMA_RED * Fgd.r) + (LUMA_GREEN * Fgd.g) + (LUMA_BLUE * Fgd.b), 0.0).xxxy;
   float4 Bgdcol = float2 ((LUMA_RED * Bgd.r) + (LUMA_GREEN * Bgd.g) + (LUMA_BLUE * Bgd.b), 0.0).xxxy;

   ret = (ret > Bgdcol) ? Fgd : Bgd;

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//

float4 ps_overlay (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Bgd < 0.5) ? 2.0 * Bgd * Fgd : 2.0 * Bgd * (Fgd - 1.0) - Fgd;

   ret = lerp (Bgd, min (ret, 1.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_softLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = Fgd - 0.5;

   ret = (Fgd < 0.5) ? Bgd * (Fgd - Bgd * ret) : sqrt (Bgd) * ret - Bgd * (Fgd - 1.0);
   ret = lerp (Bgd, max (min ((2.0 * ret), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_hardLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Fgd < 0.5) ? 2.0 * Bgd * Fgd : 2.0 * ((Bgd * Fgd) - Fgd) - Bgd;

   ret = lerp (Bgd, max (min ((2.0 * ret), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_vividLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Fgd < 0.5) ? ((Fgd == 0.0) ? Fgd : max ((1.0 - ((1.0 - Bgd) / (2.0 * Fgd))), 0.0))
                               : ((Fgd == 1.0) ? Fgd : min (Bgd / (2.0 * (1.0 - Fgd)), 1.0));

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_linearLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = max (min ((2.0 * Fgd) + Bgd - 1.0, 1.0), 0.0);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_pinLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Fgd < 0.5) ? min (Bgd, (2.0 * Fgd)) : max (Bgd, ((2.0 * Fgd) - 1.0));

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_hardMix (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Bgd > 0.5) ? 2.0 * Bgd * (Fgd - 1.0) - Fgd : 2.0 * Fgd * Bgd;

   ret = (ret > 0.5) ? (2.0 * ret * (Bgd - 1.0)) - Bgd + 2.0 : 2.0 * ret * Bgd;
   ret = lerp (Bgd, max (min ((2.0 * ret), 1.0), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//

float4 ps_difference (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = lerp (Bgd, abs (Fgd - Bgd), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_exclude (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = Fgd + Bgd - (2.0 * Fgd * Bgd);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_subtract (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = lerp (Bgd, max ((Bgd - Fgd), 0.0), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

float4 ps_divide (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = (Fgd == 0.0) ? Bgd : min ((Bgd / Fgd), 1.0);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//

float4 ps_hue (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = rgb2hsv (Bgd);

   ret.x = (rgb2hsv (Fgd)).x;

   ret = lerp (Bgd, hsv2rgb (ret), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.xyz, 1.0);
}

float4 ps_saturation (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = rgb2hsv (Bgd);

   ret.y = ret.y + (rgb2hsv (Fgd)).y;

   ret = lerp (Bgd, hsv2rgb (ret), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.xyz, 1.0);
}

float4 ps_colour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = rgb2hsv (Bgd);

   ret.xy = ret.xy + (rgb2hsv (Fgd)).xy;

   ret = lerp (Bgd, hsv2rgb (ret), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.xyz, 1.0);
}

float4 ps_luminance (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = rgb2hsv (Bgd);

   ret.z = (rgb2hsv (Fgd)).z;

   ret = lerp (Bgd, hsv2rgb (ret), Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.xyz, 1.0);
}

//-----------------------------------------------------------------------------------------//

float4 ps_negate (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = 1.0 - abs (1.0 - Fgd - Bgd);

   ret = lerp (Bgd, ret, Fgd.a);

   if (blendMode < FGD_BDR_SHADOW) {
      Fgd = (blendMode == BORDER_SHADOW) ? tex2D (s_Foreground, xy1) : tex2D (s_Border, xy1);
      ret = lerp (ret, Fgd, Fgd.a);
   }

   ret = lerp (Bgd, ret, Amount);

   return float4 (ret.rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float4 border = tex2D (s_Border, xy1);
   float4 shadow = tex2D (s_Part_2, xy1);
   float4 blends = tex2D (s_Part_1, xy1);

   if (alphaMode) {
      blends.a = shadow.a;
      Bgd.a = shadow.a;
   }

   if (blendMode <= FGD_BDR_SHADOW) return blends;

   float4 ret;

   if (blendMode == FGD_SHADOW) {
      ret = lerp (blends, Bgd, border.a);
      ret = lerp (ret, border, border.a * Amount);
      ret = lerp (ret, blends, Fgd.a);
   }
   else {
      ret = lerp (Bgd, shadow, shadow.a * Amount);

      if (blendMode == FOREGROUND) {
         ret = lerp (ret, blends, Fgd.a);
      }
      else {
         ret = lerp (ret, blends, border.a);

         if (blendMode == BORDER) ret = lerp (ret, Fgd, Fgd.a * Amount);
      }
   }

   return float4 (ret.rgb, Bgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique normal
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 { PixelShader = compile PROFILE ps_normal (); }
}

technique darken
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_darken (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique multiply
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_multiply (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique colourBurn
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_colourBurn (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique linearBurn
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_linearBurn (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique darkerColour
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_darkerColour (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique lighten
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_lighten (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique screen
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_screen (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique add
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_add (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique colourDodge
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_colourDodge (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique linearDodge
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_linearDodge (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique lighterColour
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_lighterColour (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique overlay
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_overlay (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique softLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_softLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique hardlight
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_hardLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique vividLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_vividLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique linearLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_linearLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique pinLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_pinLight (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique hardMix
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_hardMix (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique difference
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_difference (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique exclude
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_exclude (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique subtract
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_subtract (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique divide
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_divide (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique hue
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_hue (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique saturation
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_saturation (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique colour
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_colour (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique luminance
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_luminance (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}

technique negate
{
   pass P_1 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_border_A (); }
   pass P_2 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_border_B (); }
   pass P_3 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_border_C (); }
   pass P_4 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_5 < string Script = "RenderColorTarget0 = Part_2;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_6 < string Script = "RenderColorTarget0 = Part_1;"; > { PixelShader = compile PROFILE ps_negate (); }
   pass P_7 { PixelShader = compile PROFILE ps_main (); }
}
