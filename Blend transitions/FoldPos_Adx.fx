// @Maintainer jwrl
// @Released 2020-07-23
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldPos_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_FoldPos.mp4

/**
 This effect uses a delta (difference) key to separate the foreground from background then
 transitions by adding the foreground to the background.  The overflowed result is then
 folded back into the legal video range and matted into the background by the delta key.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FoldPos_Adx.fx
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
   string Description = "Folded pos dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Blend transitions";
   string Notes       = "Separates foreground from background then dissolves them through a positive mix";
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
   float4 retval = WHITE - abs (WHITE - Bgnd - Fgnd);
   float4 Title = Bgnd;

   float kDiff = distance (Bgnd.g, Fgnd.g);

   kDiff = max (kDiff, distance (Bgnd.r, Fgnd.r));
   kDiff = max (kDiff, distance (Bgnd.b, Fgnd.b));

   Title.a = smoothstep (0.0, KeyGain, kDiff);

   float amount = (1.0 - Amount) * 2.0;
   float amt1 = min (amount, 1.0);
   float amt2 = max (amount - 1.0, 0.0);

   retval = lerp (Bgnd, retval, amt1);
   Title.a = Title.a > 0.0 ? lerp (1.0, Title.a, amount) : 0.0;

   return lerp (Fgnd, lerp (retval, Fgnd, amt2), Title.a);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 retval = WHITE - abs (WHITE - Fgnd - Bgnd);
   float4 Title = Fgnd;

   float kDiff = distance (Bgnd.g, Fgnd.g);

   kDiff = max (kDiff, distance (Bgnd.r, Fgnd.r));
   kDiff = max (kDiff, distance (Bgnd.b, Fgnd.b));

   Title.a = smoothstep (0.0, KeyGain, kDiff);

   float amount = Amount * 2.0;
   float amt1 = min (amount, 1.0);
   float amt2 = max (amount - 1.0, 0.0);

   retval = lerp (Fgnd, retval, amt1);
   Title.a = Title.a > 0.0 ? lerp (1.0, Title.a, amount) : 0.0;

   return lerp (Bgnd, lerp (retval, Bgnd, amt2), Title.a);
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Foreground, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 retval = WHITE - abs (WHITE - Fgnd - Bgnd);
   float4 Title = Fgnd;

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

   Title.a = smoothstep (0.0, KeyGain, kDiff);

   float amount = (1.0 - Amount) * 2.0;
   float amt1 = min (amount, 1.0);
   float amt2 = max (amount - 1.0, 0.0);

   retval = lerp (Fgnd, retval, amt1);
   Title.a = Title.a > 0.0 ? lerp (1.0, Title.a, amount) : 0.0;

   return lerp (Bgnd, lerp (retval, Bgnd, amt2), Title.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique FoldPos_Adx_F
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_F (); }
}

technique FoldPos_Adx_O
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_O (); }
}

technique FoldPos_Adx_I
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_I (); }
}
