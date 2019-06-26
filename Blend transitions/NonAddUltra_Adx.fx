// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_NonAddUltra_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_NonAddUltra.mp4

/**
This is an extreme non-additive mix for delta (difference) keys.  The incoming key is
faded in to full value at the 50% point, at which stage the background video starts
to fade out.  The two images are mixed by giving the source with the maximum level
priority.  The dissolve out is the reverse of that

The result is extreme, but can be interesting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NonAddUltra_Adx.fx
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-add mix ultra (delta)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "This is an extreme non-additive mix for titles, which are delta keyed from the background";
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
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Background, xy1);
   float4 Bgnd = tex2D (s_Foreground, xy2);

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);
   float temp = outAmount * outAmount * outAmount;
   float alpha = distance (Bgnd.g, Fgnd.g);

   alpha  = max (alpha, distance (Bgnd.r, Fgnd.r));
   alpha  = max (alpha, distance (Bgnd.b, Fgnd.b));
   alpha  = smoothstep (0.0, KeyGain, alpha);

   outAmount = lerp (outAmount, temp, Linearity);
   temp = in_Amount * in_Amount * in_Amount;
   in_Amount = lerp (in_Amount, temp, Linearity);

   Fgnd = max (Fgnd * outAmount, Bgnd * in_Amount);

   return lerp (Bgnd, Fgnd, alpha);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float outAmount = min (1.0, Amount * 2.0);
   float in_Amount = min (1.0, (1.0 - Amount) * 2.0);
   float temp = outAmount * outAmount * outAmount;
   float alpha = distance (Bgnd.g, Fgnd.g);

   alpha = max (alpha, distance (Bgnd.r, Fgnd.r));
   alpha = max (alpha, distance (Bgnd.b, Fgnd.b));
   alpha = smoothstep (0.0, KeyGain, alpha);

   outAmount = lerp (outAmount, temp, Linearity);
   temp    = in_Amount * in_Amount * in_Amount;
   in_Amount = lerp (in_Amount, temp, Linearity);

   Fgnd = max (Bgnd * outAmount, Fgnd * in_Amount);

   return lerp (Bgnd, Fgnd, alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Adx_NonAddUltra_I
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_NonAddUltra_O
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}

