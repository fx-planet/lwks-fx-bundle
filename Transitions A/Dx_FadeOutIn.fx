// @Maintainer jwrl
// @Released 2018-04-29
// @Author jwrl
// @Created 2016-08-29
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FadeOutIn_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_FadeOutIn.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Dx_FadeOutIn.fx
//
// This is a really dumb effect, because it does exactly what the dissolve does under
// another name.  I built it way back because there have always been "where's the fade
// to or from black effect" questions.  Now when there's one of those you can say "yes,
// and here it is".
//
// But boy is it dumb!
//
// A few things to note:  because this is really a dissolve it requires two inputs, even
// if it's just doing a fade out or in.  Second, there are the same overlap requirements
// that a standard dissolve needs.  Third, the black that it uses is true black.  This
// means that it is opaque, which will impact on its use with blend effects.
//
// As I said, boy, is it DUMB!!!  I can see absolutely no advantage in using it.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fade to or from black";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Outgoing = sampler_state { Texture = <Fg>; };
sampler s_Incoming = sampler_state { Texture = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Select fade type";
   string Enum = "Fade from black,Fade to black,Fade out/in"; 
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLACK   float2(0.0,1.0).xxxy

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fade_in (float2 uv : TEXCOORD1) : COLOR
{
   return lerp (BLACK, tex2D (s_Incoming, uv), Amount);
}

float4 ps_fade_out (float2 uv : TEXCOORD1) : COLOR
{
   return lerp (tex2D (s_Outgoing, uv), BLACK, Amount);
}

float4 ps_fade_out_in (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float fadeOut = (Amount * 2.0);
   float fadeIn  = max (0.0, fadeOut - 1.0);

   float4 retval = lerp (tex2D (s_Outgoing, xy1), BLACK, min (1.0, fadeOut));

   return lerp (retval, tex2D (s_Incoming, xy2), fadeIn);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FadeOutIn_0
{
   pass P_1 { PixelShader = compile PROFILE ps_fade_in (); }
}

technique FadeOutIn_1
{
   pass P_1 { PixelShader = compile PROFILE ps_fade_out (); }
}

technique FadeOutIn_2
{
   pass P_1 { PixelShader = compile PROFILE ps_fade_out_in (); }
}

