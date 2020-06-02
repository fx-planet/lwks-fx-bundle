// @Maintainer jwrl
// @Released 2020-06-02
// @Author jwrl
// @OriginalAuthor "Robert Schütze"
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Fractals_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Fractal.mp4

/**
 This effect uses a fractal-like pattern to transition into or out of the delta key.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fractals_Adx.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Schütze (trirop) 07.12.2015.
//
// Modified jwrl 201-12-23
// Reformatted the effect description for markup purposes.
//
// Modified jwrl 2020-06-02
// Added support for unfolded effects.
// Reworded transition mode to read "Transition position".
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal dissolve (delta)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Separates foreground from background then uses a fractal-like pattern to transition into or out it";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;
texture Frctl : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state { Texture = <Title>; };

sampler s_Fractal = sampler_state
{
   Texture   = <Frctl>;
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

float fractalOffset
<
   string Group = "Fractal";
   string Description = "Offset";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Rate
<
   string Group = "Fractal";
   string Description = "Rate";   
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Border
<
   string Group = "Fractal";
   string Description = "Edge size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

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

#define FEATHER 0.1

float _OutputAspectRatio;
float _Progress;

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

float4 ps_fractal (float2 xy : TEXCOORD0) : COLOR
{
   float progress = (_Progress + 3.0) / 4.0;
   float speed = progress * Rate * 0.5;

   float3 fractal = float3 (xy.x / _OutputAspectRatio, xy.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - float3 (1.0, 1.0, speed))));
   }

   return float4 (fractal, 1.0);
}

float4 ps_main_I (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Ovly = tex2D (s_Fractal, xy0);
   float4 Fgnd = tex2D (s_Title, xy1);
   float4 Bgnd = Ftype ? tex2D (s_Foreground, xy2) : tex2D (s_Background, xy2);

   float amount  = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + FEATHER)) return Bgnd;

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / FEATHER;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Fgnd : lerp (Fgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Bgnd, fracAmt); }

   return lerp (Bgnd, retval, Fgnd.a);
}

float4 ps_main_O (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Ovly = tex2D (s_Fractal, xy0);
   float4 Fgnd = tex2D (s_Title, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

   float amount = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + FEATHER)) return tex2D (s_Foreground, xy1);

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / FEATHER;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Bgnd : lerp (Bgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Fgnd, fracAmt); }

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Adx_Fractals_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Frctl;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Adx_Fractals_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Frctl;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}
