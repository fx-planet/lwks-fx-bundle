// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect
//
// 2017, Users "schrauber"
//
//
// Update: 18 February 2017 by "Schrauber"
//        - Status level of the blue transmission channel updated (standardization with the other remote control effects).
//
// Update 23 October 2017 by "Schrauber"
// Corrected typing errors in line 348,  #define  POS_WAVE (Data reception of the waveform)
// Sampler Y offset was changed from 0.001 to 0.01 to use the center of color-coded data transmission.
//
//
//
//
//
//
//




/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Name and category of the effect
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Settings Display Unit";       // The title
   string Category    = "Remote Control";              // Lightworks 12.6: The Category    ,    Lightworks 14:  The sub-category in the main category "User" 
> = 0;





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Inputs       Samplers
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



texture Input;
sampler InputSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
};



texture RC;
sampler remoteImput = sampler_state
{
   Texture = <RC>;
   AddressU = Border;					// Border is important for the split screen to turn off when searching for a pixel location outside the texture.
   AddressV = Border;					// Border is important for the split screen to turn off when searching for a pixel location outside the texture.
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
};





//.... Rendered cycle graph (raw version)
texture RenderGraphic : RenderColorTarget;
sampler GraphicSampler = sampler_state
{
   Texture = <RenderGraphic>;
   AddressU = Wrap;
   AddressV = Wrap;
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
};







//.... Rendered cycle graph step 2 & step 3
texture RenderGraphic2 : RenderColorTarget;
sampler Graphic2Sampler = sampler_state
{
   Texture = <RenderGraphic2>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};






texture RenderMultiBarGraph : RenderColorTarget;
sampler MultiBarGraph = sampler_state
{
   Texture = <RenderMultiBarGraph>;
   AddressU = Border;					
   AddressV = Border;					
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};










///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



int ChannelCyclic
<
   string Description = "Channel of cyclic linechart";
   string Enum = "3001,3011,3021,3031,3041,3051,3061,3071,3081,3091";
> = 0;




float Channel1Bar
<
   string Group = "Channel selection for the bar graph";
   string Description = "Channel,bar,left";
   float MinVal = 1;
   float MaxVal = 500;
> = 1;

float4 ColorBar1
<
   string Group = "Channel selection for the bar graph";
   string Description = "  Color,bar,left";
> = { 0.0, 0.0, 1.0, 1.0 };





float Channel2Bar
<
   string Group = "Channel selection for the bar graph";
   string Description = "Channel, bar";
   float MinVal = 1;
   float MaxVal = 500;
> = 2;


float4 ColorBar2
<
   string Group = "Channel selection for the bar graph";
   string Description = "   Color, bar";
> = { 0.0, 0.8, 0.0, 1.0 };






float Channel3Bar
<
   string Group = "Channel selection for the bar graph";
   string Description = "Channel bar";
   float MinVal = 1;
   float MaxVal = 500;
> = 3;

float4 ColorBar3
<
   string Group = "Channel selection for the bar graph";
   string Description = "   Color, bar";
> = { 0.9, 0.6, 0.0, 1.0 };




float Channel4Bar
<
   string Group = "Channel selection for the bar graph";
   string Description = "Channel, bar";
   float MinVal = 1;
   float MaxVal = 500;
> = 4;

float4 ColorBar4
<
   string Group = "Channel selection for the bar graph";
   string Description = "   Color, bar";
> = { 0.0, 0.6, 1.0, 1.0 };



float Channel5Bar
<
   string Group = "Channel selection for the bar graph";
   string Description = "Channel, bar";
   float MinVal = 1;
   float MaxVal = 500;
> = 5;

float4 ColorBar5
<
   string Group = "Channel selection for the bar graph";
   string Description = "   Color, bar";
> = { 1.0, 0.5, 0.9, 1.0 };





float GraphicScaling
<
   string Group = "Split screen";
   string Description = "Size";
   float MinVal = 0.05;
   float MaxVal = 1.0;
> = 0.2;

int SetTechnique
<
   string Group = "Split screen";
   string Description = " ";
   string Enum = "Editing:   Full functionality,Bar graph has priority (if split screen >50%),Cyclic line chart has priority (if split screen >50%),Only bar graph & video (reduced GPU load),Only line chart & progress bar & video (reduced GPU load),Export:   Only the video input is output.";
> = 0;

             



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//					|   
//                                      |       
//                                      |       To get an overview of the program structure, first look at the "Technique" section, which pixel shaders are executed.
//                                      |       Then look at the Pixelhader. 
//                                      |       The following macros are used by the Pixel Shader, or by other macros, which are also used by the Pixel shader.
//                                      |
//                                      |
//            Definitions               |                 Most of the macros used here are written in one line.
//                                      |                 In part, these macros also use macros from other lines.
//                                      |
//          and declarations            |       A few macros use several consecutive lines.  Note for multi-line macros:
//            		 	 	|       Apart from the last macro line, the end of the line must be completed with backslash \
//                                      |       After backslach, the line must actually be terminated (no subsequent comments, no blank spaces, etc.).
//                                      |       Before the backslash, comments can only be entered if these are    /* enclosed in comment delimiters, so that backslash is not interpreted as a comment. */\
//                                      |	The single-line comment delimiter //  can only be used for the last macro line.
//                                      |           
//                                      |	If a macro contains an error, the compiler error message often does not display the relevant macro line, but instead the line in the calling shader.
//                                      |
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;	
float _Progress;



// ---------------------------------------------------------------------------
// ... Preprocessor, macros:


// These values are compared with the measured values of the blue color channels.:
#define STATUS_OFF        0.0													// Status, Channel OFF  
#define STATUS_DATA_ON    0.2 													// Status, Channel  ON ,   Content:  Data,                      Data for the "Settings Display Unit" 
#define STATUS_RC_ON      0.4 													// Status, Channel  ON ,   Content:  Remote control,
#define STATUS_RC_CLAMP   1.0  													// Status, Channel  ON ,   Content:  limited remote control,    The value of the remote control signal was limited by a remote controls.


// Receiving from the remote control input:

 
	
      #define MULTIBAR(ch)  (    (   tex2D(remoteImput, POSCHANNEL(floor(ch))).r						/* Receiving  Red = bit 1 to bit 8 of 16Bit     ,   The value of  "ch" is the receiving channel (only passed to sub macros)  */\
                                 + ((tex2D(remoteImput, POSCHANNEL(floor(ch))).g) / 255)					/* Green = bit 9 to bit 16   */\
                                 )  - 0.5   )											/* adjustment of the numeral system from  ( 0 ... 1) to (-0.5 ... +0.5)     */

     #define STATUS(ch)     ((tex2D(remoteImput, POSCHANNEL(floor(ch)))).b)							// Status, transmitter,  (The status is sent on the blue color.)


      // Position of the Channel
         #define POSCHANNEL(ch)       float2 ( frac(ch / 100.0) - 0.005  ,  POSyCHANNEL(ch) + 0.01 )				// Used by MULTIBAR  ,   Receiver:  Position of the pixel to be converted.  (  - 0.005 and  + 0.01 ar the center of the respective position)    ,   "ch" is the receiving channel. 
            #define POSyCHANNEL(ch)        ( (floor( ch/100.0) )/ 50.0 )						  	// Used by POSCHANNEL   ,  Receiver:  y - position of the the color signal.    50 channel groups    ,     "ch" is the receiving channel. 

   



