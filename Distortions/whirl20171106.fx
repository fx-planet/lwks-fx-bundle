// @Maintainer jwrl
// @Released 2017-11-06
// @Author schrauber
// @Created 2017-11-06
// @see https://www.lwks.com/media/kunena/attachments/6375/Whirl_1.png
// @see https://www.youtube.com/watch?v=LB5-_cvkRb0
//-----------------------------------------------------------------------------------------//
// Lightworks user effect whirl20171106.fx
//
// Visualise what happens when water empties out of a sink, and you have what this effect
// does.  Possibly you could regard it as adding the sort of sink error you want to your
// video!
// 
//
//
//
//
//
//
// 
//
//
//
//
//
//
//
//
// End of effect description
//
//
//-----------------------------------------------------------------------------------------//
// Information for Effect Developer:
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// GitHub-relevant modifications, 15 April 2018 schrauber: 
// Lightworks relevant release date used.
// Added video link.
// Added provisional comment blank lines (test the presentation on the homepage)
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Whirl";  
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

texture Input;

sampler FgSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float WhirlCenter
<
   string Description = "Whirl";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;


float WhirlOutside
<
   string Description = "Whirl, outside";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;





float Spin
<
   string Description = "Revolutions";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 0.0;



float Zoom
<
   string Description = "Zoom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;


float XzoomPos
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float YzoomPos
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Common definitions, declarations, macros
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{ 
 
   // ----Shader definitions and declarations ----

   float Tsin, Tcos;    // Sine and cosine of the set angle.
   float angle;
   float distance;      //Distance from the center of rotation

   // Position vectors
   float2 centreEffect = float2 (XzoomPos, 1.0 - YzoomPos);
   float2 posZoom, posSpin;

   // Direction vectors
   float2 vCzT;              // Vector between Center(zoom) and Texel
   float2 vCrT;              // Vector between Center(rotation) and Texel




   // ------ ROTATION --------

   vCrT = uv - centreEffect;
   distance = length (float2 (vCrT.x, vCrT.y / _OutputAspectRatio)); 

   angle = radians
           (
              (Spin * 360.0)
            + (WhirlOutside * 360.0 * distance)
            + (WhirlCenter * 360.0 * (1.0 - distance))
              * -1.0
           );
   
   vCrT = float2(vCrT.x * _OutputAspectRatio, vCrT.y );

   sincos (angle, Tsin , Tcos);
   posSpin = float2 ((vCrT.x * Tcos - vCrT.y * Tsin), (vCrT.x * Tsin + vCrT.y * Tcos)); 
   posSpin = float2(posSpin.x / _OutputAspectRatio, posSpin.y ) + centreEffect;


   // ------ ZOOM -------

  
   vCzT = centreEffect - posSpin;
   posZoom = ( (1.0- (exp2( Zoom * 10.0 *-1.0))) * vCzT ) + posSpin;            // The set value Zoom has been replaced by the formula  (1- (exp2( Zoom * 10 -1)))   to get the setting characteristic described in the header.


   

 
   // ------ OUTPUT-------

   return tex2D (FgSampler, posZoom);

}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique main
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}

