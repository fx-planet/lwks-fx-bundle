// @Maintainer jwrl
// @Released 2020-07-11
// @Author jwrl
// @Created 2018-10-22
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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DropShadowBlend.fx
//
// Version history:
//
// Update 11 July 2020 jwrl.
// Added a delta key to separate blended effects from the background.  THIS MAY BREAK
// BACKWARD COMPATIBILITY (BUT SHOULDN'T)!!!!!
//
// Update 30 April 2019 jwrl.
// Removed a duplicate windows ps 3.0 declaration.
// Added a fade mode to the foreground so it can be dropped out leaving just the border
// and/or drop shadow.
// The extra parameter required has broken backward compatibility so "Add" has also been
// removed since it was just a duplicate of "Linear dodge" (see rewrite notes above).
//
// Update 23 December 2018 jwrl.
// Converted to version 14.5 and up.
// Modified Windows version to compile as ps_3_0.
// Formatted the descriptive block so that it can automatically be read.
//
// Update 25 November 2018 jwrl.
// Added alpha boost function for Lightworks titles.
// Changed category to "Mix".
// Changed subcategory to "Blend Effects".
//
// Rewrite 22 October 2018 jwrl.
// Like DropShadow.fx, this effect had a heap of additional code and code modifications to
// fix or debug a range of issues, including cross-platform problems.  This is a complete
// rewrite of the 4 July 2018 version, which was the last stable release prior to this one.
// In all cases the number of passes required has been reduced by one, but this may not
// necessarily mean a dramatic improvement in efficiency.
//
// Fixes in this rewrite:
// Linearity of the border depth has been improved.
// "Darker colour" now works as it should.  Previously it was similar to "Linear dodge".
// The entire "Overlay/light" category has been reworked to match Photoshop versions.
// "Exclusion" has been fixed.  Previously it was functionally identical to "Normal".
// "Add" has been retained as a selection for backward compatibility reasons, although
// it is now (correctly) identical to "Linear Dodge" and uses the same code.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Drop shadow plus blend";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Drop shadow and border generator for text graphics with blend modes";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Border : RenderColorTarget;
texture Shadow : RenderColorTarget;

texture Composite : RenderColorTarget;
texture Blended   : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

