// @Maintainer jwrl
// @Released 2020-09-28
// @Author baopao
// @Author nouanda
// @Created 2013-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Kaleido_640.png

/**
 Kaleido A (previously Kaleido) produces the classic kaleidoscope effect.  The number of
 sides, the centering, scaling and zoom factor are all adjustable.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect KaleidoA.fx
//
// Kaleido baopao (http://www.alessandrodallafontana.com) is based on the pixel shader
// of: http://pixelshaders.com/ corrected for Cg by Lightworks user nouanda.
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Revised header block.
//
// Modified 27 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//
// Modified 5 December 2018 jwrl.
// Added creation date.
// Changed subcategory.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// LW 14+ version by jwrl 12 February 2017
// SubCategory "Patterns" added.
//
// Modified August 10 2016 by jwrl.
// Corrected three potential divide by zero errors by LW moderator jwrl.
// Some code optimisation done mainly for Cg compliance.
// User interface slightly altered.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleido A";
   string Category    = "Stylize";
   string SubCategory = "Special Effects";
   string Notes       = "The number of sides in this kaleidoscope, the centering, scaling and zoom factor are all adjustable";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Input;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Sides
<
   string Description = "Sides";
   float MinVal = 1.0;
   float MaxVal = 50.0;
> = 5.0;

float scaleAmt
<
   string Description = "Scale";
   float MinVal = 0.0;
   float MaxVal = 2.00;
> = 1.0;

float zoomFactor
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 2.00;
> = 1.0;

float PosX
<
   string Description = "Pan";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float PosY
<
   string Description = "Pan";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI      3.141593
#define TWO_PI  6.283185

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float Scale = (scaleAmt < 1.0) ? (scaleAmt * 0.999) + 0.001 : scaleAmt;
   float Zoom  = (zoomFactor < 1.0) ? (zoomFactor * 0.999) + 0.001 : zoomFactor;

   float2 PosXY = float2 (PosX, PosY);
   float2 xy = float2 (1.0 - uv.x, uv.y);

   xy -= PosXY;

   float radius = length (xy) / Zoom;
   float angle  = atan2 (xy.y, xy.x);

   angle = fmod (angle, TWO_PI / Sides);
   angle = abs (angle - (PI / Sides));

   sincos (angle, xy.y, xy.x);
   xy = ((xy * radius) + PosXY) / Scale;

   return tex2D (FgSampler, xy);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SimpleTechnique
{
   pass MainPass
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