// Receiving data from a external CYCLIC Remote controller:
 
   


   // Position of the cyclic chart channels
      #define CHANNEL_GROUP_SUB30  (ChannelCyclic * 10)										// Calculation basis for the x-position.   Sub-channel group within the channel group 30. The channel group 30 (100 channels) is divided into 10 subgroups.    Subgroup 0 = Channel 3001 to 3010,     Subgroup 10 = Channel 3011 to 3020, Subgroup 20 = Channel 3021 to 3030, etc.
      #define POSyCHANNEL30XX      (30 * 0.02 + 0.01)										// Y-position.   Channelgroup 30  (Channel 3001 to 3100),    Multiplication with 0.02  =  y-Position of the upper edge of the color signal.     0.01 is the y-center of the transmitted color point.
      #define POS_CHANNEL(ch)      float2 ( ((ch+CHANNEL_GROUP_SUB30) / 100.0) - 0.005, POSyCHANNEL30XX )			// 2D-position of the color signal.       "ch" = last digit of the channel number.       "CHANNEL_GROUP_SUB30" is one of 10 subgroups of channel group 30.        100 is the total number of channels per line (channelgroup).       0.005 is the x-center of the transmitted color point.



   // Status of the receiving channel
      #define STATUS_CYCLIC_CHANNEL  ( (tex2D(remoteImput,POS_CHANNEL(2)).b) == STATUS_DATA_ON)

  
   //Receiving and assigning 
      #define STRENGHT_CYCLE1    (tex2D(remoteImput,POS_CHANNEL(1)).r + ((tex2D(remoteImput,POS_CHANNEL(1)).g) / 255))		// 16Bit Channel 3001, The current value of the remote control signal.    Numeral system 0 to 1       Red = bit 1 to bit 8     Green = bit 9 to bit 16
         #define STRENGHT_CYCLE2 (STRENGHT_CYCLE1 * 2 - 1)									// Adjustment of the numeral system from  ( 0 ... 1) to (-1 ... +1)
      #define PROGRESS_CYCLE     (tex2D(remoteImput,POS_CHANNEL(2)).r + ((tex2D(remoteImput,POS_CHANNEL(2)).g) / 255))		// 16Bit Channel 3002, The current position in the cycle,        Red = bit 1 to bit 8     Green = bit 9 to bit 16
      #define TIME_CYCLE_FRAME   (tex2D(remoteImput,POS_CHANNEL(3)).r + ((tex2D(remoteImput,POS_CHANNEL(3)).g) / 255))		// 16Bit Channel 3003,  Cycle Time between the beginning and the end of the same frame. Timebase expressed in 0 to 1, within the current cycle. 
      #define PROGRESS           (tex2D(remoteImput,POS_CHANNEL(4)).r + ((tex2D(remoteImput,POS_CHANNEL(4)).g) / 255))		// 16Bit Channel 3004,  Effect progress      
      #define START              (tex2D(remoteImput,POS_CHANNEL(5)).r + ((tex2D(remoteImput,POS_CHANNEL(5)).g) / 255))		// 16Bit Channel 3005,  Delayed start of the effect   

      #define ERROR_FRAC         ( (tex2D(remoteImput,POS_CHANNEL(7)).r)  > 0.0 )						// Boolean  Channel 3007red,    It is checked whether "Total frames" contains a fractional part.                   (false = on or after start time, true = before start time)
      #define ERROR_PROGRESS     ( (tex2D(remoteImput,POS_CHANNEL(7)).g)  > 0.0 )						// Boolean  Channel 3007green,  It is checked whether the two progress variables differ.                           (false = on or after start time, true = before start time)
      #define ERROR_FRAMES_TOTAL ( (tex2D(remoteImput,POS_CHANNEL(7)).a)  > 0.0 )						// Boolean  Channel 3007alpha,  It is checked whether the adjusted effect length is too high.                      (false = on or after start time, true = before start time)
      #define BEFORE_START       ( (tex2D(remoteImput,POS_CHANNEL(8)).r)  > 0.0 )						// Boolean  Channel 3008red,    It is checked whether the playhead is before a possibly set delayed start time.    (false = on or after start time, true = before start time)
      #define ERROR_INTERVAL     ( (tex2D(remoteImput,POS_CHANNEL(8)).g)  > 0.0 )						// Boolean  Channel 3008green,  It is checked whether the set interval length is sufficient.                       (false = on or after start time, true = before start time)




   // Receiving the wave amplitude values for the graph. (16-bit color by using two 8-bit colors (numeral system 0 to 1)
      #define  CHANNELGROUP_WAVE   ( (ChannelCyclic * 10)/10.0 +31 )									//  Max 10 chanelgroups: 31 , 32 , 33, 34, 35, 36, 37, 38, 39, 40        For example: Channel 3001 =  also uses chanelgroup 31 for the waveform (occupies Remote control channel 3101 to 3200, and for other data channel 3001 to 3010 )
      #define  POS_WAVE            float2 (xy.x ,(CHANNELGROUP_WAVE/100.0) * 2 + 0.01)							// Position and dimensions of the color signal.        (CHANNELGROUP_WAVE/100.0) * 2  =  y-Position of the upper edge of the color signal.       0.01 is the horizontal center of the respective horizontal line.
      #define  RECEIVING_WAVE1A    (tex2D(remoteImput,POS_WAVE).r + ((tex2D(remoteImput,POS_WAVE).g) / 255))				// 16Bit Receiving the wave amplitude values for the graph.   Numeral system 0 to 1       Red = bit 1 to bit 8     Green = bit 9 to bit 16 
      #define  RECEIVING_WAVE1     (RECEIVING_WAVE1A * 2 - 1)										// Adjustment of the numeral system from  ( 0 ... 1) to (-1 ... +1)




#define STARTOK    (!BEFORE_START) 								// It is checked whether the playhead is on or after a possibly set start time.




// --- Other preprocessor, macros ----------------------------------------------
#define Y                    (1-xy.y)								// Conversion of Y coordinate direction: xy.y = top 0, bottom 1   converted to    Y = bottom 0, top 1		
#define XY                   float2 (xy.x , 1-xy.y)						// Conversion of Y coordinate direction: xy.y = top 0, bottom 1   converted to    Y = bottom 0, top 1
#define XSTEP                (1 / _OutputWidth)							// Step width (distance) between two horizontal adjacent pixels.
#define YSTEP                (1 / _OutputHeight)						// Step width (distance) between two vertically adjacent pixels.
#define XYDIST_AR(xPos,Ypos) (float2(( ((xPos)-XY.x) * _OutputAspectRatio), (Ypos) - XY.y))	// Float2 distance to the currently processed pixels (defined as float2 distance in X direction and in Y direktion. With a correction which is dependent on the aspect ratio.)  	

#define MAX_FRAME_TOTAL     62400								// Allowed maximum effect length specified in frames. In the first frame progress can remain on the first frame too long. In tests, the critical limits ranged between 62488 and 62503 frames total.  (Side note: "_Progress" generates errors when using export function "use marked section",  and is therefore used only as a cross-check)
#define START_NEXT          tmp									// Start time of the next ramp within a cycle, Temporary recycling of the "tmp" variable for multi-line macros "HALF_WAVE...
#define AREA                (200-Area*201)


#define COLOR_BLACK             float4 (0.0, 0.0,0.0,1.0)
#define COLOR_RED09             float4 (0.9,0.0,0.0,1.0)
#define COLOR_YELLOW            float4 (1.0,1.0,0.0,1.0)
#define COLOR_BACKGROUND10      float4 (0.75,0.83,1.0,1.0)  							// Background color, total progress bar
#define COLOR_BACKGROUND11      float4 (0.6,0.6,1.0,1.0)  							// Background color, total progress bar
#define COLOR_BEFORE_STARTTIME 	0.4										// Background color, when the set start time has not yet been reached.

// Split screen: video / graphics
   #define COLOR_BORDER_ERROR   float4 (1.0,0.0,0.0,1.0)											// Color of the border of the cyclic graphic, if a too short set interval length has been corrected automatically.
   #define BORDER_MIX_X         0.004														// Border X of the cyclical graphic (above)
   #define BORDER_MIX_Y         (BORDER_MIX_X * _OutputAspectRatio)										// Border Y of the cyclical graphic (above) 
   #define HEIGHT_BAR           0.05														// Height of the progress bar       (below) 
  #define BORDER2_MIX_X   ( Y > 0.05  &&  Y < 0.06  &&  !ERROR_FRAMES_TOTAL) || (Y > 0.1  &&  Y < 0.11  &&  ERROR_FRAMES_TOTAL )		// Border X of the progress bar (below.   The positioning depends on whether the maximum permissible total frames are exceeded.





//  "frame maker" in the bar
   #define COLOR_POS       float4 (0.8,0.0,0.0,1.0)				//  The color of the position marker. (red)
   #define COLOR_OUT_POS   float4 (1.0,1.0,0.0,1.0)				//  Bar: The color of the position marker, if this is before the set start time. (yellow)
   #define SKALE_DIAMOND   (min(Y/2, HEIGHT_BAR/2) - max(Y - HEIGHT_BAR/2, 0))	// Defines the width of the diamond. Because the width at the upper and lower end is defined as zero, the diamond size is also limited in the Y axis.
   #define DIAMOND(color) YLINE_TOTAL_IAR(PROGRESS,SKALE_DIAMOND,color);	// Output to the variable "ret", which has previously been declared as a float4 variable by the calling program part.
 


// ----- EXCLAMATION  ( Creates an exclamation mark for warnings.) -----
// Output to the variable "ret", which has previously been declared as a float4 variable by the calling program part.
#define XPOS_EXCLA           0.35 	// x-position of the point of the exclamation mark.
#define YPOS_EXCLA           0.25 	// Y-position of the point of the exclamation mark.
#define RADIUS_EXCLA         0.04	// Radius of the point of the exclamation mark.
#define YPOS_LINE_EXCLA      0.35 	// Lower Y-position of the line of the exclamation mark.
#define WIDTH_LINE_EXCLA     0.02 	// Lower width of the line of the exclamation mark (widens with the distance to the lower Y-position).
#define WIDTH_DYN_LINE_EXCLA 0.12 	// Dynamic width of the line of the exclamation mark (widens with the distance to the lower Y-position).
#define LENGHT_EXCLA         0.45 	// Length of the line of the exclamation mark.
#define COLOR_EXCLA  float4 (1.0,0.8,0.0,1.0)        

     // Multi-line macro "EXCLAMATION1"
        #define EXCLAMATION1 \
         {\
            YLINE_AR(XPOS_EXCLA,   YPOS_LINE_EXCLA,   LENGHT_EXCLA,   WIDTH_LINE_EXCLA +  (Y - YPOS_LINE_EXCLA) * WIDTH_DYN_LINE_EXCLA,  COLOR_EXCLA); 	/* Vertical line of the exclamation mark */\
            if ( length( XYDIST_AR (XPOS_EXCLA ,YPOS_EXCLA )) < RADIUS_EXCLA ) ret = COLOR_EXCLA;   						/* Point of exclamation mark */\
         }