sampler s_Foreground = sampler_state {
   Texture   = <Fg>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Border = sampler_state {
   Texture   = <Border>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Shadow = sampler_state {
   Texture   = <Shadow>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Composite = sampler_state {
   Texture   = <Composite>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
   MinFilter = Point;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Blended = sampler_state {
   Texture   = <Blended>;
   AddressU  = ClampToEdge;
   AddressV  = ClampToEdge;
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
> = 1.0;

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
   string Enum = "Normal,Darken,Multiply,Colour burn,Linear burn,Darker colour,Lighten,Screen,Colour dodge,Linear dodge (Add),Lighter colour,Overlay,Soft Light,Hard Light,Vivid Light,Linear Light,Pin Light,Hard mix,Difference,Exclusion,Subtract,Divide,Hue,Saturation,Colour,Luminosity,Negate";
> = 0;

bool alphaMode
<
   string Group = "Border and shadow modes";
   string Description = "Don't export background alpha";
> = false;

int Source
<
   string Description = "Source selection (disconnect input to text effects first)";
   string Enum = "Crawl / roll / titles,Video / external image,Extracted foreground";
> = 1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SHADOW        0
#define BORDER_SHADOW 1
#define FGD_SHADOW    3
#define FGD_BORDER    4
#define FOREGROUND    5
#define BORDER        6

#define LUMA_VAL      float3(0.299, 0.587, 0.114)

#define X_SCALE       0.5

#define OFFSET        0.04

#define SQRT_2        0.7071067812

float _OutputAspectRatio;
float _OutputWidth;

float _square [] = { { 0.0 }, { 0.003233578364 }, { 0.006467156728 }, { 0.009700735092 } };

float2 _rot_0 [] = { { 0.0, 0.01 },
                     { 0.002588190451, 0.009659258263 }, { 0.005, 0.008660254038 },
                     { 0.007071067812, 0.007071067812 }, { 0.008660254038, 0.005 },
                     { 0.009659258263, 0.002588190451 }, { 0.01, 0.0 } };

float2 _rot_1 [] = { { 0.001305261922, 0.009914448614 }, { 0.003826834324, 0.009238795325 },
                     { 0.006087614290, 0.007933533403 }, { 0.007933533403, 0.006087614290 },
                     { 0.009238795325, 0.003826834324 }, { 0.009914448614, 0.001305261922 } };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_border_A (float2 uv : TEXCOORD1)
{
   if (B_amount <= 0.0) return tex2D (s_Foreground, uv).a;

   float2 offset, edge = float2 (1.0, _OutputAspectRatio);
   float2 xy = uv + edge * float2 (0.5 - B_centre_X, B_centre_Y - 0.5) * 2.0;

   float alpha = tex2D (s_Foreground, xy).a;

   edge *= B_lock ? B_width.xx : float2 (B_width, B_height);

   for (int i = 0; i < 7; i++) {
      offset = edge * _rot_0 [i];

      alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
      alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);

      offset.y = -offset.y;

      alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
      alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);
   }

   for (int j = 0; j < 6; j++) {
      offset = edge * _rot_1 [j];

      alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
      alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);

      offset.y = -offset.y;

      alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
      alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);
   }

   return alpha;
}

float fn_border_B (float2 uv)
{
   if (B_amount <= 0.0) return tex2D (s_Foreground, uv).a;

   float2 offset, edge = float2 (1.0, _OutputAspectRatio);
   float2 xy = uv + edge * float2 (0.5 - B_centre_X, B_centre_Y - 0.5);

   float alpha = tex2D (s_Foreground, xy).a;

   edge *= B_lock ? B_width.xx : float2 (B_width, B_height);

   for (int i = 0; i < 4; i++) {
      offset.x = edge.x * _square [i];

      for (int j = 0; j < 4; j++) {
         offset.y = edge.y * _square [j];

         alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
         alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);

         offset.y = -offset.y;

         alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
         alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);
      }
   }

   return alpha;
}

//------------------------------------- HSV functions -------------------------------------//

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

//---------------------------------- Boost function ---------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   float4 Fgd = tex2D (s_Sampler, uv);

   if (Source == 0) {
      Fgd.a    = pow (Fgd.a, 0.5);
      Fgd.rgb /= Fgd.a;
   }
   else if (Source == 2) {
      if (Fgd.a == 0.0) return 0.0.xxxx;

      float4 Bgd = tex2D (s_Background, uv);

      float kDiff = distance (Fgd.g, Bgd.g);

      kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
      kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

      Fgd.a = smoothstep (0.0, 0.25, kDiff);
      Fgd.rgb *= Fgd.a;
   }

   return Fgd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_border (float2 uv : TEXCOORD1) : COLOR
{
   if (B_edge < 2) return fn_border_A (uv).xxxx;

   return fn_border_B (uv).xxxx;
}

float4 ps_antialias (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);

   if (B_amount <= 0.0) return Fgnd;

   float alpha = tex2D (s_Composite, uv).a;

   if ((B_edge == 0) || (B_edge == 2)) {
      float3 xyz = float3 (1.0, 0.0, _OutputAspectRatio) / _OutputWidth;

      float2 xy = xyz.xz * SQRT_2;

      alpha += tex2D (s_Composite, uv + xyz.xy).a;
      alpha += tex2D (s_Composite, uv - xyz.xy).a;
      alpha += tex2D (s_Composite, uv + xyz.yz).a;
      alpha += tex2D (s_Composite, uv - xyz.yz).a;

      alpha += tex2D (s_Composite, uv + xy).a;
      alpha += tex2D (s_Composite, uv - xy).a;

      xy.x = -xy.x;

      alpha += tex2D (s_Composite, uv + xy).a;
      alpha += tex2D (s_Composite, uv - xy).a;
      alpha /= 9.0;
   }

   alpha = max (Fgnd.a, alpha * B_amount);
   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

