// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC Zoom plus";                // The title
   string Category    = "Remote Control Distortion";   // Governs the category that the effect appears in in Lightworks
> = 0;




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




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



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Inputs       Samplers
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

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

sampler FgSamplerBorder = sampler_state
{
   Texture = <Input>;
   AddressU = Border;
   AddressV = Border;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};


texture RC;
sampler RcSampler = sampler_state
{
   Texture = <RC>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
};



///////////////////////////////////////////////
// Definitions  ,  declarations  , makro           //
///////////////////////////////////////////////

float _OutputAspectRatio;
	

#define AREA1       RECEIVING(ChArea)
#define AREA        (200-AREA1*201)

#define X_CENTRE    RECEIVING_0_1(ChXcentre)
#define Y_CENTRE    (1 - RECEIVING_0_1(ChYcentre))



// ---- Receiving from the remote control input -------

#define RECEIVING(Ch)       ( RECEIVING_COLOR(Ch) * 2 - step( 0.001 , STATUS_CH_IN(Ch) ) ) 			// Receiving,  numeral system (-1 ... +1) ,   Default value 0.0   ,  "Step" prevents a change in the received Default value if the channel can not be received.  If Status Channel > 0.001 then the calculation:   RECEIVING_COLOR * 2 - 1   ,     If the blue-status = 0.0 then the calculation:   RECEIVING_COLOR * 2 - 0 
#define RECEIVING_0_1(Ch)   ( RECEIVING_COLOR(Ch) + step( STATUS_CH_IN(Ch) , 0.001 ) / 2 ) 			// Receiving,  numeral system  ( 0 ... 1) ,   Default value 0.5   ,  "Step" prevents a change in the received Default value if the channel can not be received.  If Status Channel > 0.001 then the calculation:   RECEIVING_COLOR + 1/2     ,     If the blue-status = 0.0 then the calculation:   RECEIVING_COLOR + 0/2 

   #define RECEIVING_COLOR(Ch)    (  tex2D(RcSampler, POSCHANNEL(floor(Ch))  ).r				/* Receiving  Red = bit 1 to bit 8 of 16Bit     ,   The value of  "Ch" (receiving channel) is only passed to sub macros  */\
                                 + ((tex2D(RcSampler, POSCHANNEL(floor(Ch))).g) / 255) )			/* Green = bit 9 to bit 16   */

      #define STATUS_CH_IN(Ch)     ((tex2D(RcSampler, POSCHANNEL(floor(Ch)))).b)				// Status of the receiving channel ,   blue 0.0  = OFF   ,    0.2 = only Data  ,   0.4   = ON  ,   1.0 = ON and the value of the remote control signal was limited by the sending effect.   ,    The value of ChannelInput is only passed to sub macros 

         // Position of the Channel
         #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )		// Sub macro,   Position of the pixel to be converted.  (  - 0.005 and  + 0.01 ar the center of the respective position)    ,   "ch" is the receiving channel. 
            #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )					// Sub macro,   y - position of the the color signal.    50 channel groups    ,     "ch" is the receiving channel. 
 





//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//--------------------------------------------------------------


float4 zoom (float2 xy : TEXCOORD1) : COLOR
{
 float2 xydist = float2 (X_CENTRE, Y_CENTRE) - xy; 				// XY Distance between the current position to the adjusted effect centering
 float distance = length (float2 (xydist.x, xydist.y / _OutputAspectRatio)); 	// Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
 										// Macro, Pick up the rendered variable ( "strengthCycle" (-1 to +1) , 16-bit color by using two 8-bit colors)
 float zoom = RECEIVING(ChZoom);						// Receiving from the remote control input
 float distortion = (distance * ((distance * AREA) + 1.0) + 1);			// Creates the distortion
 if (AREA1 != 1) zoom = zoom / max( distortion, 0.1 ); 				// If the area = 1, then normal zoom works. Otherwise, a local zoom is active.   "0.1" prevents a division by zero 

 if (!Flip_edge) return tex2D (FgSamplerBorder, zoom * xydist + xy);
 return tex2D (FgSampler, zoom * xydist + xy); 

} 



//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE zoom();
   }
}

