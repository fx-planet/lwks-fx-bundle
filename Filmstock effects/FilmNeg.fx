// @Maintainer jwrl
// @Released 2018-04-07
// @Author jwrl
// @Created 2016-05-14
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmNeg_1.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmNeg.fx
//
// This simulates the look of 35 mm masked film negative.
//
// Added subcategory for LW14 - jwrl 18 February 2017.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film negative";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state { Texture = <Input>; };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

   retval.rgb  = (float3 (2.0, 1.33, 1.0) - retval.rgb) / 2.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique filmneg
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