float4 ps_shadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = uv - float2 (S_offset_X / _OutputAspectRatio, -S_offset_Y) * OFFSET;

   float alpha = tex2D (s_Border, xy1).a;

   if ((S_amount <= 0.0) || (S_feather <= 0.0)) return alpha.xxxx;

   float2 xy2, scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;

   for (int i = 0; i < 7; i++) {
      xy2 = scale * _rot_0 [i];

      alpha += tex2D (s_Border, xy1 + xy2).a;
      alpha += tex2D (s_Border, xy1 - xy2).a;

      xy2.y = -xy2.y;

      alpha += tex2D (s_Border, xy1 + xy2).a;
      alpha += tex2D (s_Border, xy1 - xy2).a;
   }

   return (alpha / 29.0).xxxx;
}

float4 ps_feather (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Shadow, uv);

   float2 xy, scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;

   float alpha = retval.a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      for (int i = 0; i < 6; i++) {
         xy = scale * _rot_1 [i];

         alpha += tex2D (s_Shadow, uv + xy).a;
         alpha += tex2D (s_Shadow, uv - xy).a;

         xy.y = -xy.y;

         alpha += tex2D (s_Shadow, uv + xy).a;
         alpha += tex2D (s_Shadow, uv - xy).a;
      }

   alpha /= 25.0;
   }

   alpha *= S_amount;

   retval = tex2D (s_Border, uv);
   alpha  = max (alpha, retval.a);
   retval = lerp (S_colour, retval, retval.a);

   return float4 (retval.rgb, alpha);
}

//----------------------- From here on are the various blend modes ------------------------//

float4 ps_normal (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);

   return lerp (tex2D (s_Background, xy2), Fgd, Fgd.a);
}

//--------------------------------------- GROUP 1 -----------------------------------------//

float4 ps_darken (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.r = min (Fgd.r, Bgd.r);
   Fgd.g = min (Fgd.g, Bgd.g);
   Fgd.b = min (Fgd.b, Bgd.b);

   return lerp (Bgd, Fgd, Fgd.a);
}

float4 ps_multiply (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   return lerp (Bgd, Bgd * Fgd, Fgd.a);
}

float4 ps_colourBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   if (Fgd.r > 0.0) Fgd.r = 1.0 - ((1.0 - Bgd.r) / Fgd.r);
   if (Fgd.g > 0.0) Fgd.g = 1.0 - ((1.0 - Bgd.g) / Fgd.g);
   if (Fgd.b > 0.0) Fgd.b = 1.0 - ((1.0 - Bgd.b) / Fgd.b);

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_linearBurn (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.rgb = saturate (Bgd.rgb + Fgd.rgb - 1.0.xxx);

   return lerp (Bgd, Fgd, Fgd.a);
}

float4 ps_darkerColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float luma = dot (Bgd.rgb, LUMA_VAL);

   if (dot (Fgd.rgb, LUMA_VAL) > luma) Fgd.rgb = Bgd.rgb;

   return lerp (Bgd, Fgd, Fgd.a);
}

//--------------------------------------- GROUP 2 -----------------------------------------//

float4 ps_lighten (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   return lerp (Bgd, max (Fgd, Bgd), Fgd.a);
}

float4 ps_screen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.r = (Fgd.r == 1.0) ? 1.0 : Fgd.r + Bgd.r * (1.0 - Fgd.r);
   Fgd.g = (Fgd.g == 1.0) ? 1.0 : Fgd.g + Bgd.g * (1.0 - Fgd.g);
   Fgd.b = (Fgd.b == 1.0) ? 1.0 : Fgd.b + Bgd.b * (1.0 - Fgd.b);

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_colourDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.r = (Fgd.r == 1.0) ? 1.0 : Bgd.r / (1.0 - Fgd.r);
   Fgd.g = (Fgd.g == 1.0) ? 1.0 : Bgd.g / (1.0 - Fgd.g);
   Fgd.b = (Fgd.b == 1.0) ? 1.0 : Bgd.b / (1.0 - Fgd.b);

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_linearDodge (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   return lerp (Bgd, saturate (Fgd + Bgd), Fgd.a);
}

