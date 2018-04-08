// @Maintainer jwrl
// @Released 2018-04-08
// @Author baopao
// @see https://www.lwks.com/media/kunena/attachments/6375/Kaleido_2016-08-08.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Kaleido.fx
//
// Kaleido baopao (http://www.alessandrodallafontana.com) is based on the pixel shader
// of: http://pixelshaders.com/ corrected for HLSL by Lightworks user nouanda.
//
// Modified August 10 2016 by jwrl.
// Corrected three potential divide by zero errors by LW moderator jwrl.
// Some code optimisation done mainly for Cg compliance.
// User interface slightly altered.
//
// LW 14+ version by jwrl 12 February 2017
// SubCategory "Patterns" added.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Kaleido";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
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

#pragma warning ( disable : 3571 )

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