// ...... Deviating, valid only for "EXCLAMATION2":
#define XPOS_EXCLA2            0.5
#define COLOR_EXCLA2           float4 (1.0,0.0,0.0,1.0)   

      // Multi-line macro "EXCLAMATION2"
         #define EXCLAMATION2 \
         {\
            YLINE_AR(XPOS_EXCLA2,   YPOS_LINE_EXCLA,   LENGHT_EXCLA,  WIDTH_LINE_EXCLA +  (Y - YPOS_LINE_EXCLA) * WIDTH_DYN_LINE_EXCLA,   COLOR_EXCLA2); 	/* Vertical line of the exclamation mark */\
            if ( length( XYDIST_AR (XPOS_EXCLA2 ,YPOS_EXCLA )) < RADIUS_EXCLA ) ret = COLOR_EXCLA2;   						/* Point of exclamation mark */\
         }


// ...... Deviating, valid only for "EXCLAMATION3":
#define XPOS_EXCLA3             (0.04/_OutputAspectRatio)
#define YPOS_EXCLA3             0.013 	
#define RADIUS_EXCLA3           0.013	
#define YPOS_LINE_EXCLA3        0.033
#define WIDTH_LINE_EXCLA3       0.003 	
#define WIDTH_DYN_LINE_EXCLA3   0.4 	
#define LENGHT_EXCLA3           0.06
#define COLOR_EXCLA3           float4 (1.0,0.55,0.53,1.0)  

         // Multi-line macro "EXCLAMATION3"
         #define EXCLAMATION3 \
         {\
            YLINE_AR(XPOS_EXCLA3,   YPOS_LINE_EXCLA3,   LENGHT_EXCLA3,   WIDTH_LINE_EXCLA3 +  (Y - YPOS_LINE_EXCLA3) * WIDTH_DYN_LINE_EXCLA3,  COLOR_EXCLA3); 	/* Vertical line of the exclamation mark */\
            if ( length( XYDIST_AR (XPOS_EXCLA3 ,YPOS_EXCLA3 )) < RADIUS_EXCLA3 ) ret = COLOR_EXCLA3;   						/* Point of exclamation mark */\
         }





   




//  Ledger lines
      #define HALF_LINEWIDHT1LL   (3 / _OutputHeight + 0.001)					//  Half line width of the +- 100 % Ledger lines (Used by cyclic graphics )
      #define HALF_LINEWIDHT1BAR  (10 / _OutputHeight + 0.002)					//  Half line width of the +- 100 % Ledger lines (Used by multi-channel bar )
      #define HALF_LINEWIDHT2LL   (0.8 / _OutputHeight + 0.001)					//  Half line width of the +- 50 % Ledger lines  (Used by cyclic graphics )
      #define HALF_LINEWIDHT2BAR  (0.0015 / (pow(GraphicScaling, 1.5) + 0.01))			//  Half line width of the +- 50 % Ledger lines  (Used by multi-channel bar )
      #define HALF_LINEWIDHT10LL  (0.6 / _OutputHeight + 0.0005)				//  Half line width of the +- 10%, 20%, 30% ...  Ledger lines  
      #define HALF_LINEWIDHT20LL   0.0004							//  Half line width of the +- 5%, 10%, 15%, 20% ...  Ledger lines  
      #define HALF_LINEWIDHT100LL  0.0003							//  Half line width of the +- 1%, 2%, 3%, 4%, 5%, 6% ....  Ledger lines  
      #define HALF_LINEWIDHT_FRAME 0.005
      #define COLOR_LEDGERLINEgray  float4 (0.6,0.6,0.6,1.0)
      #define COLOR_LEDGERLINE1     float4 (0.0,0.0,0.0,1.0)
      #define COLOR_LEDGERLINE2     float4 (0.6,0.6,0.6,1.0)
      #define COLOR_LEDGERLINE10    float4 (0.7,0.7,0.7,1.0)
      #define COLOR_LEDGERLINE20    float4 (0.84,0.84,0.84,1.0)
      #define COLOR_LEDGERLINE100   float4 (0.87,0.87,0.87,1.0)






// --- Creating vertical lines -------------------------------------------------
// Output to the variable "ret", which has previously been declared as a float4 variable by the calling program part.		


   // Total line with interpolation of line width:                                                                           Length from bottom to top.   Vertical line with interpolation of the line width (broadening the line by a maximum of 1 interpolated pixel per line outer edge). 
        #define YLINE_TOTAL_IAR(pos,half_Lineweight,color)\
           ret = lerp(\
              (color),\
              ret,\
              saturate( saturate(abs(xy.x - (pos)) - ((half_Lineweight) / _OutputAspectRatio) ) / XSTEP) );             /* The formula part  " abs(X - pos) " means:   Horizontal distance of the currently calculated pixel to the horizontal center of a vertical line.*/




     //Option:  simple vertical line, total
         #define YLINE_TOTAL(xPos,half_Lineweight,color)\
            if (  xy.x == clamp( xy.x , (xPos)-(half_Lineweight) , (xPos)+(half_Lineweight) ))\
                  ret = color;



      // Vertical line,  upwards (positive lenght value)   &  down (negative length value)   
         #define YLINE(xPos,Ypos,length,half_Lineweight,color)\
            if (  xy.x >= (xPos) - (half_Lineweight) \
               && xy.x <= (xPos) + (half_Lineweight) \
               && Y <= ((Ypos)+((length)/2)) + (abs(length)/2)                            /*   ((Ypos)+((length)/2)) is the center of the length */\
               && Y >= ((Ypos)+((length)/2)) - (abs(length)/2) ) \
                  ret = color;

 
     //Option:  Vertical line,  only upwards (positive lenght value)
        #define YLINE_UP(xPos,Ypos,length,half_Lineweight,color)\
            if (  xy.x >= (xPos) - (half_Lineweight) \
               && xy.x <= (xPos) + (half_Lineweight) \
               && Y >= (Ypos) \
               && Y <= (Ypos) + (length)) \
                  ret = color;

     
     // Vertical line,  only down (positive lenght value)
         #define YLINE_DOWN(xPos,Ypos,length,half_Lineweight,color)\
            if (  xy.x >= (xPos) - (half_Lineweight) \
               && xy.x <= (xPos) + (half_Lineweight) \
               && Y <= (Ypos) \
               && Y >= (Ypos) - (length)) \
                  ret = color;






   //-- Lines with a correction which is dependent on the aspect ratio "AR". 

         #define YLINE_AR(xPos,Ypos,length,half_Lineweight,color)\
            if (  xy.x >= (xPos) - (half_Lineweight)/_OutputAspectRatio \
               && xy.x <= (xPos) + (half_Lineweight)/_OutputAspectRatio \
               && Y >= (Ypos) \
               && Y <= (Ypos) + (length)) \
                  ret = color;


     // Option, currently not in use:
     // Line with interpolation of line width:                                                                            Vertical line with interpolation of the line width (broadening the line by a maximum of 1 interpolated pixel per line outer edge).
       #define YLINE_IAR(xPos,Ypos,length,half_Lineweight,color)\
          if( Y >= (Ypos) \
              && Y <= (Ypos) + (length) ) \
                 ret = lerp(\
                    (color),\
                    ret,\
                    saturate( saturate(abs(xy.x - (xPos)) - ((half_Lineweight) / _OutputAspectRatio) ) / XSTEP) );      /* The formula part  " abs(X - pos) " means:   Horizontal distance of the currently calculated pixel to the horizontal center of a vertical line.*/







 



