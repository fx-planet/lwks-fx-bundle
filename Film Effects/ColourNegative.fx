// @Maintainer jwrl
// @Released 2020-09-27
// @Author jwrl
// @Created 2016-05-14
// @see https://www.lwks.com/media/kunena/attachments/6375/FilmNeg_640.png

/**
 This simulates the look of 35 mm masked film negative.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourNegative.fx
//
// Version history:
//
// Update 2020-09-27 jwrl.
// Revised header block.
//
// Modified 23 December 2018 jwrl.
// Renamed effect from "Film negative".
// Changed subcategory.
// Amended the Notes to be more descriptive.
// Reformatted the effect description for markup purposes.
//
// Modified 27 September 2018 jwrl.
// Added notes to header.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Added subcategory for LW14 - jwrl 18 February 2017.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Colour negative";
   string Category    = "Colour";
   string SubCategory = "Film Effects";
   string Notes       = "Simulates the look of 35 mm colour film dye-masked negative";
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

technique ColourNegative
{
   pass P_1
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
