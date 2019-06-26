// @Released 2019-01-06
// @Author schrauber
// @Created 2017-01-31
// @see https://www.lwks.com/media/kunena/attachments/348533/RC_1_Five_channel_remote.png


/**
This is the master controller for the entire remote control user effects subsystem.
It generates the remote control channels 1 to 5 at the one output 
(to which, of course, several effects can be connected).
By itself it does very little, but when used with the appropriate effects it is a very powerful tool.
The desired channel to be used is selected in the custom remote-controllable effect.<br>
 <br>
All channels can be controlled simultaneously by means of a "Master" slider.
As with all adjustable controls, here keyframing can be used.
In turn, that Master can itself be remote controlled.
The "Multiply", parameter allows the master signal to amplify, 
attenuate or invert the individual control channels.
Each channel can be set directly, and the remote control signal may also be limited.
*/


//--------------------------------------------------------------//
// Lightworks user effect  RC1_Five.fx
//
// Update:

// 06 January 2018 by LW user schrauber: 
//    File renamed from "RC1_Remote_control.fx" to "RC1_Five.fx" 
//    Subcategory renamed from "Remote Control" to "Remote control"
//    Option for the future: Measurement option extended: Macro "POSCHANNEL" changed (more channels, such as channel 100)

// 24 June 2018  by LW user schrauber: Compatibility with LWKS 14.5 GPU precision settings
// 24 June 2018  by LW user schrauber: other compatibility improvements
// 26 April 2018 by LW user schrauber: potentially problematic sampler settings removed
//
// Insignificant updates at different times:
// Too long effect name corrected, subcategory defined, effect description
// and other data relevant to the user repository added.
//--------------------------------------------------------------//


int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC 1, Five channel remote"; 
   string Category    = "User"; 
   string SubCategory = "Remote control";  
> = 0;


//-----------------------------------------------------------------------------------------//
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//


texture R1;
sampler remoteImput1 = sampler_state
{
   Texture = <R1>;
   AddressU = Border;
   AddressU = Border;
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
};



texture R2;
sampler remoteImput2 = sampler_state
{
   Texture = <R2>;
   AddressU = Border;
   AddressU = Border;
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
};



texture R3;
sampler remoteImput3 = sampler_state
{
   Texture = <R3>;
   AddressU = Border;
   AddressU = Border;
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
};