// --- Creating horizontal lines -------------------------------------------------
// Output to the variable "ret", which has previously been declared as a float4 variable by the calling program part.


   // ... Creates horizontal line,  Scale 100% ...
							
      #define XLINE_TOTAL2(pos,half_Lineweight,color)                   ret = lerp (color, ret,  saturate( saturate(YGAP2LINECENTER2(pos) - half_Lineweight) / YSTEP) );		// Horizontal lines with interpolation of the line width (broadening the line by a maximum of 1 interpolated pixel per top and bottom edge).   "pos" refers to Y-distance from the zero line (+1 = 100 %  ,  -1 = -100%)
         #define YGAP2LINECENTER2(pos)                                    abs( Y - (pos * 0.5  + POS_GRAPH_CYCLE) )  										// For use in XLINE_TOTAL2 .   Vertical distance of the currently calculated pixel to the vertical center of a horizontal line.

      #define XMULTILINES_TOTAL2(lines,half_Lineweight,color) 	ret = lerp (color, ret, saturate( saturate(YGAP3LINECENTER2(POS_XMULTILINES2(lines)) - half_Lineweight) / YSTEP) );	// Creates several horizontal lines (with interpolation of the line width) at the same distance from each other. 
         #define POS_XMULTILINES2(lines)                                    (round((Y * 2) * lines)  / lines )											// Horizontal Multiple Lines ( For use in XMULTILINES_TOTAL2 ): Position of the line that is at the position of the currently calculated pixel.
            #define YGAP3LINECENTER2(pos)                                      abs(Y - (pos * POS_GRAPH_CYCLE) )											// For use in XMULTILINES_TOTAL2.   Vertical distance of the currently calculated pixel to the vertical center of a horizontal line.


   // ... Creates horizontal line,  Y-Scale to "SCALE_GRAPH_CYCLE" ...							
 
        #define XLINE_TOTAL(pos,half_Lineweight,color)              ret = lerp (color, ret,  saturate( saturate(YGAP2LINECENTER(pos) - half_Lineweight) / YSTEP) );				// Horizontal lines with interpolation of the line width (broadening the line by a maximum of 1 interpolated pixel per top and bottom edge).     "pos" refers to Y-distance from the zero line (+1 = 100 % of "SCALE_GRAPH_CYCLE"  ,  -1 = -100% of "SCALE_GRAPH_CYCLE" )
           #define YGAP2LINECENTER(pos)                                abs( Y - (pos * HIGHT05_GRAPH_CYCLE  + POS_GRAPH_CYCLE) )  														// For use in XLINE_TOTAL .   Vertical distance of the currently calculated pixel to the vertical center of a horizontal line.   The part of the formula: (pos * HIGHT05_GRAPH_CYCLE + POS_GRAPH_CYCLE)  adjusted the range (- 1 to +1) to the the zero line, and the internal Y scale of the graph (hight 0.05 to 0.95). External scaling (e.g., after rendering) is disregarded. 
 
        #define XMULTILINES_TOTAL(lines,half_Lineweight,color)      ret = lerp (color, ret, saturate( saturate(YGAP3LINECENTER(POS_XMULTILINES(lines)) - half_Lineweight) / YSTEP) );		// Creates several horizontal lines (with interpolation of the line width) at the same distance from each other. 
           #define POS_XMULTILINES(lines)                              (round(((Y - OUT_YSCALE) *2) * (lines / SCALE_GRAPH_CYCLE))  / (lines / SCALE_GRAPH_CYCLE))						// Horizontal Multiple Lines ( For use in XMULTILINES_TOTAL ): Position of the line that is at the position of the currently calculated pixel.
           #define YGAP3LINECENTER(pos)                                abs(Y - (pos * POS_GRAPH_CYCLE + OUT_YSCALE) )												// For use in XMULTILINES_TOTAL.   Vertical distance of the currently calculated pixel to the vertical center of a horizontal line.
 








   // ---- Creating diagonal lines -----------------------------------------------

      // Diagonal line, total ,  from bottom left to top right
         #define DIAGONAL_LINE_TOTAL1(half_Lineweight,color)\
           if (  xy.x == clamp( xy.x , Y-(half_Lineweight) , Y+(half_Lineweight) ))\
                  ret = color;

      // Diagonal line, total , from top right to top right
         #define DIAGONAL_LINE_TOTAL2(half_Lineweight,color)\
           if (  xy.x == clamp( xy.x , (1.0-Y)-(half_Lineweight) , (1.0-Y)+(half_Lineweight) ))\
                  ret = color;


      // Diagonal line, total , adjustable
      // xPos = Bottom position of the diagonal line on the x-axis
      // tilt: Shift of the top position of the line on the x-axis  (Without compensation of the aspect ratio)  ,   Example: 0.2 = 20% of the screen width
         #define DIAGONAL_LINE_TOTAL3(xPos,half_Lineweight,tilt,color)\
           if (  xy.x == clamp( xy.x , ((xPos)+Y*(tilt))-(half_Lineweight) , ((xPos)+Y*(tilt))+(half_Lineweight) ))\
                  ret = color;











// ......................................................................................
// .............. Only for multi-channel bar graph on top
// ......................................................................................

 #define COLOR_BACKGROUND_MULTIBAR  float4 (0.9,0.9,1.0,1.0) 
 #define COLOR_GRAY07          0.7
 #define OFFSET_CH_SET         4.99999999E-3           					// Offset channel setting tolerance.    Measure, because invisible fractional parts of the setting value of the slider are rounded if necessary.      Example no. 1:    If 1102.9955 was accidentally set, then 1103.00 is displayed on slider but 1102.9955 used. The addition of 0.0049 yields 1103.0004, of which the integer part gives the channel 1103.
 #define CH_SET_TOL            0.4 	         					// Channel setting tolerance (from 0.0 to +0.4).   No negative tolerance (apart from offset).    If the fractional part is larger than the channel setting tolerance + offset, the corresponding bar is not displayed (gray column background).
 #define CHANNEL1BAR           Channel1Bar + OFFSET_CH_SET				//  Example no. 2:    If 1100.998 was accidentally set, then 1101.00 is displayed on slider but 1100.998 used. The addition of 0.0049 yields 1101.0029, of which the integer part gives the channel 1101.
 #define CHANNEL2BAR           Channel2Bar + OFFSET_CH_SET				//  Example no. 3:    If 1101.995 was accidentally set, then 1101.99 is displayed on slider but 1101.995 used. The addition of 0.0049 yields 1101.9999. Because the fractional part (.9999) is larger than the channel setting tolerance (0.4), the bar is not displayed (gray column background).
 #define CHANNEL3BAR           Channel3Bar + OFFSET_CH_SET
 #define CHANNEL4BAR           Channel4Bar + OFFSET_CH_SET
 #define CHANNEL5BAR           Channel5Bar + OFFSET_CH_SET








