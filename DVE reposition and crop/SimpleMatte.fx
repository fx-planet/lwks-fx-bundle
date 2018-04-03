// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect SimpleMatte.fx
//
// Created by LW user jwrl 20 January 2018.
// @Author jwrl
// @Created "20 January 2018"
//
// Just a simple crop and matte effect.  There is no bordering
// or feathering of the edges and the background matte is just
// a plain flat colour.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Simple matte";
   string Category    = "DVE";
   string SubCategory = "Crop Presets";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fgd;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state { Texture   = <Fgd>; };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Shader
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float y = 1.0 - uv.y;

   if ((uv.x > CropLeft) && (uv.x < CropRight) && (y < CropTop) && (y > CropBottom)) {
      return tex2D (FgSampler, uv);
   }

   return Colour;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique crop
{
   pass Simple_Matte
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
