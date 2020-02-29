// @Maintainer jwrl
// @Released 2020-02-29
// @Author jwrl
// @Created 2020-02-29
// @see https://www.lwks.com/media/kunena/attachments/6375/AutoMask_640.png

/**
 This is a very simple masking tool which can be applied over an existing title to
 generate a mask from the difference between the background and foreground video.
 The generated mask is output in the alpha channel for possible downstream use.

 Depending on the amount of the difference the result may not always be as clean as
 one would wish.  If that is the case you should explore using BooleanBlendPlus.fx.
 It may require some manual routing but it will generate a clean mask where this
 effect may not.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AutoMask.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Auto mask";
   string Category    = "Mix";
   string SubCategory = "Simple tools";
   string Notes       = "Masks the background using the foreground layer.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state { Texture = <Fg>; };
sampler BgSampler = sampler_state { Texture = <Bg>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float MaskGain
<
   string Description = "Mask adjust";
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

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = tex2D (FgSampler, xy1);
   float4 Bgnd = tex2D (BgSampler, xy2);

   float kDiff = distance (Fgnd.g, Bgnd.g);

   kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
   kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));
   kDiff = smoothstep (0.0, MaskGain, kDiff);

   Fgnd = Bgnd * kDiff * Amount;

   return lerp (Bgnd, Fgnd, Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique AutoMask { pass P_1 { PixelShader = compile PROFILE ps_main (); } }

