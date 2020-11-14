// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2020-07-15
// @see https://www.lwks.com/media/kunena/attachments/6375/VisualMatte_640.png

/**
 This just a simple crop and matte effect engineered so that it can be set visually by
 dragging on-screen pins.  There is no bordering or feathering of the edges and the
 background matte is just a plain flat colour.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualMatte.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual matte";
   string Category    = "DVE";
   string SubCategory = "Simple visual tools";
   string Notes       = "A simple crop tool that can be set up visually over a flat colour background.";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input = sampler_state { Texture   = <Inp>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float4 Colour
<
   string Group = "Background";
   string Description = "Colour";
   bool SupportsAlpha = true;
> = { 0.15, 0.12, 0.75, 1.0 };

float CropLeft
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = 0.1;
   float MaxVal = 0.9;
> = 0.1;

float CropTop
<
   string Group = "Crop";
   string Description = "Top left";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = 0.1;
   float MaxVal = 0.9;
> = 0.9;

float CropRight
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = 0.1;
   float MaxVal = 0.9;
> = 0.9;

float CropBottom
<
   string Group = "Crop";
   string Description = "Bottom right";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = 0.1;
   float MaxVal = 0.9;
> = 0.1;

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 xy1 = saturate (float2 (CropLeft - 0.1, 0.9 - CropTop) * 1.25);
   float2 xy2 = saturate (float2 (CropRight - 0.1, 0.9 - CropBottom) * 1.25);

   if ((uv.x < xy1.x) || (uv.x > xy2.x) || (uv.y < xy1.y) || (uv.y > xy2.y)) return Colour;

   return tex2D (s_Input, uv);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique VisualMatte
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
