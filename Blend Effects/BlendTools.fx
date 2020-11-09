// @Maintainer jwrl
// @Released 2020-11-08
// @Author jwrl
// @Created 2018-07-02
// @see https://www.lwks.com/media/kunena/attachments/6375/Blend_Tools_640.png

/**
 Blend tools is an effect that is designed to help if the alpha channel may not be quite
 as required or to generate alpha from absolute black.  The alpha channel may be inverted,
 gamma, gain, contrast and brightness can be adjusted, and the alpha channel may also be
 feathered.  Feathering only works within the existing alpha boundaries and is based on
 the algorithm used in the "Super blur" effect.

 As well as the alpha adjustments the video may be unpremultiplied, and transparency and
 opacity may be adjusted.  Those last two behave in different ways: "Transparency" adjusts
 the key channel background transparency, and "Opacity" is a standard key opacity control.
 The unpremultiply settings when used with the key from black modes will only be applied
 after level adjustment regardless of the actual point selected.  It's impossible to do it
 before because there is no alpha channel available at that stage.

 The effect has been placed in the "Mix" category because it's felt to be closer to the
 blend effect supplied with Lightworks than it is to any of the key effects.  That said,
 it is possible to export just the foreground with the processed alpha.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlendTools.fx
//
// Version history:
//
// Update 2020-11-08 jwrl.
// Added CanSize switch for 2021 support.
//
// Modified 2020-07-25 jwrl.
// Added the ability to unpremultiply after feathering.
//
// Modified 2 August 2019 jwrl.
// Added the ability to generate the alpha channel from luminance.
// Added the ability to export just the foreground with the processed alpha.
//
// Modified 23 December 2018 jwrl.
// Renamed effect from "Key tools" to "Blend tools".
// Changed subcategory to "Blend Effects".
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Blend tools";
   string Category    = "Mix";
   string SubCategory = "Blend Effects";
   string Notes       = "Provides a wide range of blend and key adjustments including generation of alpha from black";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Key : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Key = sampler_state
{
   Texture   = <Key>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int KeyMode
<
   string Description = "Key mode";
   string Enum = "Standard key,Inverted key,Key from black,Inverted black key";
> = 0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int a_Premul
<
   string Group = "Alpha fine tuning";
   string Description = "Unpremultiply";
   string Enum = "None,Before level adjustment,After level adjustment,After feathering";
> = 0;

float a_Amount
<
   string Group = "Alpha fine tuning";
   string Description = "Transparency";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float a_Gamma
<
   string Group = "Alpha fine tuning";
   string Description = "Alpha gamma";
   float MinVal = 0.1;
   float MaxVal = 4.0;
> = 1.00;

float a_Contrast
<
   string Group = "Alpha fine tuning";
   string Description = "Alpha contrast";
   float MinVal = 0.0;
   float MaxVal = 5.0;
> = 1.0;

float a_Bright
<
   string Group = "Alpha fine tuning";
   string Description = "Alpha brightness";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float a_Gain
<
   string Group = "Alpha fine tuning";
   string Description = "Alpha gain";
   float MinVal = 0.0;
   float MaxVal = 4.0;
> = 1.0;

float a_Feather
<
   string Group = "Alpha fine tuning";
   string Description = "Alpha feather";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

int a_Mode
<
   string Description = "Output mode";
   string Enum = "Blend foreground over background,Export foreground with alpha,Show alpha channel";
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define LOOP   12
#define DIVIDE 49

#define RADIUS 0.00125
#define ANGLE  0.2617993878

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, uv);
   float4 K = (pow (Fgd, 1.0 / a_Gamma) * a_Gain) + a_Bright.xxxx;

   int unpremul = a_Premul;

   K.a -= 0.5;
   K   *= a_Contrast;

   if (KeyMode > 1) {
      K.a = saturate ((K.r + K.g + K.b) * 2.0);

      if (unpremul == 1) unpremul++;
   }
   else K.a += 0.5;

   if (unpremul == 1) Fgd.rgb /= Fgd.a;

   Fgd.a = ((KeyMode == 0) || (KeyMode == 2)) ? K.a : 1.0 - K.a;
   Fgd.a = saturate (lerp (1.0, Fgd.a, a_Amount));

   if (unpremul == 2) Fgd.rgb /= Fgd.a;

   return Fgd;
}

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 Fgd = tex2D (s_Key, uv);

   float alpha = Fgd.a;

   if (a_Feather > 0.0) {
      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * a_Feather * RADIUS;

      float angle = 0.0;

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         alpha += tex2D (s_Key, uv + xy).a;
         alpha += tex2D (s_Key, uv - xy).a;
         xy += xy;
         alpha += tex2D (s_Key, uv + xy).a;
         alpha += tex2D (s_Key, uv - xy).a;
         angle += ANGLE;
      }

      alpha *= (1.0 + a_Feather) / DIVIDE;
      alpha -= a_Feather;

      alpha = min (saturate (alpha), Fgd.a);
   }

   if (a_Premul == 3) Fgd.rgb /= alpha;

   Fgd.a = alpha * Opacity;

   if (a_Mode == 1) return Fgd;

   if (a_Mode == 2) return float4 (Fgd.aaa, 1.0);

   return float4 (lerp (tex2D (s_Background, uv), Fgd, Fgd.a).rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique BlendTools
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main (); }
}
