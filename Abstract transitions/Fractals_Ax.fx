// @Maintainer jwrl
// @Released 2020-07-22
// @Author jwrl
// @OriginalAuthor "Robert Schütze"
// @Created 2018-06-11
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Fractals_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Fractal.mp4

/**
 This effect uses a fractal-like pattern to transition into or out of a title.  It also
 composites the result over a background layer.  Alpha levels are boosted to support
 Lightworks titles, which is the default setting.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fractals_Ax.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Schütze (trirop) 07.12.2015.
//
// This is a revision of an earlier effect, Adx_Fractals.fx, which also had the ability
// to wipe between two titles.  That added needless complexity, when the same result
// can be obtained by overlaying two effects.
//
// Version history:
//
// Modified jwrl 2020-07-22
// Reworded transition mode to read "Transition position".
// Reworded Boost text to match requirements for 2020.1 and up.
// Implemented Boost as a separate pass ahead of the main code.
// Removed fn_tex2D(), which is now redundant.
//
// Modified 23 December 2018 jwrl.
// Changed effect name.
// Changed subcategory.
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fractal dissolve (alpha)";
   string Category    = "Mix";
   string SubCategory = "Abstract transitions";
   string Notes       = "Uses a fractal-like pattern to transition into or out of a title";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

texture Key : RenderColorTarget;
texture Frc : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Sup>; };
sampler s_Background = sampler_state { Texture = <Vid>; };

sampler s_Key = sampler_state
{
   Texture   = <Key>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Fractal = sampler_state {
   Texture   = <Frc>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "Lightworks effects: Disconnect the input and select";
   string Enum = "Crawl/Roll/Title/Image key,Video/External image";
> = 0;

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
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Rate
<
   string Group = "Fractal";
   string Description = "Rate";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Border
<
   string Group = "Fractal";
   string Description = "Edge size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define FEATHER 0.1

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Foreground, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
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
   float4 Fgnd = tex2D (s_Key, xy1);
   float4 Bgnd = tex2D (s_Background, xy2);

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
   float4 Fgnd = tex2D (s_Key, xy1);
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

technique Ax_Fractals_in
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Frc;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_I (); }
}

technique Ax_Fractals_out
{
   pass P_1
   < string Script = "RenderColorTarget0 = Key;"; >
   { PixelShader = compile PROFILE ps_keygen (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Frc;"; >
   { PixelShader = compile PROFILE ps_fractal (); }

   pass P_3
   { PixelShader = compile PROFILE ps_main_O (); }
}
