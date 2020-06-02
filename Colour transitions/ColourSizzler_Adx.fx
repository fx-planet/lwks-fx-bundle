// @Maintainer jwrl
// @Released 2020-06-02
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sizzler_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Sizzler.mp4

/**
 This effect dissolves a delta key in or out through a complex colour translation while
 performing what is essentially a non-additive mix.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourSizzler_Adx.fx
//
// Modified jwrl 2018-12-23
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour sizzler (delta)";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Separates foreground from background then transitions in or out using a complex colour translation";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

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
   string Enum = "At start of clip,At end of clip";
> = 0;

float Saturation
<
   string Description = "Saturation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float HueCycle
<
   string Description = "Cycle rate";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

bool Ftype
<
   string Description = "Folded effect";
> = true;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SQRT_3  1.7320508076
#define TWO_PI  6.2831853072

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return Ftype ? float4 (Bgd, smoothstep (0.0, KeyGain, kDiff))
                : float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_main_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float amount = 1.0 - Amount;

   float4 Fgnd = tex2D (s_Title, xy1);
   float4 Bgnd = Ftype ? tex2D (s_Foreground, xy2) : tex2D (s_Background, xy2);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - amount)), Bgnd * min (1.0, 2.0 * amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

float4 ps_main_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (s_Title, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);
   float4 Svid = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 Temp = max (Svid * min (1.0, 2.0 * (1.0 - Amount)), Bgnd * min (1.0, 2.0 * Amount));

   Svid = max (Svid, Bgnd);

   float Luma  = 0.1 + (0.5 * Svid.x);
   float Satn  = Svid.y * Saturation;
   float Hue   = frac (Svid.z + (Amount * HueCycle));
   float HueX3 = 3.0 * Hue;

   Hue = SQRT_3 * tan ((Hue - ((floor (HueX3) + 0.5) / 3.0)) * TWO_PI);

   float Red   = (1.0 - Satn) * Luma;
   float Blue  = ((3.0 + Hue) * Luma - (1.0 + Hue) * Red) / 2.0;
   float Green = 3.0 * Luma - Blue - Red;

   Svid.rgb = (HueX3 < 1.0) ? float3 (Green, Blue, Red)
            : (HueX3 < 2.0) ? float3 (Red, Green, Blue)
                            : float3 (Blue, Red, Green);

   float mixval = abs (2.0 * (0.5 - Amount));

   mixval *= mixval;
   Temp    = lerp (Svid, Temp, mixval);
   Fgnd.a  = Fgnd.a > 0.0 ? lerp (1.0, Fgnd.a, Amount) : 0.0;

   return lerp (Bgnd, Temp, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_ColourSizzler_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_ColourSizzler_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_O (); }
}