// ......................................................................................................................................................................
// .......   Only for cyclic graphics:  
// ......................................................................................................................................................................


   #define COLOR1_CURVE float4       (0.6,0.85,0.6,1.0) 					// Fill color for positive components in the curve profile. In case of changes, please note: These colors are evaluated and compared to create some lines in the graphic no. 2.
   #define COLOR2_CURVE float4       (0.9,0.65,0.65,1.0)					// Fill color for negaitive components in the curve profile. In case of changes, please note: These colors are evaluated and compared to create some lines in the graphic no. 2. 
   #define COLOR_BACKGROUND1 float4  (0.9,0.9,1.0,1.0)						// Background color
   #define COLOR_BACKGROUND3 float4  (1.0,1.0,1.0,1.0)						// Background color ,  top and bottom of the graphic (limiting the control signal)
   #define COLOR_ERROR_BACKGROUND1   0.3							// Background color in case of a detected error.
   #define SCALE_GRAPH_CYCLE         0.95							// Scale of the graph. External scaling (e.g., after rendering) is disregarded.. 
   #define OUT_YSCALE                (1 - SCALE_GRAPH_CYCLE) / 2				// Width of the gray lines (top and bottom), which identifies the graphics area, located outside the allowable Y scaling.
   #define HIGHT05_GRAPH_CYCLE       (SCALE_GRAPH_CYCLE * 0.5)					// The height measured by the zero line. 
   #define POS_GRAPH_CYCLE           0.5							// The Y position of the zero line. 
   #define STRENGTH_GRAPHIC_SCALED   (POS_GRAPH_CYCLE + RECEIVING_WAVE1 * HIGHT05_GRAPH_CYCLE)	// The Range (- 1 to +1) of "RECEIVING_WAVE" is adjusted to the the zero line, and the internal Y scale of the graph (hight 0.05 to 0.95). External scaling (e.g., after rendering) is disregarded.
   #define IMPRECISION_8BIT          0.002							// When entering floating-point color values (0 to 1), these are output as integer 8-bit color values (0 to 255). From this it follows a maximum deviation of 0.5 * (1/255).

   // "frame maker" = "playhead"
      #define COLOR_POS             float4 (0.8,0.0,0.0,1.0)									//  The color of the position marker. (red)
      #define COLOR_FRAME           float4 (0.8,0.0,0.0,1.0)									//  The color of the red symbolized frame (at the bottom of the chart).
      #define LINEWIDHT_FRAME       0.01											//  The linewidth of the red symbolized frame (at the bottom of the chart).
      #define LINEWIDHT_POS         (0.004 / (pow(GraphicScaling, 1.5) + 0.02))							//  Linewidht of the red position marker.
      #define HALF_LINEWIDHT_POS    ( LINEWIDHT_POS / 2)									//  Only for cyclic graphics.
      #define LEFT_LINEWIDHT_POS    ( PROGRESS_CYCLE - HALF_LINEWIDHT_POS/_OutputAspectRatio )					//  Position of the left edge of the line that symbolizes the playhead.
      #define RIGHT_LINEWIDHT_POS   ( PROGRESS_CYCLE + \
                                    ((HALF_LINEWIDHT_POS + max(LINEWIDHT_POS - PROGRESS_CYCLE, 0) ) /_OutputAspectRatio) )	//  Position of the right edge of the line that symbolizes the playhead.   If the playhead is at the right edge, then actually only the half line width would be visible, because the other half is outside the display. For better visibility, the right side of the line is only widened when the playhead is close to the left edge of the display.

      // " PLAYHEAD "  Create the vertical line that symbolizes the playhead,
      // with interpolation and a correction which is dependent on the aspect ratio. 
         #define PLAYHEAD \
            if ( xy.x > PROGRESS_CYCLE)\
            {\
               ret = lerp( COLOR_POS, ret,  saturate( (xy.x - RIGHT_LINEWIDHT_POS) / XSTEP) );		/* Length from bottom to top. */\
            }else{\
               ret = lerp( COLOR_POS, ret,  saturate( (LEFT_LINEWIDHT_POS - xy.x) / XSTEP) );		/* Length from bottom to top. */\
            }



   //  Amplitude marker,  the strength of the effect for the current frame
      #define COLOR_AMPLITUDE float4 (0.0,0.0,1.0,1.0)						//  The color of the Amplitude marker.
      #define HALF_LINEWIDHT_STRENGTH (0.001 / (pow(GraphicScaling, 1.5) + 0.01))		//  HALF line of the Amplitude marker.


   //  Chart line in the graphic.
      #define COLOR3_CURVE float4 (0.0,0.5,0.0,1.0)					//  Line color for positive components in the curve profile.
      #define COLOR4_CURVE float4 (0.7,0.0,0.0,1.0)					//  Line color for negaitive components in the curve profile. 
      #define LINEWIDHT_CURVE_DX (0.001 / (GraphicScaling + 0.01))			//  X-positioning: Linewidth for diagonale components of the chart. 
      #define LINEWIDHT_CURVE_DY (LINEWIDHT_CURVE_DX * _OutputAspectRatio)		//  Y-positioning: Linewidth for diagonale components of the chart.

      //  Chart line in the graphic. Analysis of rendered raw graph with black background. The color in the vicinity of the current pixel:
         #define REF_PIXEL_GREEN_BELOW_RIGHT tex2D(GraphicSampler, float2 (xy.x + LINEWIDHT_CURVE_DX , xy.y + LINEWIDHT_CURVE_DY)).g		/* The green reference pixel is located below the current pixel, the direction right. Distance is the line width.*/
         #define REF_PIXEL_GREEN_BELOW_LEFT tex2D(GraphicSampler, float2 (xy.x - LINEWIDHT_CURVE_DX , xy.y + LINEWIDHT_CURVE_DY)).g		/* The green reference pixel is located below the current pixel, the direction left. Distance is the line width.*/		
         #define REF_PIXEL_GREEN_ABOVE_RIGHT tex2D(GraphicSampler, float2 (xy.x + LINEWIDHT_CURVE_DX , xy.y - LINEWIDHT_CURVE_DY)).g		/* The green reference pixel is located above the current pixel, the direction right. Distance is the line width. */
         #define REF_PIXEL_GREEN_ABOVE_LEFT tex2D(GraphicSampler, float2 (xy.x - LINEWIDHT_CURVE_DX , xy.y - LINEWIDHT_CURVE_DY)).g		/* The green reference pixel is located above the current pixel, the direction left. Distance is the line width. */
         #define REF_PIXEL_RED_BELOW_RIGHT tex2D(GraphicSampler, float2 (xy.x + LINEWIDHT_CURVE_DX , xy.y - LINEWIDHT_CURVE_DY)).r		/* The red reference pixel is located below the current pixel, the direction right. Distance is the line width.*/
         #define REF_PIXEL_RED_BELOW_LEFT tex2D(GraphicSampler, float2 (xy.x - LINEWIDHT_CURVE_DX , xy.y - LINEWIDHT_CURVE_DY)).r		/* The red reference pixel is located below the current pixel, the direction left. Distance is the line width.*/
         #define REF_PIXEL_RED_ABOVE_RIGHT tex2D(GraphicSampler, float2 (xy.x + LINEWIDHT_CURVE_DX , xy.y + LINEWIDHT_CURVE_DY)).r		/* The red reference pixel is located above the current pixel, the direction right. Distance is the line width. */
         #define REF_PIXEL_RED_ABOVE_LEFT tex2D(GraphicSampler, float2 (xy.x - LINEWIDHT_CURVE_DX , xy.y + LINEWIDHT_CURVE_DY)).r		/* The red reference pixel is located above the current pixel, the direction left. Distance is the line width. */





  


















/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//               *****  Pixel Shader  *****
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// These functions are used by "Technique"
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




//////////////////////////////////////////////////////
// ------ First the internally rendering pixel shaders:
//////////////////////////////////////////////////////



// --------------  Render , cyclic graphics, the raw version of the , processing step 1  -------------------------

// *** Please note when changing the program: 
// *** Because the graphic2 is formed from this raw graphic,
// *** changes in this graphic shader can affect the graphic2. 

float4 cyclicGraphicStep1 (float2 xy : TEXCOORD2) : COLOR		
{ 

  // Output: render cycle graph (raw version)
  // Please note that these colors are evaluated elsewhere in order to create the graphic step2.
     if (STRENGTH_GRAPHIC_SCALED > Y && Y > POS_GRAPH_CYCLE - LINEWIDHT_CURVE_DY) return COLOR1_CURVE;
     if (STRENGTH_GRAPHIC_SCALED < Y && Y < POS_GRAPH_CYCLE ) return COLOR2_CURVE;
   
        return 0;										// In case of changes, please note: This background color is evaluated elsewhere to create the graphic2.
} 




// --------------  Render,   cyclic,  processing step 2  -------------------------

