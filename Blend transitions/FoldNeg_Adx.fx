// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldNeg_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldNeg.mp4

/**
 This effect separates foreground from background then dissolves them through a negative
 mix of the two components.  The result is a sort of ghostly double transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FoldNeg_Adx.fx
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
   string Description = "Folded neg dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then dissolves them through a negative mix";
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

#define WHITE (1.0).xxxx

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_F (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float kDiff = distance (Bgnd.g, Fgnd.g);

   kDiff = max (kDiff, distance (Bgnd.r, Fgnd.r));
   kDiff = max (kDiff, distance (Bgnd.b, Fgnd.b));

   Bgnd.a = smoothstep (0.0, KeyGain, kDiff);

   float4 Mix  = lerp (Fgnd, Bgnd, Bgnd.a);
   float4 Neg  = float4 (WHITE - ((Mix + Fgnd) / 2.0));

   Neg      = lerp (Fgnd, Neg, Amount);
   Bgnd.rgb = lerp (Neg.rgb, Mix.rgb, Amount);
   Bgnd.a   = Bgnd.a > 0.0 ? lerp (Bgnd.a, 1.0, Amount) : 0.0;

   return lerp (Fgnd, Bgnd, Bgnd.a);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   Fgnd.a = smoothstep (0.0, KeyGain, kDiff);

   float4 Mix  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Neg  = float4 (WHITE - ((Mix + Bgnd) / 2.0));

   float amount = 1.0 - Amount;

   Neg      = lerp (Bgnd, Neg, amount);
   Fgnd.rgb = lerp (Neg.rgb, Mix.rgb, amount);
   Fgnd.a   = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   Fgnd.a = smoothstep (0.0, KeyGain, kDiff);

   float4 Mix  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Neg  = float4 (WHITE - ((Mix + Bgnd) / 2.0));

   Neg      = lerp (Bgnd, Neg, Amount);
   Fgnd.rgb = lerp (Neg.rgb, Mix.rgb, Amount);
   Fgnd.a   = Fgnd.a > 0.0 ? lerp (Fgnd.a, 1.0, Amount) : 0.0;

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FoldNeg_Adx_F
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique FoldNeg_Adx_O
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique FoldNeg_Adx_I
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_I (); }
}
