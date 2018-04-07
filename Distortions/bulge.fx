// @Maintainer jwrl
// @Released 2018-04-07
// @Author schrauber
// @see https://www.lwks.com/media/kunena/attachments/6375/Bulge_4.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Bulge_3_2016-04-10.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect bulge.fx
//
// Bulge allows a variable area of the frame to have a concave or convex bulge applied.
// Optionally the background can have a radial distortion applied at the same time, or
// can be made transparent black.
//
// Added subcategory for LW14 - jwrl 18 Feb 2017
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bulge";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and shader
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float zoom
<
	string Description = "Zoom";
	float MinVal = -3.00;
	float MaxVal = 3.00;
> = 0.00;

float bulge_size
<
	string Description = "Bulge size";
	float MinVal = 0.00;
	float MaxVal = 0.50;
> = 0.25;

bool environment
<
	string Description = "Distort environment";
> = false;

bool black
<
	string Description = "Transparency on";
> = false;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 universal (float2 xy : TEXCOORD1) : COLOR 
{ 
   float2 XYc = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = XYc - xy;
   float2 pos_zoom = float2 (xy1.x, xy1.y / _OutputAspectRatio);
   float distortion = 0;

   float _distance = distance ((0.0).xx, pos_zoom);

   if ((_distance < (bulge_size)) || (environment))
      distortion = zoom * sqrt (sin (bulge_size - _distance));
 
   if ((_distance > bulge_size) && (black))
      return (0.0).xxxx;

   xy1 = distortion * xy1 + xy;

   return tex2D (FgSampler, xy1);
} 

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Bulge
{
   pass SinglePass
   {
      PixelShader = compile PROFILE universal ();
   }
}
