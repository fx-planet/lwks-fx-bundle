// @Maintainer jwrl
// @Released 2020-01-04
// @Author jwrl
// @Created 2020-01-04
// @see https://www.lwks.com/media/kunena/attachments/6375/KeyOutBlack_640.png

/**
 This effect is designed to turn on the foreground alpha layer wherever black is at absolute
 zero.  To soften the key edge an inverse parabolic curve is derived from 0% to 12.5% video.
 That is then combined with any alpha channel in the foreground layer and used to key it over
 the background.  The range over which the key is generated can be offset by up to 4% of the
 total video level to compensate for noise in blacks.

 While you can exceed the 4% limit by manually entering values, if you need full control over
 your key level there are better tools available.  A good start would be to try the Lightworks
 lumakey instead.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KeyOutBlack.fx
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Key out black";
   string Category    = "Key";
   string SubCategory = "Simple tools";
   string Notes       = "This generates keys from absolute (super) black";
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
   string Description = "Black offset";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define OFFSET 0.04  // This gives us a 4% black offset to correct for any noise.

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   // Recover the foreground into Fgd.

   float4 Fgd = tex2D (s_Foreground, xy1);

   // Offset the black level by up to 4% and store the RGB components in rgb.

   float3 rgb = saturate (Fgd.rgb - (Offset * OFFSET).xxx);

   // Combine red, green and blue then derive the alpha channel from the combination.
   // This is further combined with the foreground alpha to produce the final result,
   // protecting any transparency already present in the foreground.

   float range = max (rgb.r, max (rgb.g, rgb.b));
   float alpha = min (pow (saturate (range * 32.0), 0.5), Fgd.a);

   // Finally, use the alpha to key the foreground over the background.  The opacity
   // parameter allows for fading of the foreground.

   return lerp (tex2D (s_Background, xy2), Fgd, alpha * Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique KeyOutBlack
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
