// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Scurve-640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Scurve.mp4

/**
This is essentially the same as the S dissolve but extended to dissolve delta keys.
A trigonometric curve is applied to the "Amount" parameter and the linearity of the
curve can be adjusted.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Sdissolve_Adx.fx
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "S dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then dissolves it with a non-linear profile";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition mode";
   string Enum = "Delta key in,Delta key out";
> = 0;

float Linearity
<
   string Description = "Linearity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.1415926536

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Bgnd = tex2D (s_Foreground, xy1);
   float4 Fgnd = tex2D (s_Background, xy2);

   float kDiff = distance (Bgnd.g, Fgnd.g);

   kDiff = max (kDiff, distance (Bgnd.r, Fgnd.r));
   kDiff = max (kDiff, distance (Bgnd.b, Fgnd.b));

   Fgnd.a = smoothstep (0.0, KeyGain, kDiff);

   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   amount = saturate (amount + (curve * Linearity));

   return lerp (Bgnd, Fgnd, Fgnd.a * amount);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float kDiff = distance (Bgnd.g, Fgnd.g);

   kDiff = max (kDiff, distance (Bgnd.r, Fgnd.r));
   kDiff = max (kDiff, distance (Bgnd.b, Fgnd.b));

   Fgnd.a = smoothstep (0.0, KeyGain, kDiff);

   float amount = (1.0 - sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;
   float curve  = Amount - amount;

   amount = 1.0 - saturate (amount + (curve * Linearity));

   return lerp (Bgnd, Fgnd, Fgnd.a * amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Sdissolve_Adx_I
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Sdissolve_Adx_O
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}

