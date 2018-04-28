// @Maintainer jwrl
// @Released 2018-04-28
// @Author schrauber
// @Created 2017-01-31
//--------------------------------------------------------------//
// Lightworks user effect RC1_Remote_control.fx
//
// This is the master controller for the entire remote control user effects subsystem.
// It generates up to five separate remote control channels on the one output.
// By itself it does very little, but when used with the appropriate effects it is a very powerful tool.
// The desired channel to be used is selected in the custom remote-controllable effect.
//
// All channels can be controlled simultaneously by means of a "Master" slider.
// As with all adjustable controls, here keyframing can be used.
// In turn, that Master can itself be remote controlled.
// The "Multiply", parameter allows the master signal to amplify, 
// attenuate or invert the individual control channels.
// Each channel can be set directly, and the remote control signal may also be limited.
//
// Limitations and Known Problems:
// The optional effect inputs are incompatible with GPU Precision Settings "16-bit Floating Point" (Lightworks 14.5)
//
// Update:
// 26 April 2018 by LW user schrauber: Unnecessary sampler settings removed.
//
// Insignificant updates at different times:
// Too long effect name corrected, subcategory defined, effect description
// and other data relevant to the user repository added.
//--------------------------------------------------------------//


int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC 1, Five channel remote"; 
   string Category    = "User" 
   string SubCategory = "Remote Control";  
> = 0;


//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//


texture R1;
sampler remoteImput1 = sampler_state { Texture = <R1>; };



texture R2;
sampler remoteImput2 = sampler_state { Texture = <R2>; };



texture R3;
sampler remoteImput3 = sampler_state { Texture = <R3>; };


texture R4;
sampler remoteImput4 = sampler_state { Texture = <R4>; };




texture RenderInputMix : RenderColorTarget;
sampler InputMix = sampler_state
{
   Texture = <RenderInputMix>;
   AddressU = Border;					
   AddressV = Border;					
   MinFilter = PYRAMIDALQUAD;
   MagFilter = PYRAMIDALQUAD;				// MagFilter setting when the sampler uses the pixel coordinates of "TEXCOORD0" .
   MipFilter = PYRAMIDALQUAD;
};





//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float ChannelInput
<

   string Group = "Common setting (internal Master slider = channel 0";
   string Description = "Channel";
   float MinVal = 0.0;
   float MaxVal = 5000.0;
> =  0.0;



float MasterInt
<

   string Group = "Common setting (internal Master slider = channel 0";
   string Description = "Master internal";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  0.0;




float Multiply1
<

   string Group = "Mix with the master and Output to channel 1";
   string Description = "Multiply";
   float MinVal = -5.0;
   float MaxVal = 5.0;
> =  1.0;

float Add1
<

   string Group = "Mix with the master and Output to channel 1";
   string Description = "Offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  0.0;



float LimitUp1
<

   string Group = "Mix with the master and Output to channel 1";
   string Description = "Up limit, priority";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  1.0;



float LimitDown1
<

   string Group = "Mix with the master and Output to channel 1";
   string Description = "Down limit";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  -1.0;








float Multiply2
<

   string Group = "Mix with the master and Output to channel 2";
   string Description = "Multiply";
   float MinVal = -5.0;
   float MaxVal = 5.0;
> =  1.0;

float Add2
<

   string Group = "Mix with the master and Output to channel 2";
   string Description = "Offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  0.0;


float LimitUp2
<

   string Group = "Mix with the master and Output to channel 2";
   string Description = "Up limit, priority";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  1.0;



float LimitDown2
<

   string Group = "Mix with the master and Output to channel 2";
   string Description = "Down limit";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  -1.0;








float Multiply3
<

   string Group = "Mix with the master and Output to channel 3";
   string Description = "Multiply";
   float MinVal = -5.0;
   float MaxVal = 5.0;
> =  1.0;

float Add3
<

   string Group = "Mix with the master and Output to channel 3";
   string Description = "Offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  0.0;


float LimitUp3
<

   string Group = "Mix with the master and Output to channel 3";
   string Description = "Up limit, priority";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  1.0;



float LimitDown3
<

   string Group = "Mix with the master and Output to channel 3";
   string Description = "Down limit";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  -1.0;









float Multiply4
<

   string Group = "Mix with the master and Output to channel 4";
   string Description = "Multiply";
   float MinVal = -5.0;
   float MaxVal = 5.0;
> =  1.0;

float Add4
<

   string Group = "Mix with the master and Output to channel 4";
   string Description = "Offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  0.0;


float LimitUp4
<

   string Group = "Mix with the master and Output to channel 4";
   string Description = "Up limit, priority";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  1.0;



