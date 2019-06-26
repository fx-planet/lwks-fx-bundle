// @Maintainer jwrl
// @Released 2018-12-23
// @Author jwrl
// @Created 2018-01-20
// @see https://www.lwks.com/media/kunena/attachments/6375/SimpleMatte_640.png

/**
This just a simple crop and matte effect.  There is no bordering or feathering of the
edges and the background matte is just a plain flat colour.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Simple_matte.fx
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 29 August 2018 jwrl.
// Added notes to header.
//
// Modified 23 December 2018 jwrl.
// Changed subcategory.
// Formatted the descriptive block so that it can automatically be read.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple matte";
   string Category    = "DVE";
   string SubCategory = "Border and crop";
   string Notes       = "A simple crop tool with flat colour matte background.";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fgd;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state { Texture   = <Fgd>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float CropLeft
<
   string Description = "Top left";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float CropTop
<
   string Description = "Top left";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float CropRight
<
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.9;

float CropBottom
<
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.1;

float4 Colour
<
   string Group = "Background";
   string Description = "Colour";
> = { 0.15, 0.12, 0.75, 1.0 };

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float y = 1.0 - uv.y;

   if ((uv.x > CropLeft) && (uv.x < CropRight) && (y < CropTop) && (y > CropBottom)) {
      return tex2D (FgSampler, uv);
   }

   return Colour;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique crop
{
   pass Simple_matte
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
