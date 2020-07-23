// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Non_Add_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Non_Add.mp4

/**
 This effect emulates the classic analog vision mixer non-add dissolve.  It uses an
 algorithm that mimics reasonably closely what the electronics used to do.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAdd_Adx.fx
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
// Modified jwrl 2018-12-23
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-additive mix (delta)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then emulates the classic analog vision mixer non-add dissolve";
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

#define EMPTY 0.0.xxxx

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
   alpha *= (1.0 - abs (Amount - 0.5)) * 2.0;

   Bgnd = lerp (EMPTY, Bgnd, Amount);
   Bgnd = max (lerp (Fgnd, EMPTY, Amount), Bgnd);

   return lerp (Fgnd, Bgnd, alpha);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float alpha = distance (Bgnd.g, Fgnd.g);

   alpha = max (alpha, distance (Bgnd.r, Fgnd.r));
   alpha = max (alpha, distance (Bgnd.b, Fgnd.b));
   alpha = smoothstep (0.0, KeyGain, alpha);
   alpha *= (1.0 - abs (0.5 - Amount)) * 2.0;

   Fgnd = lerp (Fgnd, EMPTY, Amount);
   Fgnd = max (lerp (EMPTY, Bgnd, Amount), Fgnd);

   return lerp (Bgnd, Fgnd, alpha);
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float alpha = distance (Bgnd.g, Fgnd.g);

   alpha  = max (alpha, distance (Bgnd.r, Fgnd.r));
   alpha  = max (alpha, distance (Bgnd.b, Fgnd.b));
   alpha  = smoothstep (0.0, KeyGain, alpha);
   alpha *= (1.0 - abs (Amount - 0.5)) * 2.0;

   Fgnd = lerp (EMPTY, Fgnd, Amount);
   Fgnd = max (lerp (Bgnd, EMPTY, Amount), Fgnd);

   return lerp (Bgnd, Fgnd, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique NonAdd_Adx_F
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique NonAdd_Adx_O
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique NonAdd_Adx_I
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_I (); }
}