float LimitDown4
<

   string Group = "Mix with the master and Output to channel 4";
   string Description = "Down limit";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  -1.0;










float Multiply5
<

   string Group = "Mix with the master and Output to channel 5";
   string Description = "Multiply";
   float MinVal = -5.0;
   float MaxVal = 5.0;
> =  1.0;

float Add5
<

   string Group = "Mix with the master and Output to channel 5";
   string Description = "Offset";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  0.0;


float LimitUp5
<

   string Group = "Mix with the master and Output to channel 5";
   string Description = "Up limit, priority";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  1.0;



float LimitDown5
<

   string Group = "Mix with the master and Output to channel 5";
   string Description = "Down limit";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> =  -1.0;



 










//-----------------------------------------------------------------------------------------//
//Definitions, declarations, macros
//-----------------------------------------------------------------------------------------//



 #define VALUE_CHANNEL1    (Master * Multiply1  +  Add1)
 #define VALUE_CHANNEL2    (Master * Multiply2  +  Add2)
 #define VALUE_CHANNEL3    (Master * Multiply3  +  Add3)
 #define VALUE_CHANNEL4    (Master * Multiply4  +  Add4)
 #define VALUE_CHANNEL5    (Master * Multiply5  +  Add5)

 #define CLAMP_CHANNEL1    clamp(VALUE_CHANNEL1 , LimitDown1 , LimitUp1)
 #define CLAMP_CHANNEL2    clamp(VALUE_CHANNEL2 , LimitDown2 , LimitUp2)
 #define CLAMP_CHANNEL3    clamp(VALUE_CHANNEL3 , LimitDown3 , LimitUp3)
 #define CLAMP_CHANNEL4    clamp(VALUE_CHANNEL4 , LimitDown4 , LimitUp4)
 #define CLAMP_CHANNEL5    clamp(VALUE_CHANNEL5 , LimitDown5 , LimitUp5)






// ---- Receiving from the remote control input -------
	
      #define MASTER_EXT    (    (   tex2D(InputMix, POSCHANNEL(floor(ChannelInput))).r					/* Receiving  Red = bit 1 to bit 8 of 16Bit     ,   The value of ChannelInput is only passed to sub macros  */\
                                 + ((tex2D(InputMix, POSCHANNEL(floor(ChannelInput))).g) / 255)				/* Green = bit 9 to bit 16   */\
                                 ) * 2 - 1)										// Adjustment of the numeral system from  ( 0 ... 1) to (-1 ... +1)

      #define STATUS_INPUT     ((tex2D(InputMix, POSCHANNEL(floor(ChannelInput)))).b)					// blue 0.0  = OFF   ,    0.2 = only Data  ,   0.4   = ON  ,   1.0 = ON and the value of the remote control signal was limited by the sending effect.   ,    The value of ChannelInput is only passed to sub macros 

         // Position of the Channel
         #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )				// Sub macro,   Position of the pixel to be converted.  (  - 0.005 and  + 0.01 ar the center of the respective position)    ,   "ch" is the receiving channel. 
            #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )						  	// Sub macro,   y - position of the the color signal.    50 channel groups    ,     "ch" is the receiving channel. 
 
   



// ---------- Transmitter,  Position ----------------------


// Position of the signal to be transmitted in the texture.

    //  Option, if channels are to be used over number 100:
    //  #define POSy_CHANNELGROUP_1_0_1  (2 * 0.02)										// Channelgroup 2  (Channel 201 to 300)      Multiplication with 0.02  =  y-Position of the lower edge of the color signal.
    //  #define POS_CHANNELGROUP_1_0_1   (xy.y > POSy_CHANNELGROUP_1_0_1 && xy.y < POSy_CHANNELGROUP_1_0_1 + 0.02)		// Channel group for transmission. 0.02 is the y-size of the color signal areas.


   #define POSy_CHANNELGROUP_1_0_1   0.02										// Channelgroup 0  (Channel 001 to 100)
   #define POS_CHANNELGROUP_1_0_1   (xy.y < POSy_CHANNELGROUP_1_0_1)							// Channel group for transmission. 0.02 is the y-size of the color signal areas.
   #define POSx_CHANNEL1            (xy.x < 0.01)									// Channel 1,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL2            (xy.x > 0.01 && xy.x < 0.02)							// Channel 2,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL3            (xy.x > 0.02 && xy.x < 0.03)							// Channel 3,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL4            (xy.x > 0.03 && xy.x < 0.04)							// Channel 4,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL5            (xy.x > 0.04 && xy.x < 0.05)							// Channel 5,    x - position position and dimensions of the the color signal
 



