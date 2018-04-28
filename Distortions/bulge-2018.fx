// @Maintainer jwrl
// @Released 2018-04-26
// @Author schrauber
// @Created 2016-03-16
// @see https://www.lwks.com/media/kunena/attachments/6375/Bulge_4.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Bulge_3_2016-04-10.png
// @see https://www.youtube.com/watch?v=IZToP0MrbZM
//-----------------------------------------------------------------------------------------//
// Lightworks user effect bulge-2018.fx
//
// Bulge allows a variable area of the frame to have a concave or convex bulge applied.
// Optionally the background can have a radial distortion applied at the same time, or
// can be made black or transparent black.
//
// This effect  bulge-2018.fx replaces the withdrawn bulge.fx
// This effect file is incompatible with the old bulge effect already added to the timeline.
// You can also install this new effect in addition to the existing old effect,
// but avoid using the withdrawn version for new editing operations.
//
// Update:
// 26 April 2018 by LW user schrauber: The aspect ratio of the bulge is now adjustable and rotatable.
// 26 April 2018 by LW user schrauber: Fixed cross-platform compatibility (Mode: Environment, distorted).
// 18 Feb 2017 by LW user jwrl:        Added subcategory for LW14
// 18 Feb 2017 by LW user jwrl:        Added subcategory for LW14
//
//-----------------------------------------------------------------------------------------//


int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Bulge 2018";
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
   float dist;           // Corrected distance to the effect center (affects the shape and angle of the bulge).

   // Position vectors
   float2 centre = float2 (Xcentre, 1.0 - Ycentre);
   float2 posSpin;       // The not centered rotated Texel position.
   float2 SpinPixel;     // The centered and rotated Texel position.
   float2 xy = uv;

   // Direction vectors
   float2 vcenter;    // Vector between Center and Texel



   // ------ Rotation of bulge dimensions. --------

   vcenter = uv - centre; 
   angle = radians( Angle  * -1.0);
   
   vcenter = float2(vcenter.x * _OutputAspectRatio, vcenter.y );

   sincos (angle, Tsin , Tcos);
   posSpin = float2 ((vcenter.x * Tcos - vcenter.y * Tsin), (vcenter.x * Tsin + vcenter.y * Tcos)); 
   posSpin = float2(posSpin.x / _OutputAspectRatio, posSpin.y );
   SpinPixel = posSpin + centre;



   // ------ Bulge --------
   vcenter = centre - uv;
   if (Rotation == 1)  posSpin = vcenter;
   dist = length (float2 (posSpin.x / AspectRatio, (posSpin.y / _OutputAspectRatio) * AspectRatio));
   
   if (Mode == 1 || dist < Bulge_size) 
      distortion = Zoom * sqrt (sin (abs(Bulge_size - dist) ));
   if (Mode == 2 && dist > Bulge_size) return (0.0).xxxx;
   if (Mode == 3 && dist > Bulge_size) return float4 (0.0.xxx, 1.0);

   if ( (Rotation == 3) 
      || (Rotation == 2 && dist < Bulge_size)
      || (Rotation == 1 && dist < Bulge_size)
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
