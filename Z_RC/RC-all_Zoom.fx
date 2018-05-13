// @Maintainer schrauber
// @Maintainer jwrl
// @Released 2018-05-14
// @Author schrauber
// @Created 2017-02-01
//--------------------------------------------------------------//
// Lightworks user effect RC-all_Zoom.fx
//
// This is the remote control version of the earlier regional zoom effect.
// This version only works when it is controlled by a master remote control.
// All parameters are remote controlled, and require 4 remote control channels.
//   Exception: If required, "Flip edge" can be activated in the effect itself.
//
//
// Update 14 May 2018 by LW user schrauber:
//   Category changed and subcategory defined.
//   When channel 0 is set, the remote control for this parameter is now disabled,
//      and a default value is applied.
//   Cross-platform compatibility optimized.
//--------------------------------------------------------------//
//
// ... Update information for effect developers ...
//
// Update 14 May 2018 by LW user schrauber:
//   Only one sampler per input (cross-platform compatibility)
//   Sampler settings RC-input (cross-platform compatibility and functional change)
//   Effect description and other data relevant to the user repository added.
//   
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC-all Zoom";
   string Category    = "Stylize";
   string SubCategory = "Requires remote control";
> = 0;




//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//


float ChZoom
<
   string Group = "Receiving Channel";
   string Description = "Zoom";
   float MinVal = 1.0;
   float MaxVal = 5000.0;
> = 1.0;



float ChArea
<
   string Group = "Receiving Channel";
   string Description = "Area";
   float MinVal = 1.0;
   float MaxVal = 5000.0;
> = 2.0;



float ChXcentre
<
   string Group = "Receiving Channel";
   string Description = "Zoom centre X";
   float MinVal = 1.0;
   float MaxVal = 5000.0;
> = 3.0;

float ChYcentre
<
   string Group = "Receiving Channel";
   string Description = "Zoom centre Y";
   float MinVal = 1.0;
   float MaxVal = 5000.0;
> = 4.0;


bool Flip_edge
<
	string Description = "Flip edge";
> = false;




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
	

#define AREA1       RECEIVING(ChArea)
#define AREA        (200.0 - AREA1*201.0)

#define X_CENTRE    RECEIVING_0_1(ChXcentre)
#define Y_CENTRE    (1.0 - RECEIVING_0_1(ChYcentre))



// Receiving scalar value from the remote control input

#define RECEIVING(Ch)       ( RECEIVING_COLOR(Ch) * 2 - step( 0.001 , STATUS_CH_IN(Ch) ) ) 			// Receiving,  numeral system (-1 ... +1) ,   Default value 0.0   ,  "Step" prevents a change in the received Default value if the channel can not be received.  If Status Channel > 0.001 then the calculation:   RECEIVING_COLOR * 2 - 1   ,     If the blue-status = 0.0 then the calculation:   RECEIVING_COLOR * 2 - 0 
#define RECEIVING_0_1(Ch)   ( RECEIVING_COLOR(Ch) + step( STATUS_CH_IN(Ch) , 0.001 ) / 2 ) 			// Receiving,  numeral system  ( 0 ... 1) ,   Default value 0.5   ,  "Step" prevents a change in the received Default value if the channel can not be received.  If Status Channel > 0.001 then the calculation:   RECEIVING_COLOR + 1/2     ,     If the blue-status = 0.0 then the calculation:   RECEIVING_COLOR + 0/2 

   #define RECEIVING_COLOR(Ch)    (  tex2D(RcSampler, POSCHANNEL(floor(Ch))  ).r				/* Receiving  Red = bit 1 to bit 8 of 16Bit     ,   The value of  "Ch" (receiving channel) is only passed to sub macros  */\
                                 + ((tex2D(RcSampler, POSCHANNEL(floor(Ch))).g) / 255) )			/* Green = bit 9 to bit 16   */

      #define STATUS_CH_IN(Ch)     ((tex2D(RcSampler, POSCHANNEL(floor(Ch)))).b)				// Status of the receiving channel ,   blue 0.0  = OFF   ,    0.2 = only Data  ,   0.4   = ON  ,   1.0 = ON and the value of the remote control signal was limited by the sending effect.   ,    The value of ChannelInput is only passed to sub macros 

         // Position of the Channel
         #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )		// Sub macro,   Position of the pixel to be converted.  (  - 0.005 and  + 0.01 ar the center of the respective position)    ,   "ch" is the receiving channel. 
            #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )					// Sub macro,   y - position of the the color signal.    50 channel groups    ,     "ch" is the receiving channel. 
 







//-----------------------------------------------------------------------------------------//
// Shader
//-----------------------------------------------------------------------------------------//

float4 ps_zoom (float2 uv : TEXCOORD1) : COLOR
{
 float2 xydist = float2 (X_CENTRE, Y_CENTRE) - uv; 				// XY Distance between the current position to the adjusted effect centering
 float distance = length (float2 (xydist.x, xydist.y / _OutputAspectRatio)); 	// Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
 										// Macro, Pick up the rendered variable ( "strengthCycle" (-1 to +1) , 16-bit color by using two 8-bit colors)
 float zoom = RECEIVING(ChZoom);						// Receiving from the remote control input
 float distortion = (distance * ((distance * AREA) + 1.0) + 1);			// Creates the distortion
 if (AREA1 != 1) zoom = zoom / max( distortion, 0.1 ); 				// If the area = 1, then normal zoom works. Otherwise, a local zoom is active.   "0.1" prevents a division by zero 
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

