// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2020-01-04
// @see https://www.lwks.com/media/kunena/attachments/6375/KeyOutBlack_640.png

/**
 This effect is designed to turn on the foreground alpha layer wherever black is at absolute
 zero.  To soften the key edge a non-linear curve is derived from the bottom 0% to 2.5% of
 the video.  That is then combined with any alpha channel in the foreground layer and used
 to key it over the background.  The range over which the key is generated can be offset by
 up to 5% of the total video level to compensate for noise in blacks.

 While you can exceed the 5% limit by manually entering values, if you need more control over
 your key level there are better tools available.  A good start would be to try the Lightworks
 lumakey instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KeyOutBlack.fx
//
// The theory behind this effect:
//
// First we crush the black level by up to 5% and get the maximum of the red, green and
// blue channels from the result.  We then derive the initial alpha channel from that
// maximum value, using the bottom 2.5% of the black crushed video.  The cosine of the
// preliminary alpha is used to smooth the clipping with an S curve.
//
// That synthetic alpha is then combined with the foreground video alpha to produce a
// composite alpha channel, which preserves any existing foreground transparency.  Finally,
// the derived alpha channel is used to key the foreground over the background video.  The
// opacity parameter allows for dissolving the foreground in or out.
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 2020-06-15 jwrl:
// Changed "Black offset" in Offset parameter to read "Black clip".
// Added DisplayAsPercentage flag to the Offset parameter.
// Changed Offset range to run from 0.0 to 0.05 (5%).
// Changed Offset default value to 0.025 (2.5%).
// In the shader, changed the black range used to generate alpha from 3.125% to 2.5%.
// Changed alpha curve generation from inverse parabolic to trigonometric S-curve.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Key out black";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "This generates keys from absolute (super) black";
   bool CanSize       = true;
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

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Offset
<
   string Description = "Black clip";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.05;
> = 0.025;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy1);

   float3 v = saturate (Fgd.rgb - Offset.xxx);

   float alpha = (1.0 - cos (saturate (max (v.r, max (v.g, v.b)) * 40.0) * PI)) * 0.5;

   return lerp (tex2D (s_Background, xy2), Fgd, min (alpha, Fgd.a) * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique KeyOutBlack
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
