// @Maintainer jwrl
// @Released 2020-11-11
// @Author schrauber
// @Created 2016-03-16
// @see https://www.lwks.com/media/kunena/attachments/6375/bulge-2018_640.png
// @see https://www.youtube.com/watch?v=IZToP0MrbZM

/**
 Bulge 2018 allows a variable area of the frame to have a concave or convex bulge applied.
 Optionally the background can have a radial distortion applied at the same time, or can
 be made black or transparent black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BulgeFx.fx
//
// This effect replaces the withdrawn bulge.fx.  It is incompatible with the old bulge
// effect already added to the timeline.  You can install this new effect in addition
// to the existing old effect, but avoid using the withdrawn version for new editing
// operations.
//
// Version history:
//
// Update 2020-11-11 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Update 23 Dec 2018 by LW user jwrl:
// Changed category.
// Formatted the descriptive block so that it can automatically be read.
//
// Update 18 Feb 2017 by LW user jwrl:
// Added subcategory for LW14
//
// Update 26 April 2018 by LW user schrauber:
// The aspect ratio of the bulge is now adjustable and rotatable.
// Fixed cross-platform compatibility (Mode: Environment, distorted).
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bulge 2018";
   string Category    = "DVE";
   string SubCategory = "Distortion";
   string Notes       = "This effect allows a variable area of the frame to have a concave or convex bulge applied";
   bool CanSize       = true;
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

float Zoom
<
   string Description = "Zoom";
   float MinVal = -3.0;
   float MaxVal = 3.0;
> = 1.0;

float Bulge_size
<
   string Group ="Bulge";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.25;

float AspectRatio
<
   string Group ="Bulge";
   string Description = "Aspect Ratio";
   float MinVal = 0.1;
   float MaxVal = 10.0;
> = 1.0;

float Angle
<
   string Group = "Bulge";
   string Description = "Angle";
   float MinVal = -3600.0;
   float MaxVal = 3600;
> = 0.0;

int Rotation
<
   string Description = "Rotation mode";
   string Enum = "Shape (Aspect ratio should not be 1),Only the bulge content,Bulge,Input texture";
> = 2;

int Mode
<
   string Description = "Environment of bulge";
   string Enum = "Original, Distorted, Black alpha 0, Black alpha 1";
> = 0;

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

//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR 
{ 

// ----Shader definitions and declarations ----

   float Tsin, Tcos;     // Sine and cosine of the set angle.
   float angle;
   float distortion = 0;
   float corRadius;           // Corrected object radius.

   // Position vectors
   float2 centre = float2 (Xcentre, 1.0 - Ycentre);
   float2 SpinPixel;     // The rotated Texel position.
   float2 xy = uv;

   // Direction vectors
   float2 vcenter;    // Vector between Center and Texel
   float2 Spin;       // Correction Vector for recalculation of objects Dimensions.

   // ------ Rotation of bulge dimensions. --------

   vcenter = uv - centre; 
   angle = radians( Angle  * -1.0);

   vcenter = float2(vcenter.x * _OutputAspectRatio, vcenter.y );

   sincos (angle, Tsin , Tcos);
   Spin = float2 ((vcenter.x * Tcos - vcenter.y * Tsin), (vcenter.x * Tsin + vcenter.y * Tcos)); 
   Spin = float2(Spin.x / _OutputAspectRatio, Spin.y );
   SpinPixel = Spin + centre;

   // ------ Bulge --------
 
  vcenter = centre - uv;
   if (Rotation == 1)  Spin = vcenter;
   corRadius = length (float2 (Spin.x / AspectRatio, (Spin.y / _OutputAspectRatio) * AspectRatio));
   
   if (Mode == 1 || corRadius < Bulge_size) 
      distortion = Zoom * sqrt (sin (abs(Bulge_size - corRadius) ));
   if (Mode == 2 && corRadius > Bulge_size) return (0.0).xxxx;
   if (Mode == 3 && corRadius > Bulge_size) return float4 (0.0.xxx, 1.0);

   if ( (Rotation == 3) 
      || (Rotation == 2 && corRadius < Bulge_size)
      || (Rotation == 1 && corRadius < Bulge_size)
      ) xy = SpinPixel;
   return tex2D (FgSampler, (distortion * (centre - xy)) + xy);
} 

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Bulge
{
   pass SinglePass
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