float4 cyclicGraphicStep2 (float2 xy : TEXCOORD2) : COLOR		
{ 
   precise float4 ret = tex2D(GraphicSampler, xy);							// Holt the pixel from the buffered graphic. 
   if (ret.a == 0) 
   {
      ret = COLOR_BACKGROUND1;
         
      if (GraphicScaling > 0.8)
      {
         XMULTILINES_TOTAL (100,HALF_LINEWIDHT100LL,COLOR_LEDGERLINE100);				// Horizontal ledger line. 200 horizontal ledger line are displayed,  Creates 100 Lines above und 100 Lines below the zero line. 
         XMULTILINES_TOTAL (20,HALF_LINEWIDHT20LL,COLOR_LEDGERLINE20);					// Horizontal ledger line.  40 horizontal ledger line are displayed,  Creates 20 Lines above und 20 Lines below the zero line. 
      }
      if ( fmod( (xy.x / TIME_CYCLE_FRAME) , 2 ) < 1.0 ) ret = ret - 0.04;				// Correction of the background color, and the color of the fine ledgerlines for every 2nd frame. 
         
      if (GraphicScaling > 0.4)
      {
         XMULTILINES_TOTAL (10,HALF_LINEWIDHT10LL,COLOR_LEDGERLINE10);					// Horizontal ledger line,  Creates 10 Lines above und 10 Lines below the zero line
         XMULTILINES_TOTAL (2,HALF_LINEWIDHT2LL,COLOR_LEDGERLINE2);					// Horizontal ledger line,  Creates 2 Lines above und 2 Lines below the zero line (50% + 100 % , and the zero line)
         XLINE_TOTAL (1.0,HALF_LINEWIDHT1LL,COLOR_LEDGERLINE1);						// Horizontal ledger line (100%) 
         XLINE_TOTAL (-1.0,HALF_LINEWIDHT1LL,COLOR_LEDGERLINE1);					// Horizontal ledger line (-100%) 
      }
         
      if (xy.y < OUT_YSCALE - HALF_LINEWIDHT1LL || Y < OUT_YSCALE - HALF_LINEWIDHT1LL ) ret = COLOR_BACKGROUND3;	// Background color ,  top and bottom of the graphic (limiting the control signal) 
      if ( ERROR_PROGRESS || ERROR_FRAC ) ret = COLOR_ERROR_BACKGROUND1;						// Background color in case of a detected progress error.
   }
      
   // >>>>>                      ............. CURVE .........................					  	 <<<<<
   //   >>>>>      It is checked whether the respective pixel is in the colored or black area of rendered graphics.	 <<<<<
   //   >>>>> If the surrounding area darker or lighter, then a color edge is generated there. This edge is the curve.   <<<<<
   
   // Green, line width of the chart
   if (tex2D(GraphicSampler, xy).g < REF_PIXEL_GREEN_BELOW_RIGHT && REF_PIXEL_GREEN_BELOW_RIGHT > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;
   if (tex2D(GraphicSampler, xy).g < REF_PIXEL_GREEN_BELOW_LEFT && REF_PIXEL_GREEN_BELOW_LEFT > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;
   if (tex2D(GraphicSampler, xy).g > REF_PIXEL_GREEN_ABOVE_RIGHT && tex2D(GraphicSampler, xy).g > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;
   if (tex2D(GraphicSampler, xy).g > REF_PIXEL_GREEN_ABOVE_LEFT && tex2D(GraphicSampler, xy).g > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;
      
   return ret;
} 





// -------------- Render,  cyclic, processing step 3  -------------------------

float4 cyclicGraphicStep3 (float2 xy : TEXCOORD2) : COLOR		
{ 
   precise float4 ret = tex2D(Graphic2Sampler, xy);			// Holt the pixel from the buffered graphic. 
      
 if (!STATUS_CYCLIC_CHANNEL)    					// If no signal is received on the set channel.
    {
       ret = COLOR_ERROR_BACKGROUND1;
       DIAGONAL_LINE_TOTAL1(0.01,COLOR_RED09);
       DIAGONAL_LINE_TOTAL2(0.01,COLOR_RED09);
       return ret;
    }



   // >>>>>                      ............. CURVE .........................					   <<<<<
   //  >>>>>      It is checked whether the respective pixel is in the colored or black area of rendered graphics.	   <<<<<
   // >>>>> If the surrounding area darker or lighter, then a color edge is generated there. This edge is the curve.    <<<<<
   // ...Red,  line width of the chart 
   if (tex2D(GraphicSampler, xy).r < REF_PIXEL_RED_BELOW_RIGHT && REF_PIXEL_RED_BELOW_RIGHT > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;
   if (tex2D(GraphicSampler, xy).r < REF_PIXEL_RED_BELOW_LEFT && REF_PIXEL_RED_BELOW_LEFT > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;
   if (tex2D(GraphicSampler, xy).r > REF_PIXEL_RED_ABOVE_RIGHT && tex2D(GraphicSampler, xy).r > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;
   if (tex2D(GraphicSampler, xy).r > REF_PIXEL_RED_ABOVE_LEFT && tex2D(GraphicSampler, xy).r > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;
      
      
   // ... "frame maker" / "playhead" ... 
   if (STARTOK) 
   {
      PLAYHEAD;																					//  Your position in the cycle. This indicator is disabled when the set start time has not yet been reached   
      if (STARTOK && PROGRESS_CYCLE > xy.x - TIME_CYCLE_FRAME && PROGRESS_CYCLE < xy.x && ( xy.y <  LINEWIDHT_FRAME || Y < LINEWIDHT_FRAME)) ret = COLOR_FRAME;			// Displays the width of the current frame in the diagram. This indicator is disabled when the set start time has not yet been reached. 
   }
      
   // ... Amplitude marker, the strength of the effect for the current frame
   XLINE_TOTAL(STRENGHT_CYCLE2,HALF_LINEWIDHT_STRENGTH,COLOR_AMPLITUDE);
      
   if (BEFORE_START)   ret = ret * 0.5;							// Dimming of the graph if the progress variables differ. 
      
   // .... Error checks and warnings  
   if (ERROR_FRAC)     EXCLAMATION1;							// Display an exclamation point in the graphic, if "Total frames" contains a fractional part. 
   if (ERROR_PROGRESS) EXCLAMATION2;							// Display an exclamation point in the graphic, if "Total frames" contains a fractional part. 
     
   return ret;
} 











// --------------   Render,   multi channel bar graph on top , processing step 1    -----------------------

float4 MultiChannelBarGraphStep1  (float2 xy : TEXCOORD2) : COLOR		
{    
   precise float4 ret = COLOR_BACKGROUND_MULTIBAR;

   if (GraphicScaling > 0.8)
   {
      XMULTILINES_TOTAL2 (100,HALF_LINEWIDHT100LL,COLOR_LEDGERLINE100);					// Horizontal ledger line.   200 horizontal ledger line are displayed,  Creates 100 Lines above und 100 Lines below the zero line.
      XMULTILINES_TOTAL2 (20,HALF_LINEWIDHT20LL,COLOR_LEDGERLINE20);					// Horizontal ledger line.  40 horizontal ledger line are displayed,  Creates 20 Lines above und 20 Lines below the zero line.
   }
 
   if (GraphicScaling > 0.4)
   {
      XMULTILINES_TOTAL2  (10,HALF_LINEWIDHT10LL,COLOR_LEDGERLINE10);					// Horizontal ledger line,  Creates 10 Lines above und 10 Lines below the zero line
      XMULTILINES_TOTAL2  (2,HALF_LINEWIDHT2LL,COLOR_LEDGERLINEgray);					// Horizontal ledger line,  Creates 2 Lines above und 2 Lines below the zero line (50% + 100 %)
      XLINE_TOTAL2        (1.0,HALF_LINEWIDHT1BAR,COLOR_LEDGERLINEgray);				// Horizontal ledger line (100%) 
      XLINE_TOTAL2        (-1.0,HALF_LINEWIDHT1BAR,COLOR_LEDGERLINEgray);				// Horizontal ledger line (-100%) 
   }

   XLINE_TOTAL2    (0.0 ,HALF_LINEWIDHT2BAR,COLOR_LEDGERLINEgray);					// Horizontal ledger line (zero line) 


   return ret;
} 





// --------------  Render,   multi channel bar graph on top , processing step 2    -----------------------

float4 MultiChannelBarGraphStep2  (float2 xy : TEXCOORD2) : COLOR		
{    

 precise float4 ret = tex2D (MultiBarGraph,xy);


 if (xy.x <= 0.2) 										// Position and width of the corresponding column.
 {
    if (     STATUS(CHANNEL1BAR)              <  STATUS_RC_ON					// Status channel,     if  Status < STATUS_RC_ON    Then:  No remote control signal found on the channel, The corresponding bar is not displayed (gray column background).
       ||  CHANNEL1BAR - floor(CHANNEL1BAR)   >   CH_SET_TOL					// Channel setting tolerance (from 0.0 to +0.4).   No negative tolerance (apart from offset).    If the fractional part is larger than the channel setting tolerance + offset, the corresponding bar is not displayed (gray column background).
       ) 
          {
             DIAGONAL_LINE_TOTAL3(0.0,0.01,0.2,COLOR_RED09); 					//In case of error:    DIAGONAL_LINE_TOTAL3(xPos,half_Lineweight,tilt,color)     xPos = Bottom position of the diagonal line on the x-axis
             DIAGONAL_LINE_TOTAL3(0.2,0.01,-0.2,COLOR_RED09);					//                     DIAGONAL_LINE_TOTAL3(xPos,half_Lineweight,tilt,color)     tilt: Shift of the top position of the line on the x-axis     0.2 = 20% of the screen width (without compensation of the aspect ratio) 
             return ret;									//                     Return without displaying the corresponding bar.
          }
    if (STATUS(CHANNEL1BAR)  ==  STATUS_RC_CLAMP) ret = COLOR_YELLOW;				// Background of the column.       Status, Channel,   if STATUS == STATUS_RC_CLAMP   Then: RC ON and the value was limited by a RC. 
 }







 if (xy.x == clamp(xy.x , 0.2 , 0.4 ))
 {
    if (     STATUS(CHANNEL2BAR)              <  STATUS_RC_ON
       ||  CHANNEL2BAR - floor(CHANNEL2BAR)   >   CH_SET_TOL					
       ) 
          {
              DIAGONAL_LINE_TOTAL3(0.2,0.01,0.2,COLOR_RED09); 
              DIAGONAL_LINE_TOTAL3(0.4,0.01,-0.2,COLOR_RED09);
              return ret;
          }
    if (STATUS(CHANNEL2BAR)  ==  STATUS_RC_CLAMP) ret = COLOR_YELLOW;
 }


 if (xy.x == clamp(xy.x , 0.4 , 0.6 ))
 {
    if (     STATUS(CHANNEL3BAR)              <  STATUS_RC_ON
       ||  CHANNEL3BAR - floor(CHANNEL3BAR)   >   CH_SET_TOL	
       ) 
          {
              DIAGONAL_LINE_TOTAL3(0.4,0.01,0.2,COLOR_RED09); 
              DIAGONAL_LINE_TOTAL3(0.6,0.01,-0.2,COLOR_RED09);
              return ret;
          }
    if (STATUS(CHANNEL3BAR)  ==  STATUS_RC_CLAMP) ret = COLOR_YELLOW;
 }






 YLINE_DOWN  (0.1 , 0.5 , -MULTIBAR(CHANNEL1BAR) , 0.07 ,  COLOR_RED09 );				// Red bar edges in the case of negative values.     Line macro with parameter transfer:   YLINE_DOWN(xPos,Ypos,length,half_Lineweight,color) .       This macro only processes positive values. Because it is to be active with negative values, the minus sign converts the length value into a positive value.
 YLINE       (0.1 , 0.5 ,  MULTIBAR(CHANNEL1BAR) , 0.05 ,  ColorBar1 );					// The bar.       Line macro with parameter transfer:    YLINE(xPos,Ypos,length,half_Lineweight,color) .     Positive length value = line from the set position upwards   ,   negative length value = line downwards.

 YLINE_DOWN  (0.3 , 0.5 , -MULTIBAR(CHANNEL2BAR) , 0.07 ,  COLOR_RED09 );
 YLINE       (0.3 , 0.5 ,  MULTIBAR(CHANNEL2BAR) , 0.05 ,  ColorBar2 );

 YLINE_DOWN  (0.5 , 0.5 , -MULTIBAR(CHANNEL3BAR) , 0.07 ,  COLOR_RED09 );
 YLINE       (0.5 , 0.5 ,  MULTIBAR(CHANNEL3BAR) , 0.05 ,  ColorBar3 );


   return ret;
}





// -------------- Render,  multi channel bar graph on top , processing step 3    -----------------------

float4 MultiChannelBarGraphStep3  (float2 xy : TEXCOORD2) : COLOR		
{    

 precise float4 ret = tex2D (MultiBarGraph,xy);


  if (xy.x == clamp(xy.x , 0.6 , 0.8 ))
 {
    if (     STATUS(CHANNEL4BAR)              <  STATUS_RC_ON
       ||  CHANNEL4BAR - floor(CHANNEL4BAR)   >   CH_SET_TOL					
       ) 
          {
              DIAGONAL_LINE_TOTAL3(0.6,0.01,0.2,COLOR_RED09); 
              DIAGONAL_LINE_TOTAL3(0.8,0.01,-0.2,COLOR_RED09);
              return ret;
          }
    if (STATUS(CHANNEL4BAR)  ==  STATUS_RC_CLAMP) ret = COLOR_YELLOW;
 }



  if (xy.x == clamp(xy.x , 0.8 , 1.0 ))
 {
    if (     STATUS(CHANNEL5BAR)              <  STATUS_RC_ON
       ||  CHANNEL5BAR - floor(CHANNEL5BAR)   >   CH_SET_TOL					
       ) 
          {
              DIAGONAL_LINE_TOTAL3(0.8,0.01,0.2,COLOR_RED09); 
              DIAGONAL_LINE_TOTAL3(1.0,0.01,-0.2,COLOR_RED09);
              return ret;
          }
    if (STATUS(CHANNEL5BAR)  ==  STATUS_RC_CLAMP) ret = COLOR_YELLOW;
 }


 YLINE_DOWN  (0.7 , 0.5 , -MULTIBAR(CHANNEL4BAR) , 0.07 ,  COLOR_RED09 );
 YLINE       (0.7 , 0.5 ,  MULTIBAR(CHANNEL4BAR) , 0.05 ,  ColorBar4 );

 YLINE_DOWN  (0.9 , 0.5 , -MULTIBAR(CHANNEL5BAR) , 0.07 ,  COLOR_RED09 );
 YLINE       (0.9 , 0.5 ,  MULTIBAR(CHANNEL5BAR) , 0.05 ,  ColorBar5 );

   return ret;
}












///////////////////////////////////////////////
//---------- Main Pixel Shader  (effect output): 
///////////////////////////////////////////////



// --------------  Main mix, Automatic 
float4 mainMixAutomatic (float2 xy1 : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{ 										
precise float4 ret;
float xScaling = GraphicScaling;														// Wide of the graphics split screen
 if (GraphicScaling > 0.495  &&  STATUS_CYCLIC_CHANNEL) xScaling = 0.495;									// Wide of the graphics split screen							

// ... Multi-channel bar graph (top right):
 if (xScaling > 0 && (1-xy.x) / xScaling < 1.0 && xy.y / GraphicScaling < 1.0)
    return tex2D (MultiBarGraph, (float2( (xy.x - 1 + xScaling) / xScaling ,  xy.y / GraphicScaling) ) );					// Multi-channel bar graph and their size
 if (xScaling > 0 && (1-xy.x) < xScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) return COLOR_BLACK;				// Border of the Multi-channel bar graph


// ... Cyclic graphic (top left):
 if (!STATUS_CYCLIC_CHANNEL) return tex2D (InputSampler, xy1); 											// Disables the following graphic elements if the channel does not send.

 if (xScaling > 0 && xy.x / xScaling < 1.0 && xy.y / GraphicScaling < 1.0) 
    return tex2D (Graphic2Sampler , float2( xy.x/xScaling  ,  xy.y/GraphicScaling) );								// Cyclic graphic and their size
 if (xScaling > 0 && xy.x < xScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) 							// Border of the graphic
 {
     if(ERROR_INTERVAL) 
     {
        return COLOR_BORDER_ERROR;														// Color of the border of the cyclic graphic, if a too short set interval length has been corrected automatically.
     }else{
        return COLOR_BLACK;
     }
 }	  


// ... Progress bar of the whole effect:
 if (BORDER2_MIX_X) return COLOR_BLACK;														// Border of the bar
 ret = COLOR_BACKGROUND10;															// Background color for the bar
 if (xy.x < START)   ret = COLOR_BEFORE_STARTTIME;												// Background color for the bar when the set start time has not yet been reached.
 if (ERROR_FRAMES_TOTAL) EXCLAMATION3;														// Warning
 if (!BEFORE_START  &&  START > PROGRESS && xy.x > PROGRESS && xy.x < START) ret = COLOR_BACKGROUND11;						// Extension of the bar to the playhead if the set start time is still within the same frame as the playhead.
 DIAMOND(COLOR_POS);																// Frame maker
 if (BEFORE_START)   DIAMOND(COLOR_OUT_POS);													// frame maker,  when the set start time has not yet been reached. 
 if (( !ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR) || (ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR * 2) ) return ret;  				// Height of the progress bar depending on whether a warning symbol is displayed.				


// ... Video
 return tex2D (InputSampler, xy1);
} 







// --------------  Main mix,    Background: Video  ,  priority: Multi-channel bar graph ,  subordinated size: Cyclical graphic , Foreground: Total position graphic. ----
float4 mainMixVideoGraphFgBar (float2 xy1 : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{ 										
precise float4 ret;
float cyklicScaling = GraphicScaling;
 if (GraphicScaling > 0.495) cyklicScaling = 0.995-GraphicScaling;											// Reduce the cyclical graphic window to avoid overlapping.

// ... Multi-channel bar graph  (top right):
 if (GraphicScaling > 0 && (1-xy.x) / GraphicScaling < 1.0 && xy.y / GraphicScaling < 1.0)
    return tex2D (MultiBarGraph, (float2(xy.x - 1 + GraphicScaling, xy.y) / GraphicScaling) );								// Multi-channel bar graph and their size
 if (GraphicScaling > 0 && (1-xy.x) < GraphicScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) return COLOR_BLACK;			// Border of the Multi-channel bar graph



 if (!STATUS_CYCLIC_CHANNEL) return tex2D (InputSampler, xy1); 												// Disables the following graphic elements if the channel does not send.

// ... Cyclic graphic (top left):
 if (cyklicScaling > 0 && xy.x / cyklicScaling < 1.0 && xy.y / GraphicScaling < 1.0) 
   return tex2D (Graphic2Sampler , float2( xy.x/cyklicScaling  ,  xy.y/GraphicScaling) );								// Cyclic graphic and their size
 if (cyklicScaling > 0 && xy.x < cyklicScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) 						// Border of the graphic
 {
     if(ERROR_INTERVAL) 
     {
        return COLOR_BORDER_ERROR;															// Color of the border of the cyclic graphic, if a too short set interval length has been corrected automatically.
     }else{
        return COLOR_BLACK;
     }
 }	


// ... Progress bar of the whole effect:
 if (BORDER2_MIX_X) return COLOR_BLACK;														// Border of the bar
 ret = COLOR_BACKGROUND10;															// Background color for the bar
 if (xy.x < START)   ret = COLOR_BEFORE_STARTTIME;												// Background color for the bar when the set start time has not yet been reached.
 if (ERROR_FRAMES_TOTAL) EXCLAMATION3;														// Warning
 if (!BEFORE_START  &&  START > PROGRESS && xy.x > PROGRESS && xy.x < START) ret = COLOR_BACKGROUND11;						// Extension of the bar to the playhead if the set start time is still within the same frame as the playhead.
 DIAMOND(COLOR_POS);																// Frame maker
 if (BEFORE_START)   DIAMOND(COLOR_OUT_POS);													// frame maker,  when the set start time has not yet been reached. 
 if (( !ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR) || (ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR * 2) ) return ret;  				// Height of the progress bar depending on whether a warning symbol is displayed.				


// ... Video
 return tex2D (InputSampler, xy1);
} 








// --------------  Main mix,    Background: Video,    priority: Cyclical graphic ,    subordinated size:   Multi-channel bar graph  , Foreground: Total position graphic. ----------
float4 mainMixVideoGraphFgCyclical (float2 xy1 : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{ 										
 precise float4 ret;
 float BarScaling = GraphicScaling;
 if (GraphicScaling > 0.495) BarScaling = 0.995-GraphicScaling; 												//Reduce the bar graph window to avoid overlapping.

 
// ... Cyclic graphic (top left):										

    if (GraphicScaling > 0 && xy.x / GraphicScaling < 1.0 && xy.y / GraphicScaling < 1.0) return tex2D (Graphic2Sampler, xy / GraphicScaling );			// Cyclic graphic and their size
    if (GraphicScaling > 0 && xy.x < GraphicScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) 							// Border of the graphic
    {
        if(ERROR_INTERVAL) 
        {
           return COLOR_BORDER_ERROR;															// Color of the border of the cyclic graphic, if a too short set interval length has been corrected automatically.
        }else{
          return COLOR_BLACK;
        }
    }	


// ... Multi-channel bar graph (top right):
 if (BarScaling > 0 && (1-xy.x) / BarScaling < 1.0 && xy.y / GraphicScaling < 1.0)
    return tex2D (MultiBarGraph, (float2( (xy.x - 1 + BarScaling) / BarScaling ,  xy.y / GraphicScaling) ) );					// Multi-channel bar graph and their size
 if (BarScaling > 0 && (1-xy.x) < BarScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) return COLOR_BLACK;				// Border of the Multi-channel bar graph


if (!STATUS_CYCLIC_CHANNEL) return tex2D (InputSampler, xy1); 												// Disables the following graphic elements if the channel does not send.

// ... Progress bar of the whole effect:
 if (BORDER2_MIX_X) return COLOR_BLACK;														// Border of the bar
 ret = COLOR_BACKGROUND10;															// Background color for the bar
 if (xy.x < START)   ret = COLOR_BEFORE_STARTTIME;												// Background color for the bar when the set start time has not yet been reached.
 if (ERROR_FRAMES_TOTAL) EXCLAMATION3;														// Warning
 if (!BEFORE_START  &&  START > PROGRESS && xy.x > PROGRESS && xy.x < START) ret = COLOR_BACKGROUND11;						// Extension of the bar to the playhead if the set start time is still within the same frame as the playhead.
 DIAMOND(COLOR_POS);																// Frame maker
 if (BEFORE_START)   DIAMOND(COLOR_OUT_POS);													// frame maker,  when the set start time has not yet been reached. 
 if (( !ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR) || (ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR * 2) ) return ret;  				// Height of the progress bar depending on whether a warning symbol is displayed.				


// ... Video
 return tex2D (InputSampler, xy1);
} 









// -------------  Main mix,  Video,  Multi-channel bar graph  ----------
float4 mainMixVideoBarGraph (float2 xy1 : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{ 										
precise float4 ret;

 
// ... Multi-channel bar graph (top right):
 if (GraphicScaling > 0 && (1-xy.x) / GraphicScaling < 1.0 && xy.y / GraphicScaling < 1.0)
    return tex2D (MultiBarGraph, (float2(xy.x - 1 + GraphicScaling, xy.y) / GraphicScaling) );								// Multi-channel bar graph and their size
 if (GraphicScaling > 0 && (1-xy.x) < GraphicScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) return COLOR_BLACK;			// Border of the Multi-channel bar graph


// ... Video
 return tex2D (InputSampler, xy1);
} 








// -------  Main mix,   Video,    Cyclical graphic , Total position graphic. ----------
float4 mainMixVideoCyclicalGraph (float2 xy1 : TEXCOORD1, float2 xy : TEXCOORD2) : COLOR
{ 										
precise float4 ret;

 
// ... Cyclic graphic (top left):										
    if (GraphicScaling > 0 && xy.x / GraphicScaling < 1.0 && xy.y / GraphicScaling < 1.0) return tex2D (Graphic2Sampler, xy / GraphicScaling );			// Cyclic graphic and their size
    if (GraphicScaling > 0 && xy.x < GraphicScaling + BORDER_MIX_X && xy.y < GraphicScaling + BORDER_MIX_Y ) 							// Border of the graphic2
    {
        if(ERROR_INTERVAL) 
        {
           return COLOR_BORDER_ERROR;																// Color of the border of the cyclic graphic, if a too short set interval length has been corrected automatically.
        }else{
          return COLOR_BLACK;
        }
    }	

if (!STATUS_CYCLIC_CHANNEL) return tex2D (InputSampler, xy1); 											// Disables the following graphic elements if the channel does not send.

// ... Progress bar of the whole effect:
 if (BORDER2_MIX_X) return COLOR_BLACK;														// Border of the bar
 ret = COLOR_BACKGROUND10;															// Background color for the bar
 if (xy.x < START)   ret = COLOR_BEFORE_STARTTIME;												// Background color for the bar when the set start time has not yet been reached.
 if (ERROR_FRAMES_TOTAL) EXCLAMATION3;														// Warning
 if (!BEFORE_START  &&  START > PROGRESS && xy.x > PROGRESS && xy.x < START) ret = COLOR_BACKGROUND11;						// Extension of the bar to the playhead if the set start time is still within the same frame as the playhead.
 DIAMOND(COLOR_POS);																// Frame maker
 if (BEFORE_START)   DIAMOND(COLOR_OUT_POS);													// frame maker,  when the set start time has not yet been reached. 
 if (( !ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR) || (ERROR_FRAMES_TOTAL  &&  Y <= HEIGHT_BAR * 2) ) return ret;  				// Height of the progress bar depending on whether a warning symbol is displayed.				


// ... Video
 return tex2D (InputSampler, xy1);
} 







// -------  Main Export ----------
float4 mainExport (float2 xy1 : TEXCOORD1) : COLOR
{ 										
 return tex2D (InputSampler, xy1);
} 















///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// Technique
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#define PS_VERSION    PROFILE		// This sets the pixel shader version for all pixel shaders and passages.


technique Automatic
{
   // Curve graphic
   pass _1_1   < string Script = "RenderColorTarget0 = RenderGraphic;"; >        { PixelShader = compile PS_VERSION cyclicGraphicStep1(); }		// The raw version of the cyclical graphic, processing step 1		
   pass _1_2   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep2(); }		// Cyclical graphic,  processing step 2    				
   pass _1_3   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep3(); }		// Cyclical graphic,  processing step 3					


   // Multi-channel bar graph on top		
   pass _2_1   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep1(); }	// Main Multi-channel bar graph
   pass _2_2   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep2(); }	// Main Multi-channel bar graph 				
   pass _2_3   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep3(); }	// Main Multi-channel bar graph 

   // Mix video & Graphic
   pass _3_1  { PixelShader = compile PS_VERSION mainMixAutomatic(); }											// Created the progress bar of the whole effect, and creates the split screen (Track  &  Cyclical graphic  &  Main Multi-channel bar graph  &  progress bar)
}




technique Automatic_priority_multibar
{
   // Curve graphic
   pass _1_1   < string Script = "RenderColorTarget0 = RenderGraphic;"; >        { PixelShader = compile PS_VERSION cyclicGraphicStep1(); }		// The raw version of the cyclical graphic, processing step 1		
   pass _1_2   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep2(); }		// Cyclical graphic,  processing step 2    				
   pass _1_3   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep3(); }		// Cyclical graphic,  processing step 3					


   // Multi-channel bar graph on top		
   pass _2_1   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep1(); }	// Main Multi-channel bar graph
   pass _2_2   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep2(); }	// Main Multi-channel bar graph 				
   pass _2_3   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep3(); }	// Main Multi-channel bar graph 

   // Mix video & Graphic
   pass _3_1  { PixelShader = compile PS_VERSION mainMixVideoGraphFgBar(); }										// Created the progress bar of the whole effect, and creates the split screen (Track  &  Cyclical graphic  &  Main Multi-channel bar graph  &  progress bar)
}



technique Automatic_priority_cyclical
{
   // Curve graphic
   pass _1_1   < string Script = "RenderColorTarget0 = RenderGraphic;"; >        { PixelShader = compile PS_VERSION cyclicGraphicStep1(); }		// The raw version of the cyclical graphic, processing step 1		
   pass _1_2   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep2(); }		// Cyclical graphic,  processing step 2    				
   pass _1_3   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep3(); }		// Cyclical graphic,  processing step 3					


   // Multi-channel bar graph on top		
   pass _2_1   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep1(); }	// Main Multi-channel bar graph
   pass _2_2   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep2(); }	// Main Multi-channel bar graph 				
   pass _2_3   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep3(); }	// Main Multi-channel bar graph 

   // Mix video & Graphic
   pass _3_1  { PixelShader = compile PS_VERSION mainMixVideoGraphFgCyclical(); }									// Created the progress bar of the whole effect, and creates the split screen (Track  &  Cyclical graphic  &  Main Multi-channel bar graph  &  progress bar)
}






