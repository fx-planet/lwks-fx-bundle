//--------------------------------------------------------------//
// Lightworks user effect
//
// Created by LW user schrauber  06 November 2017
// @Author: schrauber
// @CreationDate: "06 November 2017"
// 
//--------------------------------------------------------------//


int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Whirl";  
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;





//--------------------------------------------------------------//
// Inputs und Samplers
//--------------------------------------------------------------//


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




//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//


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









//--------------------------------------------------------------//
// Common definitions, declarations, macros
//--------------------------------------------------------------//

float _OutputAspectRatio;





//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//


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






//--------------------------------------------------------------
// Technique
//--------------------------------------------------------------


technique main
{
   pass P_1 { PixelShader = compile PROFILE ps_main (); }
}


