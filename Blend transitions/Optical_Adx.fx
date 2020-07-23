// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Optical_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Optical.mp4

/**
 A transition that simulates the burn effect of the classic film optical.  Titles or any
 other keyed components are separated from the background with a delta key before executing
 the transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Optical_Adx.fx
//
// Version history:
//
// Modified jwrl 2020-07-23
// Rolled fold/unfold into transition position.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//
// Modified jwrl 2018-12-28
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Optical dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then simulates the burn effect of the classic film optical title";
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
   string Description = "Transition position";
   string Enum = "At start of clip,At end of clip,At start (unfolded)";
> = 0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268

#define EMPTY   0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_F (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float alpha = distance (Fgnd.g, Bgnd.g);

   alpha  = max (alpha, distance (Fgnd.r, Bgnd.r));
   alpha  = max (alpha, distance (Fgnd.b, Bgnd.b));
   alpha  = smoothstep (0.0, KeyGain, alpha);
   alpha *= sin (Amount * HALF_PI) * 1.5;
   Bgnd   = lerp (Fgnd, Bgnd, Bgnd.a);
   Fgnd   = max (EMPTY, Fgnd - alpha.xxxx);

   return lerp (Fgnd, Bgnd, Amount);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float amount = 1.0 - Amount;
   float alpha = distance (Bgnd.g, Fgnd.g);

   alpha  = max (alpha, distance (Bgnd.r, Fgnd.r));
   alpha  = max (alpha, distance (Bgnd.b, Fgnd.b));
   alpha  = smoothstep (0.0, KeyGain, alpha);
   alpha *= sin (amount * HALF_PI) * 1.5;
   Fgnd   = lerp (Bgnd, Fgnd, Fgnd.a);
   Bgnd   = max (EMPTY, Bgnd - alpha.xxxx);

   return lerp (Bgnd, Fgnd, amount);
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float alpha = distance (Bgnd.g, Fgnd.g);

   alpha  = max (alpha, distance (Bgnd.r, Fgnd.r));
   alpha  = max (alpha, distance (Bgnd.b, Fgnd.b));
   alpha  = smoothstep (0.0, KeyGain, alpha);
   alpha *= sin (Amount * HALF_PI) * 1.5;
   Fgnd   = lerp (Bgnd, Fgnd, Fgnd.a);
   Bgnd   = max (EMPTY, Bgnd - alpha.xxxx);

   return lerp (Bgnd, Fgnd, Amount);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Optical_Adx_F
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique Optical_Adx_O
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique Optical_Adx_I
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_I (); }
}
