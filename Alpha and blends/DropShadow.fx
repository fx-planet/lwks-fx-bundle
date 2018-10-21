// @Maintainer jwrl
// @Released 2018-10-21
// @Author jwrl
// @Created 2018-10-21
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
// be displayed.  This allows it to be used with downstream alpha handling effects.
//
// Rewritten 21 October 2018 jwrl.
// In the previous version of this effect there had been quite a lot of bug fixes and so
// it had grown considerably over its lifetime.  This rewrite aims to reduce that bloat.
// The six passes of the earlier version are now four and the maths has also been somewhat
// simplified.  An extremely minor cross-platform bug was also found and fixed and a small
// variation in border depth between fully sampled and square edged borders has also been
// corrected.
//
// This version is functionally identical to the version of 4 July 2018.  That was the
// last release of the original effect.
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

texture RawBdr : RenderColorTarget;
texture Border : RenderColorTarget;
texture Shadow : RenderColorTarget;

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

sampler s_RawBorder = sampler_state {
   Texture   = <RawBdr>;
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

sampler s_Shadow = sampler_state {
   Texture = <Shadow>;
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

int SetTechnique
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

int AlphaMode
<
   string Description = "Output mode";
   string Enum = "Normal (no alpha),Foreground with alpha";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define X_SCALE 0.5

#define OFFSET  0.04

#define SQRT_2  0.7071067812

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
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_border_A (float2 uv : TEXCOORD1) : COLOR
{
   if (B_amount <= 0.0) return tex2D (s_Foreground, uv);

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

   for (int i = 0; i < 6; i++) {
      offset = edge * _rot_1 [i];

      alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
      alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);

      offset.y = -offset.y;

      alpha = max (alpha, tex2D (s_Foreground, xy + offset).a);
      alpha = max (alpha, tex2D (s_Foreground, xy - offset).a);
   }

   return alpha.xxxx;
}

float4 ps_border_B (float2 uv : TEXCOORD1) : COLOR
{
   if (B_amount <= 0.0) return tex2D (s_Foreground, uv);

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

   return alpha.xxxx;
}

float4 ps_antialias (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   if (B_amount <= 0.0) return Fgnd;

   float alpha = tex2D (s_RawBorder, uv).a;

   float3 xyz = float3 (1.0, 0.0, _OutputAspectRatio) / _OutputWidth;

   float2 xy = xyz.xz * SQRT_2;

   alpha += tex2D (s_RawBorder, uv + xyz.xy).a;
   alpha += tex2D (s_RawBorder, uv - xyz.xy).a;
   alpha += tex2D (s_RawBorder, uv + xyz.yz).a;
   alpha += tex2D (s_RawBorder, uv - xyz.yz).a;

   alpha += tex2D (s_RawBorder, uv + xy).a;
   alpha += tex2D (s_RawBorder, uv - xy).a;

   xy.x = -xy.x;

   alpha += tex2D (s_RawBorder, uv + xy).a;
   alpha += tex2D (s_RawBorder, uv - xy).a;
   alpha /= 9.0;

   alpha = max (Fgnd.a, alpha * B_amount);
   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

float4 ps_direct (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, uv);

   if (B_amount <= 0.0) return Fgnd;

   float alpha = max (Fgnd.a, tex2D (s_RawBorder, uv).a * B_amount);

   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

float4 ps_shadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = uv - float2 (S_offset_X / _OutputAspectRatio, -S_offset_Y) * OFFSET;

   float alpha = tex2D (s_Border, xy1).a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      float2 scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;
      float2 xy2;

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

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float alpha = tex2D (s_Shadow, xy1).a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      float2 scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;
      float2 uv;

      for (int i = 0; i < 6; i++) {
         uv = scale * _rot_1 [i];

         alpha += tex2D (s_Shadow, xy1 + uv).a;
         alpha += tex2D (s_Shadow, xy1 - uv).a;

         uv.y = -uv.y;

         alpha += tex2D (s_Shadow, xy1 + uv).a;
         alpha += tex2D (s_Shadow, xy1 - uv).a;
      }

   alpha /= 25.0;
   }

   alpha *= S_amount;

   float4 retval = tex2D (s_Border, xy1);

   alpha  = max (alpha, retval.a);
   retval = lerp (S_colour, retval, retval.a);
   retval.a = alpha;
   alpha *= Amount;

   if (AlphaMode == 1) return float4 (retval.rgb, alpha);

   return lerp (tex2D (s_Background, xy2), retval, alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DropShadow_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = RawBdr;"; >
   { PixelShader = compile PROFILE ps_border_A (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_antialias (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Shadow;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique DropShadow_1
{
   pass P_1
   < string Script = "RenderColorTarget0 = RawBdr;"; >
   { PixelShader = compile PROFILE ps_border_A (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_direct (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Shadow;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique DropShadow_2
{
   pass P_1
   < string Script = "RenderColorTarget0 = RawBdr;"; >
   { PixelShader = compile PROFILE ps_border_B (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_antialias (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Shadow;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}

technique DropShadow_3
{
   pass P_1
   < string Script = "RenderColorTarget0 = RawBdr;"; >
   { PixelShader = compile PROFILE ps_border_B (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_direct (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Shadow;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_4
   { PixelShader = compile PROFILE ps_main (); }
}
