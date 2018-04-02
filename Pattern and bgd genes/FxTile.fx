// @ReleaseDate 2018-03-31
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

//--------------------------------------------------------------//
// FxTile
//
// Checked and modded for ps_2_0 compliance by Lightworks user
// jwrl, 5 February 2016.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "FxTile";       // The title
   string Category    = "Stylize";      // Governs the category that the effect appears in in Lightworks
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

float _OutputAspectRatio;

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

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------

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

//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------

technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE FxRotateTile ();
   }
}

