// @Maintainer jwrl
// @Released 2018-07-04
// @Author jwrl
// @Created 2016-03-31
// @see https://www.lwks.com/media/kunena/attachments/6375/DropShadowAndBorder_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks effect DropShadow.fx
//
// This effect is a drop shadow and border generator.  It provides drop shadow blur and
// independent colour settings for border and shadow.  Two border generation modes and
// full border anti-aliassing are provided.  The border centering can also be adjusted
// (thanks Igor for the suggestion).
//
// The effect can also output the foreground, border and drop shadow alone, with the
// appropriate alpha channel.  When doing so any background input to the effect will not
// be displayed.  This allows it to be used with downstream alpha processing effects.
//
// LW 14+ version by jwrl 11 January 2017.
// Category changed from "Keying" to "Key", subcategory "Edge Effects" added.
//
// Bug fix 21 July 2017 by jwrl:
// This addresses a cross platform issue which could cause the effect to not behave as
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
// Improved the resolution of the blur/rotation lookup tables.  This is a UHD/8K fix, and
// will have little noticeable effect at lower frame sizes.
// Altered various parameter defaults to more closely match current practice.
//
// Modified 4 July 2018
// Fixed a bug in border generation causing aspect ratio not to be correctly applied.
// Improved border antialias routine.  It's now much smoother.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Drop shadow and border";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
   string Notes       = "Drop shadow and border generator for text graphics";
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
   Texture = <Part_1>;
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

int SetTechnique
<
   string Description = "Output mode";
   string Enum = "Normal (no alpha),Foreground with alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define X_SCALE 0.005
#define S_SCALE 0.015

#define OFFSET  0.04

#define SQRT_2  0.7071067812

float _OutputAspectRatio;
float _OutputWidth;

float2 _rot_0 [] = { { 0.0, 1.0 }, { 0.2588190451, 0.9659258263 }, { 0.5, 0.8660254038 },
                     { 0.7071067812, 0.7071067812 }, { 0.8660254038, 0.5 },
                     { 0.9659258263, 0.2588190451 }, { 1.0, 0.0 } };

float2 _rot_1 [] = { { 0.1305261922, 0.9914448614 }, { 0.3826834324, 0.9238795325 },
                     { 0.6087614290, 0.7933533403 }, { 0.7933533403, 0.6087614290 },
                     { 0.9238795325, 0.3826834324 }, { 0.9914448614, 0.1305261922 } };

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
   float2 edge = (B_edge < 2) ? float2 (1.0, _OutputAspectRatio) * X_SCALE
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
      float3 xyz = float3 (1.0, 0.0, _OutputAspectRatio) / _OutputWidth;

      float2 xy = xyz.xz * SQRT_2;

      alpha += tex2D (s_Part_2, uv + xyz.xy).a;
      alpha += tex2D (s_Part_2, uv - xyz.xy).a;
      alpha += tex2D (s_Part_2, uv + xyz.yz).a;
      alpha += tex2D (s_Part_2, uv - xyz.yz).a;

      alpha += tex2D (s_Part_2, uv + xy).a;
      alpha += tex2D (s_Part_2, uv - xy).a;

      xy.x = -xy.x;

      alpha += tex2D (s_Part_2, uv + xy).a;
      alpha += tex2D (s_Part_2, uv - xy).a;
      alpha /= 9.0;
   }

   alpha = max (Fgnd.a, alpha * B_amount);
   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

float4 ps_shadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;
   float2 xy2, xy1 = uv - float2 (S_offset_X / _OutputAspectRatio, -S_offset_Y) * OFFSET;

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

   float2 xy, scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;

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

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Part_2, xy1);
   float4 Bgd = tex2D (s_Background, xy2);

   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   return float4 (retval.rgb, 1.0);
}

float4 ps_alpha (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Part_2, uv);

   return float4 (retval.rgb, retval.a * Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique normal
{
   pass P_1
   < string Script = "RenderColorTarget0 = Part_1;"; >
   { PixelShader = compile PROFILE ps_border_A (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Part_2;"; >
   { PixelShader = compile PROFILE ps_border_B (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_border_C (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Part_1;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Part_2;"; >
   { PixelShader = compile PROFILE ps_feather (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}

technique alpha
{
   pass P_1
   < string Script = "RenderColorTarget0 = Part_1;"; >
   { PixelShader = compile PROFILE ps_border_A (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Part_2;"; >
   { PixelShader = compile PROFILE ps_border_B (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_border_C (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Part_1;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Part_2;"; >
   { PixelShader = compile PROFILE ps_feather (); }

   pass P_6
   { PixelShader = compile PROFILE ps_alpha (); }
}