technique Only_Bar_graph_and_Video
{
 
   // Multi-channel bar graph on top		
   pass _2_1   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep1(); }	// Main Multi-channel bar graph
   pass _2_2   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep2(); }	// Main Multi-channel bar graph 				
   pass _2_3   < string Script = "RenderColorTarget0 = RenderMultiBarGraph;"; >  { PixelShader = compile PS_VERSION MultiChannelBarGraphStep3(); }	// Main Multi-channel bar graph 

   // Mix video & Graphic
   pass _3_1  { PixelShader = compile PS_VERSION mainMixVideoBarGraph(); }
}




technique Only_cyclical_chart_and_progress_bar_and_Video
{
   // Curve graphic
   pass _1_1   < string Script = "RenderColorTarget0 = RenderGraphic;"; >        { PixelShader = compile PS_VERSION cyclicGraphicStep1(); }		// The raw version of the cyclical graphic, processing step 1		
   pass _1_2   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep2(); }		// Cyclical graphic,  processing step 2    				
   pass _1_3   < string Script = "RenderColorTarget0 = RenderGraphic2;"; >       { PixelShader = compile PS_VERSION cyclicGraphicStep3(); }		// Cyclical graphic,  processing step 3					


   // Mix video & Graphic
   pass _3_1  { PixelShader = compile PS_VERSION mainMixVideoCyclicalGraph(); }
}




technique Export
{
   pass _1_1  { PixelShader = compile PS_VERSION mainExport(); }
}
