// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect FilmNeg.fx
//
// Created by LW user jwrl 14 May 2016.
// @Author jwrl
// @CreationDate "14 May 2016"
//
// This simulates the look of 35 mm masked film negative.
//
// Added subcategory for LW14 - jwrl 18 February 2017.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Film negative";
   string Category    = "Colour";
   string SubCategory = "Preset Looks";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state { Texture = <Input>; };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

// Nothing to see here.  Move on please.

//--------------------------------------------------------------//
// Definitions and stuff
//--------------------------------------------------------------//

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (FgSampler, xy);

   retval.rgb  = (float3 (2.0, 1.33, 1.0) - retval.rgb) / 2.0;

   return retval;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique filmneg
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

