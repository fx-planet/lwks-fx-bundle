// @Maintainer jwrl
// @Released 2018-12-06
// @Author khaver
// @Created 2014-11-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Strobe_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Strobe.fx
//
// Strobe is a two-input effect which switches rapidly between two video layers.  The
// switch rate is dependent on the length of the clip.  There should be enough adjustment
// range of strobe spacing to allow any reasonable clip size to be used, but if you need
// more range break the clip into sections and repeat the effect.
//
// Version 14 update 18 Feb 2017 jwrl.
// Added subcategory to effect header.
//
// Cross platform compatibility check 2 August 2017 jwrl.
// Explicitly defined samplers to avoid cross platform default sampler differences.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//
// Modified 6 December 2018 jwrl.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Strobe";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture fg;
texture bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FGround = sampler_state {
        Texture = <fg>;
        AddressU = Clamp;
        AddressV = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };
sampler BGround = sampler_state {
        Texture = <bg>;
        AddressU = Clamp;
        AddressV = Clamp;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
 };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

bool swap
<
	string Description = "Swap";
> = false;

float strobe
<
	string Description = "Strobe Spacing";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 1.0f;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 Combine( float2 uv : TEXCOORD1 ) : COLOR
{
  float maxi = 20000;
  float theprogress = 20000.0 * _Progress;
  float mini = 20000 * strobe;
  float4 FG, BG;
  if (swap) {
	BG = tex2D( BGround, uv);
	FG = tex2D( FGround, uv);
  }
  else {
	BG = tex2D( FGround, uv);
	FG = tex2D( BGround, uv);
  }
  float rem = frac(ceil(theprogress/mini) / 2.0);
  if (rem == 0.0) return FG;
  else return BG;
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Strobe
{

   pass Pass1
   {
      PixelShader = compile PROFILE Combine();
   }
}
