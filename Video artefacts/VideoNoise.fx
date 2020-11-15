// @Maintainer jwrl
// @Released 2020-11-15
// @Author windsturm
// @Created 2012-08-02
// @see https://www.lwks.com/media/kunena/attachments/6375/FxNoise_640.png

/**
 This does exactly what it says - generates both monochrome and colour video noise.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VideoNoise.fx (FxNoise)
//-----------------------------------------------------------------------------------------//

/*
  * FxNoise.
  * Noise effect.
  * 
  * @param <Color Type> "Monochrome" or "Color"
  * @param <Noise Size> Noise block size
  * @param <Opacity>    Degree to which blended with the image
  * @param <Alpha>      Alpha blending 
  * @param <Seed>       Random seed
  * @author Windsturm
  * @version 1.1.0
*/

//-----------------------------------------------------------------------------------------//
// This conversion for ps_2_b compliance by Lightworks user jwrl, 4 February 2016.
//
// Version history:
//
// Update 2020-11-15 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 7 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14 update 18 Feb 2017 by jwrl.
// Added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Video noise";
   string Category    = "Stylize";
   string SubCategory = "Video artefacts";
   string Notes       = "Generates either monochrome or colour video noise";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler s0 = sampler_state
{
   Texture = <Input>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Color Type";
   string Enum = "Monochrome,Color";
> = 0;

float Size
<
   string Description = "Size";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.0;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Alpha
<
   string Description = "Alpha";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 1.0;

float Seed
<
   string Description = "Random Seed";
   float MinVal = 0.00;
   float MaxVal = 1.00;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float rand (float2 uv, float seed)
{
   return frac (sin (dot (uv, float2 (12.9898,78.233)) + seed) * (43758.5453));
}

float4 FxNoiseMono (float2 xy : TEXCOORD1) : COLOR
{
   float2 xy2;

   if (Size != 0.0) {
      float xSize = Size;
      float ySize = xSize * _OutputAspectRatio;
      xy2 = float2 (round ((xy.x - 0.5) / xSize) * xSize, round ((xy.y - 0.5) / ySize) * ySize);
   }
   else xy2 = xy;

   float  c = rand (xy2, rand (xy2, Seed));
   float4 ret = lerp (tex2D (s0, xy), float2 (c, 1.0).xxxy, Opacity);

   return float4 (ret.rgb, ret.a * Alpha);
}

float4 FxNoiseColor (float2 xy : TEXCOORD1) : COLOR
{
   float2 xy2;

   if (Size != 0.0) {
      float xSize = Size;
      float ySize = xSize * _OutputAspectRatio;
      xy2 = float2 (round ((xy.x - 0.5) / xSize) * xSize, round ((xy.y - 0.5) / ySize) * ySize);
   }
   else xy2 = xy;

   float3 c = float3 (rand (xy2, rand (xy2, Seed)), rand (xy2, rand (xy2, Seed + 1)), rand (xy2, rand (xy2, Seed + 2)));
   float4 ret = lerp (tex2D (s0, xy), float4 (c, 1.0), Opacity);

   return float4 (ret.rgb, ret.a * Alpha);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Monochrome
{
   pass SinglePass
   {
      PixelShader = compile PROFILE FxNoiseMono ();
   }
}

technique Color
{
   pass SinglePass
   {
      PixelShader = compile PROFILE FxNoiseColor ();
   }
}