float4 ps_lighterColour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float luma = dot (LUMA_VAL, Fgd.rgb);

   float4 ret = (luma > dot (LUMA_VAL, Bgd.rgb)) ? Fgd : Bgd;

   return lerp (Bgd, ret, Fgd.a);
}

//--------------------------------------- GROUP 3 -----------------------------------------//

float4 ps_overlay (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float3 retMin = 2.0 * Bgd.rgb * Fgd.rgb;
   float3 retMax = 2.0 * (Bgd.rgb + Fgd.rgb) - retMin - 1.0.xxx;

   Fgd.r = (Bgd.r <= 0.5) ? retMin.r : retMax.r;
   Fgd.g = (Bgd.g <= 0.5) ? retMin.g : retMax.g;
   Fgd.b = (Bgd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_softLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float3 retMax = (2.0 * Fgd.rgb) - 1.0.xxx;
   float3 retMin = Bgd.rgb * (retMax * (1.0.xxx - Bgd.rgb) + 1.0.xxx);

   retMax *= sqrt (Bgd.rgb) - Bgd.rgb;
   retMax += Bgd.rgb;

   Fgd.r = (Fgd.r <= 0.5) ? retMin.r : retMax.r;
   Fgd.g = (Fgd.g <= 0.5) ? retMin.g : retMax.g;
   Fgd.b = (Fgd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_hardLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float3 retMin = 2.0 * Fgd.rgb * Bgd.rgb;
   float3 retMax = (2.0 * (Fgd.rgb + Bgd.rgb)) - retMin.rgb - 1.0.xxx;

   Fgd.r = (Fgd.r <= 0.5) ? retMin.r : retMax.r;
   Fgd.g = (Fgd.g <= 0.5) ? retMin.g : retMax.g;
   Fgd.b = (Fgd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_vividLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float3 retMin = saturate (1.0.xxx - (1.0.xxx - Bgd.rgb) / (2.0 * Fgd.rgb));
   float3 retMax = saturate (Bgd.rgb / (2.0 * (1.0.xxx - Fgd.rgb)));

   Fgd.r = (Fgd.r <= 0.5) ? retMin.r : retMax.r;
   Fgd.g = (Fgd.g <= 0.5) ? retMin.g : retMax.g;
   Fgd.b = (Fgd.b <= 0.5) ? retMin.b : retMax.b;

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_linearLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.rgb = Bgd.rgb + (2.0 * Fgd.rgb) - 1.0.xxx;

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_pinLight (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float3 retMax = 2.0 * Fgd.rgb;
   float3 retMin = retMax - 1.0.xxx;

   Fgd.r = (Bgd.r > retMax.r) ? retMax.r : (Bgd.r < retMin.r) ? retMin.r : Bgd.r;
   Fgd.g = (Bgd.g > retMax.g) ? retMax.g : (Bgd.g < retMin.g) ? retMin.g : Bgd.g;
   Fgd.b = (Bgd.b > retMax.b) ? retMax.b : (Bgd.b < retMin.b) ? retMin.b : Bgd.b;

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

float4 ps_hardMix (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = 1.0.xxxx - Bgd;

   Fgd.r = (Fgd.r < ret.r) ? 0.0 : 1.0;
   Fgd.g = (Fgd.g < ret.g) ? 0.0 : 1.0;
   Fgd.b = (Fgd.b < ret.b) ? 0.0 : 1.0;

   return lerp (Bgd, Fgd, Fgd.a);
}

//--------------------------------------- GROUP 4 -----------------------------------------//

float4 ps_difference (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.rgb = abs (Fgd.rgb - Bgd.rgb);

   return lerp (Bgd, Fgd, Fgd.a);
}

float4 ps_exclude (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.rgb= saturate (Fgd.rgb + Bgd.rgb * (1.0.xxx - (2.0 * Fgd.rgb)));

   return lerp (Bgd, Fgd, Fgd.a);
}

float4 ps_subtract (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.rgb = saturate (Bgd.rgb - Fgd.rgb);

   return lerp (Bgd, Fgd, Fgd.a);
}

float4 ps_divide (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.r = (Fgd.r == 0.0) ? 1.0 : Bgd.r / Fgd.r;
   Fgd.g = (Fgd.g == 0.0) ? 1.0 : Bgd.g / Fgd.g;
   Fgd.b = (Fgd.b == 0.0) ? 1.0 : Bgd.b / Fgd.b;

   return lerp (Bgd, saturate (Fgd), Fgd.a);
}

//--------------------------------------- GROUP 5 -----------------------------------------//

float4 ps_hue (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = fn_rgb2hsv (Bgd);

   ret.xw = fn_rgb2hsv (Fgd).xw;

   return lerp (Bgd, fn_hsv2rgb (ret), Fgd.a);
}

float4 ps_saturation (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = fn_rgb2hsv (Bgd);

   ret.yw = fn_rgb2hsv (Fgd).yw;

   return lerp (Bgd, fn_hsv2rgb (ret), Fgd.a);
}

float4 ps_colour (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = fn_rgb2hsv (Fgd);

   ret.x = fn_rgb2hsv (Bgd).x;

   return lerp (Bgd, fn_hsv2rgb (ret), Fgd.a);
}

float4 ps_luminance (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 ret = fn_rgb2hsv (Bgd);

   ret.zw = fn_rgb2hsv (Fgd).zw;

   return lerp (Bgd, fn_hsv2rgb (ret), Fgd.a);
}

//------------------------------------- NON_PHOTOSHOP -------------------------------------//

float4 ps_negate (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Composite, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.rgb = 1.0.xxx - abs (1.0.xxx - Fgd.rgb - Bgd.rgb);

   return lerp (Bgd, Fgd, Fgd.a);
}

//---------------------------------- End of blend modes -----------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = fn_tex2D (s_Foreground, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   Fgd.rgb = lerp (Bgd.rgb, Fgd.rgb, F_amount);

   float4 border = tex2D (s_Border, xy1);
   float4 shadow = tex2D (s_Composite, xy1);
   float4 blends = tex2D (s_Blended, xy1);
   float4 retval = (blendMode < FGD_BORDER)
                 ? lerp (Bgd, blends, shadow.a) : lerp (Bgd, shadow, shadow.a);

   retval = ((blendMode != SHADOW) && (blendMode != FGD_SHADOW) && (blendMode != FOREGROUND))
          ? lerp (retval, blends, border.a) : lerp (retval, border, border.a);

   retval = ((blendMode > BORDER_SHADOW) && (blendMode < BORDER))
          ? lerp (retval, blends, Fgd.a) : lerp (retval, Fgd, Fgd.a);

   retval   = lerp (Bgd, retval, Amount);
   retval.a = alphaMode ? shadow.a : Bgd.a;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique normal
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_normal (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique darken
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_darken (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique multiply
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_multiply (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique colourBurn
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_colourBurn (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique linearBurn
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_linearBurn (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique darkerColour
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_darkerColour (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique lighten
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_lighten (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique screen
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_screen (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique colourDodge
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_colourDodge (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique linearDodge
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_linearDodge (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique lighterColour
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_lighterColour (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique overlay
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_overlay (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique softLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_softLight (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique hardlight
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_hardLight (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique vividLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_vividLight (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique linearLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_linearLight (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique pinLight
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_pinLight (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique hardMix
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_hardMix (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique difference
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_difference (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique exclude
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_exclude (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique subtract
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_subtract (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique divide
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_divide (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique hue
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_hue (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique saturation
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_saturation (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique colour
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_colour (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique luminance
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_luminance (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}

technique negate
{
   pass P_1 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_border (); }
   pass P_2 < string Script = "RenderColorTarget0 = Border;"; > { PixelShader = compile PROFILE ps_antialias (); }
   pass P_3 < string Script = "RenderColorTarget0 = Shadow;"; > { PixelShader = compile PROFILE ps_shadow (); }
   pass P_4 < string Script = "RenderColorTarget0 = Composite;"; > { PixelShader = compile PROFILE ps_feather (); }
   pass P_5 < string Script = "RenderColorTarget0 = Blended;"; > { PixelShader = compile PROFILE ps_negate (); }
   pass P_6 { PixelShader = compile PROFILE ps_main (); }
}
