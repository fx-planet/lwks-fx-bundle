// @Maintainer jwrl
// @Released 2020-11-13
// @Author jwrl
// @Created 2018-06-08
// @see https://www.lwks.com/media/kunena/attachments/6375/LumaMatte_640.png

/**
 This effect is designed to generate a key from the foreground video and use that key
 to superimpose the foreground over the background or fill the foreground key shape
 with a flat matte colour.  It has been designed with text supers in mind.  The key
 can be produced from a white on black image or inverted.  Alternatively the alpha
 channel can be used instead of the video to provide the key.  The same controls apply
 to the alpha channel in this mode as do to the video.

 A coloured border can also be generated from the key.  Border opacity, width and
 colour are all adjustable.  A drop shadow with the same range of adjustments can also
 be produced, and the position of that shadow can be adjusted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyAndMatte.fx
//
// Version history:
//
// Update 2020-11-13 jwrl.
// Added Cansize switch for LW 2021 support.
//
// Modified 22 Feb 2019 by user jwrl:
// Modified the key generation so that selecting key alpha bypasses the key clip.
// Key clip and tolerance is now calculated from the RGB sum, not the RGB maximum.
//
// Modified 23 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 26 Nov 2018 by user schrauber:
// Changed subcategory from "User Effects" to "Key Extras".
//
// Modified 4 July 2018
// Improved key tolerance calculation.  It's now symmetrical around clip.
// Fixed a bug in border generation causing aspect ratio to not be correctly applied.
// Improved border antialias routine.  It's now much smoother.
//
// Modified 3 July 2018
// Added ability to key in external video.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Lumakey and matte";
   string Category    = "Key";
   string SubCategory = "Key Extras";
   string Notes       = "Generates a key from video, fills it with colour or other video and generates a border and/or drop shadow.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Key;
texture V_1;
texture V_2;

texture KeyFgd : RenderColorTarget;
texture Part_1 : RenderColorTarget;
texture Part_2 : RenderColorTarget;
texture Border : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Key_Vid = sampler_state { Texture = <Key>; };
sampler s_Video_1 = sampler_state { Texture = <V_1>; };
sampler s_Video_2 = sampler_state { Texture = <V_2>; };

sampler s_Foreground = sampler_state {
   Texture   = <KeyFgd>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
> = 1.0;

bool K_alpha
<
   string Description = "Use key alpha channel";
> = false;

bool K_invert
<
   string Description = "Invert key";
> = false;

float K_clip
<
   string Group = "Key";
   string Description = "Clip level";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

float K_range
<
   string Group = "Key";
   string Description = "Tolerance";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.50;

int K_fill
<
   string Group = "Key";
   string Description = "Fill key with:";
   string Enum = "Key video,Video 1,Matte colour";
> = 2;

float4 K_matte
<
   string Group = "Key";
   string Description = "Matte colour";
   bool SupportsAlpha = false;
> = { 1.0, 1.0, 1.0, 1.0 };

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define X_SCALE 0.005
#define OFFSET  0.04

#define INVSQR2 0.7071067812

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

float4 ps_key_gen (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd   = tex2D (s_Key_Vid, xy1);
   float4 retval = (K_fill == 2) ? K_matte
                 : (K_fill == 1) ? tex2D (s_Video_1, xy2) : Fgnd;

   float2 half_pix = float2 (1.0, _OutputAspectRatio) / (_OutputWidth * 2.0);
   float2 quad_pix = half_pix * INVSQR2;

   Fgnd += tex2D (s_Key_Vid, xy1 + float2 (half_pix.x, 0.0));
   Fgnd += tex2D (s_Key_Vid, xy1 - float2 (half_pix.x, 0.0));
   Fgnd += tex2D (s_Key_Vid, xy1 + quad_pix);
   Fgnd += tex2D (s_Key_Vid, xy1 - quad_pix);
   half_pix.x = 0.0;
   quad_pix.x = -quad_pix.x;
   Fgnd += tex2D (s_Key_Vid, xy1 + half_pix);
   Fgnd += tex2D (s_Key_Vid, xy1 - half_pix);
   Fgnd += tex2D (s_Key_Vid, xy1 + quad_pix);
   Fgnd += tex2D (s_Key_Vid, xy1 - quad_pix);

   Fgnd /= 9.0;

   if (K_alpha) { retval.a = Fgnd.a; }
   else {
      float keyMin = max (0.0, K_clip - K_range);
      float keyMax = min (1.0, K_clip + K_range);

      retval.a = smoothstep (keyMin, keyMax, (Fgnd.r + Fgnd.g + Fgnd.b) / 3.0);
   }

   if (K_invert) retval.a = 1.0 - retval.a;

   return retval;
}

float4 ps_border_A (float2 uv : TEXCOORD1) : COLOR
{
   if (B_amount <= 0.0) return tex2D (s_Foreground, uv);

   float2 offset, xy = uv;
   float2 edge = float2 (1.0, _OutputAspectRatio) * B_width * X_SCALE;

   float alpha = tex2D (s_Foreground, xy).a;

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

   float2 offset, xy = uv;
   float2 edge = float2 (1.0, _OutputAspectRatio) * B_width * X_SCALE;

   float alpha = tex2D (s_Part_1, xy).a;

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

   float3 xyz = float3 (1.0, 0.0, _OutputAspectRatio) / _OutputWidth;

   float2 xy = xyz.xz * INVSQR2;

   float alpha = tex2D (s_Part_2, uv).a;

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

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 retval = tex2D (s_Part_1, xy1);

   float2 xy, scale = float2 (1.0, _OutputAspectRatio) * S_feather * X_SCALE;

   float alpha = retval.a;

   if ((S_amount > 0.0) && (S_feather > 0.0)) {
      for (int i = 0; i < 6; i++) {
         xy = scale * _rot_1 [i];

         alpha += tex2D (s_Part_1, xy1 + xy).a;
         alpha += tex2D (s_Part_1, xy1 - xy).a;

         xy.y = -xy.y;

         alpha += tex2D (s_Part_1, xy1 + xy).a;
         alpha += tex2D (s_Part_1, xy1 - xy).a;
      }

   alpha /= 25.0;
   }

   alpha *= S_amount;

   retval = tex2D (s_Border, xy1);
   alpha  = max (alpha, retval.a);
   retval = lerp (S_colour, retval, retval.a);

   float4 Bgnd = (K_fill == 1) ? tex2D (s_Video_2, xy2) : tex2D (s_Video_1, xy1);

   retval = lerp (Bgnd, retval, alpha * Amount);

   return float4 (retval.rgb, Bgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique LumakeyAndMatte
{
   pass P_1
   < string Script = "RenderColorTarget0 = KeyFgd;"; >
   { PixelShader = compile PROFILE ps_key_gen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Part_1;"; >
   { PixelShader = compile PROFILE ps_border_A (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Part_2;"; >
   { PixelShader = compile PROFILE ps_border_B (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_border_C (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Part_1;"; >
   { PixelShader = compile PROFILE ps_shadow (); }

   pass P_6
   { PixelShader = compile PROFILE ps_main (); }
}
