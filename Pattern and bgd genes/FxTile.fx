// @Maintainer jwrl
// @Released 2018-04-08
// @Author windsturm
// @see https://www.lwks.com/media/kunena/attachments/6375/FxTile_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect FxTile.fx
//-----------------------------------------------------------------------------------------//

/**
  * FxTile.
  * Tiling and Rotation effect.
  * 
  * @param <threshold> The granularity of the tiling parameters
  * @param <angle> Rotation parameters of the screen
  * @author Windsturm
  * @version 1.0
  * @see <a href="http://kuramo.ch/webgl/videoeffects/">WebGL Video Effects Demo</a>
*/

//-----------------------------------------------------------------------------------------//
// Checked and modded for ps_2_b compliance by Lightworks user jwrl, 5 February 2016.
//
// LW 14+ version by jwrl 12 February 2017 - SubCategory added.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "FxTile";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

sampler s0 = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float threshold
<
   string Description = "Threshold";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.5;

float angle
<
   string Description = "Angle";
   float MinVal = 0.00;
   float MaxVal = 360.00;
> = 0.00;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Pixel Shader
//-----------------------------------------------------------------------------------------//

float4 FxRotateTile (float2 xy : TEXCOORD1) : COLOR
{
   float Tcos, Tsin;

   if (threshold >= 1.0) return float2 (0.5, 1.0).xxxy;

   xy -= 0.5.xx;

   //rotation

   float2 angXY = float2 (xy.x, xy.y / _OutputAspectRatio);

   sincos (radians (angle), Tsin, Tcos);

   float temp = (angXY.x * Tcos - angXY.y * Tsin) + 0.5;

   angXY.y = ((angXY.x * Tsin + angXY.y * Tcos) * _OutputAspectRatio ) + 0.5;
   angXY.x = temp;

   // tiling

   return tex2D (s0, frac ((angXY - 0.5.xx) / (1.0 - threshold) + 0.5.xx));
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE FxRotateTile ();
   }
}
