// @Maintainer jwrl
// @Released 2020-12-28
// @Author jwrl
// @Created 2020-12-28
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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks effect DropShadowBdr.fx
//
// Version history:
//
// Rewrite 2020-12-28 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define SQRT_2  0.7071067812

float _OutputAspectRatio;
float _OutputWidth;
float _OutputHeight;

float _BgXScale = 1.0;
float _BgYScale = 1.0;
float _FgXScale = 1.0;
float _FgYScale = 1.0;

float _square [] = { { 0.0 }, { 0.003233578364 }, { 0.006467156728 }, { 0.009700735092 } };

float2 _rot_0 [] = { { 0.0, 0.01 },
                     { 0.002588190451, 0.009659258263 }, { 0.005, 0.008660254038 },
                     { 0.007071067812, 0.007071067812 }, { 0.008660254038, 0.005 },
                     { 0.009659258263, 0.002588190451 }, { 0.01, 0.0 } };

float2 _rot_1 [] = { { 0.001305261922, 0.009914448614 }, { 0.003826834324, 0.009238795325 },
                     { 0.006087614290, 0.007933533403 }, { 0.007933533403, 0.006087614290 },
                     { 0.009238795325, 0.003826834324 }, { 0.009914448614, 0.001305261922 } };

#define EMPTY    (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (RawBdr, s_RawBorder);
DefineTarget (Border, s_Border);
DefineTarget (Shadow, s_Shadow);

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
> = { 0.0, 0.0, 0.0, 1.0 };

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
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.15;

float S_offset_X
<
   string Group = "Shadow";
   string Description = "X offset";
   string Flags = "DisplayAsPercentage";
   float MinVal = -0.05;
   float MaxVal = 0.05;
> = 0.01;

float S_offset_Y
<
   string Group = "Shadow";
   string Description = "Y offset";
   string Flags = "DisplayAsPercentage";
   float MinVal = -0.05;
   float MaxVal = 0.05;
> = -0.01;

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
   string Description = "Source selection (disconnect title and image key inputs)";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image,Extracted foreground";
> = 1;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? EMPTY : tex2D (s, uv);
}

float fn_alpha (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   return (max (xy.x, xy.y) > 0.5) ? 0.0 : tex2D (s, uv).a;
}