// ---------- Transmitter,  Output ----------------------

// "RENDER_1_0_1(Tx)"  Numeral system input -1 to +1, output 0 to 1
//                     Transmits the value of "Tx" as a 16-bit color by using two 8-bit colors ,
//                     and transmits the value of Tx as  a 8-bit color
 #define RENDER_1_0_1(Tx,Status)   return float4 (TRANSMIT(Tx) - BIT9TO16_1_0_1(Tx) / 255 , BIT9TO16_1_0_1(Tx) , Status , TRANSMIT(Tx))		// Return: Red = bit 1 to bit 8 of 16 Bit,     Green (BIT9TO16) = bit 9 to bit 16 of 16 Bit,      Blue = Status, transmitter ON,       Alpha = 8 Bit
    #define BIT9TO16_1_0_1(Tx)        fmod(TRANSMIT(Tx) * 255 , 1)										// Here the color channel for bit 9 to bit 16.
       #define TRANSMIT(Tx)              ((Tx + 1) / 2)												// Adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1)








//-----------------------------------------------------------------------------------------//
// Shaders 
//-----------------------------------------------------------------------------------------//

float4 ps_Inputs (float2 xy : TEXCOORD0 , float2 xy1 : TEXCOORD1 , float2 xy2 : TEXCOORD2 , float2 xy3 : TEXCOORD3 , float2 xy4 : TEXCOORD4) : COLOR
{ 
 
 // The following priorities apply when the channels are identical:
 // Primarily: R1 
         // Then: R2
            // Then: R3
               // Subordinated: R4

 if ( tex2D(remoteImput1,xy1).b > 0.0 ) return tex2D (remoteImput1,xy1); 	// Pass the color signal from the remote input 1
 if ( tex2D(remoteImput2,xy2).b > 0.0 ) return tex2D (remoteImput2,xy2); 	// Pass the color signal from the remote input 2
 if ( tex2D(remoteImput3,xy3).b > 0.0 ) return tex2D (remoteImput3,xy3); 	// Pass the color signal from the remote input 3
 return tex2D (remoteImput4,xy4); 						// Pass the color signal from the remote input 4				
}




float4 ps_RemoteControl (float2 xy : TEXCOORD0) : COLOR
{ 
 float Master = MasterInt;
 if ( STATUS_INPUT >= 0.4 ) Master = MASTER_EXT;				//Selects the common master remote control value for all output channels.

 float status1 = 0.4;					 			// Status, transmitter    ,    0.0  = OFF   ,    0.4   = ON   
 float status2 = 0.4;								// Note: To make it easier to check the status values, the status value should be selected so that this would result in an integer in the case of a multiplication by 255. This ensures that no rounding errors occur after rendering.
 float status3 = 0.4;
 float status4 = 0.4;
 float status5 = 0.4;
 
 
 if (VALUE_CHANNEL1  != CLAMP_CHANNEL1  || STATUS_INPUT == 1.0) status1 = 1.0;	// Status, transmitter    1.0 = ON and clamped value
 if (VALUE_CHANNEL2  != CLAMP_CHANNEL2  || STATUS_INPUT == 1.0) status2 = 1.0;
 if (VALUE_CHANNEL3  != CLAMP_CHANNEL3  || STATUS_INPUT == 1.0) status3 = 1.0;
 if (VALUE_CHANNEL4  != CLAMP_CHANNEL4  || STATUS_INPUT == 1.0) status4 = 1.0;
 if (VALUE_CHANNEL5  != CLAMP_CHANNEL5  || STATUS_INPUT == 1.0) status5 = 1.0;




 if (POS_CHANNELGROUP_1_0_1)							// Channel group for transmission of values.
 {
    if (POSx_CHANNEL1)     RENDER_1_0_1(CLAMP_CHANNEL1 , status1); 		// Transmission 16 Bit and 8 Bit (and adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1))
    if (POSx_CHANNEL2)     RENDER_1_0_1(CLAMP_CHANNEL2 , status2);
    if (POSx_CHANNEL3)     RENDER_1_0_1(CLAMP_CHANNEL3 , status3);
    if (POSx_CHANNEL4)     RENDER_1_0_1(CLAMP_CHANNEL4 , status4);
    if (POSx_CHANNEL5)     RENDER_1_0_1(CLAMP_CHANNEL5 , status5);
 }


  return tex2D (InputMix,xy);;
}









//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//


technique main
{
   pass P_1   < string Script = "RenderColorTarget0 = RenderInputMix;"; >        { PixelShader = compile PROFILE ps_Inputs(); }		
   pass P_2   { PixelShader = compile PROFILE ps_RemoteControl(); }
}
