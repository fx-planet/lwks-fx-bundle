// @Maintainer jwrl
// @Released 2018-05-04
// @Author schrauber
// @Created 2017-02-01
//--------------------------------------------------------------//
// Lightworks user effect RC_Zoom_Regional_20180506.fx
//
// This is the remote control version of the earlier regional zoom effect.
// This version only works when it is controlled by a master remote control.
// The area on which the zoom works and the centre of the zoom can be set in the effect itself.
// 
//
// Update 5 May 2018 by LW user schrauber:
//   Category changed and subcategory defined.
//   Cross-platform compatibility (only one sampler per input)
//   Effect description and other data relevant to the user repository added.
//
//
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC Zoom";
   string Category    = "Stylize";
   string SubCategory = "Requires remote control";
> = 0;




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




float ChZoom
<
   string Description = "Channel, zoom";
   float MinVal = 1.0;
   float MaxVal = 5000.0;
> = 1.0;



float Area
<
	string Description = "Area";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 1.00;



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


bool Flip_edge
<
	string Description = "Flip edge";
> = true;




//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
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


texture RC;
sampler RcSampler = sampler_state
{
   Texture = <RC>;
   AddressU = Border;  // If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control.
   AddressU = Border;  // If a channel position is set outside the texture (e.g., channel 0), a black border turns off the remote control.
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
};




//-----------------------------------------------------------------------------------------//
// Definitions  ,  declarations  , makro    
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;
	
#define AREA  (200-Area*201)

// Receiving scalar value from the remote control input
// The documentation for the macro RECEIVING (Ch), and the associated sub-macros, can be found in the subcode repository.

   #define RECEIVING(Ch)    (    (   tex2D(RcSampler, POSCHANNEL(floor(Ch))).r \
                              + ((tex2D(RcSampler, POSCHANNEL(floor(Ch))).g) / 255) \
                             ) * 2 - step( 0.001 , STATUS_CH_IN(Ch))  )
                             
   #define STATUS_CH_IN(Ch)     ((tex2D(RcSampler, POSCHANNEL(floor(Ch)))).b)            
            
      #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )        
         #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )





//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//


float4 ps_zoom (float2 uv : TEXCOORD1) : COLOR
{
 float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - uv; 				// XY Distance between the current position to the adjusted effect centering
 float distance = length (float2 (xydist.x, xydist.y / _OutputAspectRatio)); 	// Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
 
 float zoom = RECEIVING(ChZoom);						// Receiving from the remote control input
 float distortion = (distance * ((distance * AREA) + 1.0) + 1);			// Creates the distortion
 if (Area != 1) zoom = zoom / max( distortion, 0.1 ); 				// If the area = 1, then normal zoom works. Otherwise, a local zoom is active.   "0.1" prevents a division by zero 
 float2 xy = zoom * xydist + uv;

 if ((!Flip_edge) 
    && (  (xy.x < 0.0) || (xy.y < 0.0) || (xy.x > 1.0) || (xy.y > 1.0) ))
    return (0.0).xxxx; 
 return tex2D (FgSampler, xy); 
} 


//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique main
{
   pass P_1
   {
      PixelShader = compile PROFILE ps_zoom();
   }
}