texture R4;
sampler remoteImput4 = sampler_state
{
   Texture = <R4>;
   AddressU = Border;
   AddressU = Border;
   MinFilter = Point;
   MagFilter = Point;
   MipFilter = Point;
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



// ---- Receiving from the remote control input -------

#define POSCHANNEL(ch)       float2 ( frac( (floor(ch)-1.0) / 100.0) + 0.005, ((floor( (floor(ch)-1.0) / 100.0))/50.0) + 0.01 )

	
#define DECODE(rcColor)    (( rcColor.r  + ((rcColor.g) / 255.0)) * 2.0 - 1.0 )
   



// ---------- Transmitter,  Position ----------------------


// Position of the signal to be transmitted in the texture.

    //  Option, if channels are to be used over number 100:
    //  #define POSy_CHANNELGROUP_1_0_1  (2 * 0.02)										// Channelgroup 2  (Channel 201 to 300)      Multiplication with 0.02  =  y-Position of the lower edge of the color signal.
    //  #define POS_CHANNELGROUP_1_0_1   (uv0.y > POSy_CHANNELGROUP_1_0_1 && uv0.y < POSy_CHANNELGROUP_1_0_1 + 0.02)		// Channel group for transmission. 0.02 is the y-size of the color signal areas.


   #define POSy_CHANNELGROUP_1_0_1   0.02										// Channelgroup 0  (Channel 001 to 100)
   #define POS_CHANNELGROUP_1_0_1   (uv0.y < POSy_CHANNELGROUP_1_0_1)							// Channel group for transmission. 0.02 is the y-size of the color signal areas.
   #define POSx_CHANNEL1            (uv0.x < 0.01)									// Channel 1,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL2            (uv0.x > 0.01 && uv0.x < 0.02)							// Channel 2,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL3            (uv0.x > 0.02 && uv0.x < 0.03)							// Channel 3,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL4            (uv0.x > 0.03 && uv0.x < 0.04)							// Channel 4,    x - position position and dimensions of the the color signal
   #define POSx_CHANNEL5            (uv0.x > 0.04 && uv0.x < 0.05)							// Channel 5,    x - position position and dimensions of the the color signal
 



// ---------- Transmitter,  Output ----------------------

// "RENDER_1_0_1(Tx)"  Numeral system input -1 to +1, output 0 to 1
//                     Transmits the value of "Tx" as a 16-bit color by using two 8-bit colors ,
//                     and transmits the value of ?Tx? as  a 8-bit color
 #define RENDER_1_0_1(Tx,Status)   return float4 (TRANSMIT(Tx) - BIT9TO16_1_0_1(Tx) / 255 , BIT9TO16_1_0_1(Tx) , Status , TRANSMIT(Tx))		// Return: Red = bit 1 to bit 8 of 16 Bit,     Green (BIT9TO16) = bit 9 to bit 16 of 16 Bit,      Blue = Status, transmitter ON,       Alpha = 8 Bit
    #define BIT9TO16_1_0_1(Tx)        fmod(TRANSMIT(Tx) * 255 , 1)										// Here the color channel for bit 9 to bit 16.
       #define TRANSMIT(Tx)              ((Tx + 1) / 2)												// Adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1)








//-----------------------------------------------------------------------------------------//
// Shaders 
//-----------------------------------------------------------------------------------------//





float4 ps_main (float2 uv0 : TEXCOORD0 , float2 uv1 : TEXCOORD1 , float2 uv2 : TEXCOORD2 , float2 uv3 : TEXCOORD3 , float2 uv4 : TEXCOORD4) : COLOR
{ 

 // Creating a texture containing the remote control channels of all inputs:
 // The following priorities apply when the channels are identical:
 // Primarily: input R1 
         // Then:  input  R2
            // Then:  input  R3
               // Subordinated:  input R4
 
 float4 ret = 0.0.xxxx; 
 if ( tex2D(remoteImput4,uv4).b > 0.0 ) ret = tex2D (remoteImput4,uv4);  // Add the color signal from the remote input 4
 if ( tex2D(remoteImput3,uv3).b > 0.0 ) ret = tex2D (remoteImput3,uv3);  // Add the color signal from the remote input 3
 if ( tex2D(remoteImput2,uv2).b > 0.0 ) ret = tex2D (remoteImput2,uv2);  // Add the color signal from the remote input 2
 if ( tex2D(remoteImput1,uv1).b > 0.0 ) ret = tex2D (remoteImput1,uv1);  // Add the color signal from the remote input 1


 
 // Search the color signal for remote control of this effect:
 float4 masterExt = 0.0.xxxx; 
 if ( tex2D(remoteImput4, POSCHANNEL(ChannelInput) ).b > 0.0 ) masterExt = tex2D (remoteImput4, POSCHANNEL(ChannelInput) );  // Add the color signal from the remote input 4
 if ( tex2D(remoteImput3, POSCHANNEL(ChannelInput) ).b > 0.0 ) masterExt = tex2D (remoteImput3, POSCHANNEL(ChannelInput) );  // Add the color signal from the remote input 3
 if ( tex2D(remoteImput2, POSCHANNEL(ChannelInput) ).b > 0.0 ) masterExt = tex2D (remoteImput2, POSCHANNEL(ChannelInput) );  // Add the color signal from the remote input 2
 if ( tex2D(remoteImput1, POSCHANNEL(ChannelInput) ).b > 0.0 ) masterExt = tex2D (remoteImput1, POSCHANNEL(ChannelInput) );  // Add the color signal from the remote input 1



// .. Add remote control ..

 float Master = MasterInt;
 if ( masterExt.b > 0.39 ) Master = DECODE(masterExt.rg);     //Selects the common master remote control value for all output channels.


 float status1 = 0.4;					 			// Status, transmitter    ,    0.0  = OFF   ,    0.4   = ON   
 float status2 = 0.4;
 float status3 = 0.4;
 float status4 = 0.4;
 float status5 = 0.4;
 

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


 
 if (VALUE_CHANNEL1  != CLAMP_CHANNEL1  || masterExt.b == 1.0) status1 = 1.0;	// Status, transmitter    1.0 = ON and clamped value
 if (VALUE_CHANNEL2  != CLAMP_CHANNEL2  || masterExt.b == 1.0) status2 = 1.0;
 if (VALUE_CHANNEL3  != CLAMP_CHANNEL3  || masterExt.b == 1.0) status3 = 1.0;
 if (VALUE_CHANNEL4  != CLAMP_CHANNEL4  || masterExt.b == 1.0) status4 = 1.0;
 if (VALUE_CHANNEL5  != CLAMP_CHANNEL5  || masterExt.b == 1.0) status5 = 1.0;




 if (POS_CHANNELGROUP_1_0_1)							// Channel group for transmission of values.
 {
    if (POSx_CHANNEL1)     RENDER_1_0_1(CLAMP_CHANNEL1 , status1); 		// Transmission 16 Bit and 8 Bit (and adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1))
    if (POSx_CHANNEL2)     RENDER_1_0_1(CLAMP_CHANNEL2 , status2);
    if (POSx_CHANNEL3)     RENDER_1_0_1(CLAMP_CHANNEL3 , status3);
    if (POSx_CHANNEL4)     RENDER_1_0_1(CLAMP_CHANNEL4 , status4);
    if (POSx_CHANNEL5)     RENDER_1_0_1(CLAMP_CHANNEL5 , status5);
 }

 return ret;
  
				
}





//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//


technique tech_main
{
   pass P_1   { PixelShader = compile PROFILE ps_main(); }		
}