float fn_key2D (sampler s, float2 uv)
{
   float2 xy = abs (uv - 0.5.xx);

   if (max (xy.x, xy.y) > 0.5) return 0.0;

   float4 Fgd = tex2D (s, uv);

   if ((Fgd.a == 0.0) || (Source == 1)) return Fgd.a;
   if (Source == 0) return pow (Fgd.a, 0.5);

   float4 Bgd = fn_tex2D (s_Background, uv);

   float kDiff = distance (Fgd.g, Bgd.g);

   kDiff = max (kDiff, distance (Fgd.r, Bgd.r));
   kDiff = max (kDiff, distance (Fgd.b, Bgd.b));

   return smoothstep (0.0, 0.25, kDiff);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_border_A (float2 uv : TEXCOORD1) : COLOR
{
   if (B_amount <= 0.0) return fn_tex2D (s_Foreground, uv);

   float Xpos = (0.5 - B_centre_X) * _BgXScale  / _FgXScale;
   float Ypos = (B_centre_Y - 0.5) * _BgYScale / _FgYScale;

   float2 offset, edge = float2 (1.0, _OutputAspectRatio);
   float2 xy = uv + edge * float2 (Xpos, Ypos);

   float alpha = fn_key2D (s_Foreground, uv);

   edge *= B_lock ? B_width.xx : float2 (B_width, B_height);

   for (int i = 0; i < 7; i++) {
      offset = edge * _rot_0 [i];

      alpha = max (alpha, fn_key2D (s_Foreground, xy + offset));
      alpha = max (alpha, fn_key2D (s_Foreground, xy - offset));

      offset.y = -offset.y;

      alpha = max (alpha, fn_key2D (s_Foreground, xy + offset));
      alpha = max (alpha, fn_key2D (s_Foreground, xy - offset));
   }

   for (int i = 0; i < 6; i++) {
      offset = edge * _rot_1 [i];

      alpha = max (alpha, fn_key2D (s_Foreground, xy + offset));
      alpha = max (alpha, fn_key2D (s_Foreground, xy - offset));

      offset.y = -offset.y;

      alpha = max (alpha, fn_key2D (s_Foreground, xy + offset));
      alpha = max (alpha, fn_key2D (s_Foreground, xy - offset));
   }

   return alpha.xxxx;
}

float4 ps_border_B (float2 uv : TEXCOORD1) : COLOR
{
   if (B_amount <= 0.0) return fn_tex2D (s_Foreground, uv);

   float Xpos = (0.5 - B_centre_X) * _BgXScale  / _FgXScale;
   float Ypos = (B_centre_Y - 0.5) * _BgYScale / _FgYScale;

   float2 offset, edge = float2 (1.0, _OutputAspectRatio);
   float2 xy = uv + edge * float2 (Xpos, Ypos);

   float alpha = fn_key2D (s_Foreground, uv);

   edge *= B_lock ? B_width.xx : float2 (B_width, B_height);

   for (int i = 0; i < 4; i++) {
      offset.x = edge.x * _square [i];

      for (int j = 0; j < 4; j++) {
         offset.y = edge.y * _square [j];

         alpha = max (alpha, fn_key2D (s_Foreground, xy + offset));
         alpha = max (alpha, fn_key2D (s_Foreground, xy - offset));

         offset.y = -offset.y;

         alpha = max (alpha, fn_key2D (s_Foreground, xy + offset));
         alpha = max (alpha, fn_key2D (s_Foreground, xy - offset));
      }
   }

   return alpha.xxxx;
}

float4 ps_antialias (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);

   Fgnd.a = fn_key2D (s_Foreground, uv);

   if (Source == 0) Fgnd.rgb /= Fgnd.a;
   else if (Source == 2) Fgnd.rgb *= Fgnd.a;

   if (B_amount <= 0.0) return Fgnd;

   float alpha = fn_alpha (s_RawBorder, uv);

   float3 xyz = float3 (1.0 / _OutputWidth, 0.0, 1.0 / _OutputHeight);

   float2 xy = xyz.xz * SQRT_2;

   alpha += fn_alpha (s_RawBorder, uv + xyz.xy);
   alpha += fn_alpha (s_RawBorder, uv - xyz.xy);
   alpha += fn_alpha (s_RawBorder, uv + xyz.yz);
   alpha += fn_alpha (s_RawBorder, uv - xyz.yz);

   alpha += fn_alpha (s_RawBorder, uv + xy);
   alpha += fn_alpha (s_RawBorder, uv - xy);

   xy.x = -xy.x;

   alpha += fn_alpha (s_RawBorder, uv + xy);
   alpha += fn_alpha (s_RawBorder, uv - xy);
   alpha /= 9.0;

   alpha = max (Fgnd.a, alpha * B_amount);
   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

float4 ps_direct (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgnd = fn_tex2D (s_Foreground, uv);

   Fgnd.a = fn_key2D (s_Foreground, uv);

   if (Source == 0) Fgnd.rgb /= Fgnd.a;
   else if (Source == 2) Fgnd.rgb *= Fgnd.a;

   if (B_amount <= 0.0) return Fgnd;

   float alpha = max (Fgnd.a, fn_alpha (s_RawBorder, uv) * B_amount);

   Fgnd  = lerp (B_colour, Fgnd, Fgnd.a);

   return float4 (Fgnd.rgb, alpha);
}

float4 ps_shadow (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = uv - float2 (S_offset_X / _OutputAspectRatio, -S_offset_Y);

   float alpha = fn_alpha (s_Border, xy1);

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      float2 scale = float2 (1.0, _OutputAspectRatio) * S_feather;
      float2 xy2;

      for (int i = 0; i < 7; i++) {
         xy2 = scale * _rot_0 [i];

         alpha += fn_alpha (s_Border, xy1 + xy2);
         alpha += fn_alpha (s_Border, xy1 - xy2);

         xy2.y = -xy2.y;

         alpha += fn_alpha (s_Border, xy1 + xy2);
         alpha += fn_alpha (s_Border, xy1 - xy2);
      }

   alpha /= 29.0;
   }

   return alpha.xxxx;
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float alpha = fn_alpha (s_Shadow, xy1);

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      float2 scale = float2 (1.0, _OutputAspectRatio) * S_feather;
      float2 uv;

      for (int i = 0; i < 6; i++) {
         uv = scale * _rot_1 [i];

         alpha += fn_alpha (s_Shadow, xy1 + uv);
         alpha += fn_alpha (s_Shadow, xy1 - uv);

         uv.y = -uv.y;

         alpha += fn_alpha (s_Shadow, xy1 + uv);
         alpha += fn_alpha (s_Shadow, xy1 - uv);
      }

   alpha /= 25.0;
   }

   alpha *= S_amount;

   float4 retval = fn_tex2D (s_Border, xy1);

   alpha  = max (alpha, retval.a);
   alpha  = lerp (alpha, 0.0, fn_key2D (s_Foreground, xy1) * (1.0 - F_amount));
   retval = lerp (S_colour, retval, retval.a);
   retval.a = alpha;
   alpha *= Amount;

   if (AlphaMode == 1) return retval;

   return lerp (fn_tex2D (s_Background, xy2), retval, alpha);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique DropShadowBdr_0
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

technique DropShadowBdr_1
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

technique DropShadowBdr_2
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

technique DropShadowBdr_3
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
