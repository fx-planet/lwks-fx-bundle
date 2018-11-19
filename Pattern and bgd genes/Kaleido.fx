// @Maintainer jwrl
// @Released 2018-11-20
// @Author baopao
// @Author nouanda
// @Created 2013-06-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Kaleido_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Kaleido.fx
//
// !!! DO NOT USE !!! Use Kaleido B instead.
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
// SubCategory "User Effects" added.
//
// Modified 8 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 20 November 2018 jwrl.
// Addressed several bugs that were introduced during compatibility fixing and other
// adjustments.
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

sampler s_Input = sampler_state
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

#define TWO_PI  6.2831853072

#define MINIMUM 0.0000000001

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float2 PosXY = float2 (PosX, 1.0 - PosY);
   float2 xy = uv - PosXY;

   float sides = max (MINIMUM, Sides);
   float scale = max (MINIMUM, scaleAmt);
   float zoom  = max (MINIMUM, zoomFactor);
   float radius = length (xy);
   float tmp = max (MINIMUM, abs (xy.x));

   xy.x = xy.x < 0.0 ? -tmp : tmp;

   float angle = atan (xy.y / xy.x);

   tmp = TWO_PI / sides;
   angle -= tmp * floor (angle / tmp);
   angle = abs (angle - (tmp * 0.5));

   sincos (angle, xy.y, xy.x);
   xy = ((xy * radius / zoom) + PosXY) / scale;

   return tex2D (s_Input, xy);
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
