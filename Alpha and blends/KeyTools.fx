// @Maintainer jwrl
// @Released 2018-07-03
// @Author jwrl
// @Created 2018-07-02
// @see https://www.lwks.com/media/kunena/attachments/6375/KeyTools_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect KeyTools.fx
//
// This effect is predominantly a combination of two earlier effects, "Adjustable blend"
// and "Alpha adjust", both of which have now been withdrawn.  The feathering section is
// taken from the "Super blur" effect.
//
// It is designed to help when the alpha channel may not be quite as required.  Alpha
// may be inverted or scaled, gamma, gain, contrast and brightness can be adjusted, and
// the alpha channel may also be feathered.  Feathering only works within the existing
// alpha boundaries.
//
// As well as the alpha adjustments the video may be premultiplied, and transparency
// and opacity may be adjusted.  Those last two behave in different ways: "Transparency"
// adjusts the key channel background transparency, while "Opacity" is a standard key
// opacity adjustment.
//
// It has been placed in the "Mix" category because it's felt to be closer to the blend
// effect supplied with Lightworks than it is to any of the key effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Key tools";
   string Category    = "Mix";
   string SubCategory = "User Effects";
   string Notes       = "Provides a wide range of blend and key adjustments";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state { Texture = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool Invert
<
   string Description = "Invert alpha";
> = false;

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
   string Enum = "None,Before level adjustment,After level adjustment"; 
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

bool a_Show
<
   string Description = "Show alpha channel";
> = false;

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

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy1);
   float3 Bgd = tex2D (s_Background, xy2);

   float alpha, beta = Invert ? 1.0 - Fgd.a : Fgd.a;

   if (a_Premul == 1) Fgd.rgb /= beta;

   alpha = ((((pow (beta, 1.0 / a_Gamma) * a_Gain) + a_Bright) - 0.5) * a_Contrast) + 0.5;
   beta  = alpha;
   alpha = saturate (lerp (1.0, beta, a_Amount));

   if (a_Premul == 2) Fgd.rgb /= alpha;

   if (a_Feather > 0.0) {
      float2 uv, radius = float2 (1.0, _OutputAspectRatio) * a_Feather * RADIUS;

      float angle = 0.0;

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, uv.x, uv.y);
         uv *= radius;
         alpha += tex2D (s_Foreground, xy1 + uv).a;
         alpha += tex2D (s_Foreground, xy1 - uv).a;
         uv += uv;
         alpha += tex2D (s_Foreground, xy1 + uv).a;
         alpha += tex2D (s_Foreground, xy1 - uv).a;
         angle += ANGLE;
      }

      alpha *= (1.0 + a_Feather) / DIVIDE;
      alpha -= a_Feather;

      alpha = min (saturate (alpha), beta);
   }

   if (a_Show) return alpha.xxxx;

   return float4 (lerp (Bgd, Fgd.rgb, alpha * Opacity), Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique KeyTools
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}

