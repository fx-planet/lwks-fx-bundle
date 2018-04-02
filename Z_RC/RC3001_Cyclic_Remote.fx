// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect 
// 2017, Users "schrauber"
// Last update: 18 February 2017
//              - Status level of the blue transmission channel updated (standardization with the other remote control effects).
//
//
//
// Please excuse the Google translation:
//
// Thanks for your tips.
// I would be glad about your participation in the further development of the effect,
// as well as the code usage for other effects.
//
//
// Note: 
// For some parameters, Lightworks keyframing should not be used; other parameters should be aware of unusual behaviors:
// E.g. A sliding change of the frames per cycle always shifts the position in the cycle, 
// which can counteract the internally calculated positional change, 
// which in the interplay will give a different cycle time than the Kyframe value.
//
// Note: 
// For cycle frames with decimal places, 
// the cycle progress will occasionally pause for 2 frames
// at a position to remain synchronized with the set value.
//


//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC 3001, cyclic control";        // The title
   string Category    = "Remote Control";                 // Governs the category that the effect appears in Lightworks
> = 0;





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Inputs       Samplers
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

texture remote;
sampler remoteImput = sampler_state
{
   Texture = <remote>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = PYRAMIDALQUAD;		              // (MinFilter settings seem to have no influence on this user effect?)
   MagFilter = PYRAMIDALQUAD;		// IMPORTANT: MagFilter setting when the sampler uses the pixel coordinates of "TEXCOORD0" .       The settings "PYRAMIDALQUAD" and "GAUSSIANQUAD" worked well in tests.  All other tested settings ("NONE", "POINT", "LINEAR", "ANISOTROPIC" ) caused small deterioration of image quality, which increased with each new rendering (even if the effect is only to pass the pixels unchanged).
   MipFilter = PYRAMIDALQUAD;		              // (MipFilter settings seem to have no influence on this user effect?)
};


//....  Render the incomplete transmission signal (Step 1)
texture Render_transmission : RenderColorTarget;
sampler transmission = sampler_state
{ 
   Texture = <Render_transmission>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = PYRAMIDALQUAD;		               // (MinFilter settings seem to have no influence on this user effect?)
   MagFilter = PYRAMIDALQUAD;		// IMPORTANT:  MagFilter setting when the sampler uses the pixel coordinates of "TEXCOORD0" .       The settings "PYRAMIDALQUAD" and "GAUSSIANQUAD" worked well in tests.  All other tested settings ("NONE", "POINT", "LINEAR", "ANISOTROPIC" ) caused small deterioration of image quality, which increased with each new rendering (even if the effect is only to pass the pixels unchanged).
   MipFilter = PYRAMIDALQUAD;		               // (MipFilter settings seem to have no influence on this user effect?)
};




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





float frames_total
<
	string Group = "Effect frames (First enter correct total frames of this effect)";
	string Description = "Total frames";
	float MinVal = 4;
	float MaxVal = 62400;
> = 1000.0;

float Interval
<
	string Group = "Effect frames (First enter correct total frames of this effect)";
	string Description = "Per Cycle";
	float MinVal = 2.0011;
	float MaxVal = 500.0;
> = 50.0;

float IntervalFine
<
	string Group = "Effect frames (First enter correct total frames of this effect)";
	string Description = "^Fine tuning^";
	float MinVal = -3.0;
	float MaxVal = 3.0;
> = 0.00;

int SetTechnique
<
   string Group = "Effect mode";
   string Description = ">";
   string Enum = "Remote control & display data for idealized curve,Remote cont. & display data for curve in frame steps,No Settings Display Unit: minimized GPU load";
> = 0;



float start_time
<
	string Group = "Delayed start of the effect.";
	string Description = "Start time x 1";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.0;

float start_fine
<
	string Group = "Delayed start of the effect.";
	string Description = "Fine x 0.01";
	float MinVal = -2.0;
	float MaxVal = 2.0;
> = 0.0;

float start_fine00001
<
	string Group = "Delayed start of the effect.";
	string Description = "Fine x 0.0001";
	float MinVal = -2.0;
	float MaxVal = 2.0;
> = 0.0;






// --- Pulse ---

float Strength1
<
	string Group = "Timing within pulse cycle";
	string Description = "Strength 1";
	float MinVal = -1.0;
	float MaxVal = 1.0;
> = 1.0;

float Hold_Time1A
<
	string Group = "Timing within pulse cycle";
	string Description = "Hold time 1A";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.0;

float Ramp_Time1A
<
	string Group = "Timing within pulse cycle";
	string Description = "Ramp time 1A";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.03;

float Hold_Time1B
<
	string Group = "Timing within pulse cycle";
	string Description = "Hold time1B";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.05;

float Ramp_Time1B
<
	string Group = "Timing within pulse cycle";
	string Description = "Ramp time 1B";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.12;



bool Linear_Ramp1
<
	string Group = "Timing within pulse cycle";
	string Description = "Linear Ramp 1AB";
> = false;



float Strength2
<
	string Group = "Timing within pulse cycle";
	string Description = "Strength 2";
	float MinVal = -1.0;
	float MaxVal = 1.0;
> = -0.2;

float Hold_Time2A
<
	string Group = "Timing within pulse cycle";
	string Description = "Hold time 2A";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.15;

float Ramp_Time2A
<
	string Group = "Timing within pulse cycle";
	string Description = "Ramp time 2A";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.08;

float Hold_Time2B
<
	string Group = "Timing within pulse cycle";
	string Description = "Hold time 2B";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.0;

float Ramp_Time2B
<
	string Group = "Timing within pulse cycle";
	string Description = "Ramp time 2B";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.35;

bool Linear_Ramp2
<
	string Group = "Timing within pulse cycle";
	string Description = "Linear Ramp 2AB";
> = false;




float progress
<
	string Group = "Effect progress: Do not alter in any way";
	string Description = "Progress";
	float MinVal = 1.0;						// The Min value is higher than the Max value to disable the slider.
	float MaxVal = 0.0;						// The Max value is lower than the Min value to disable the slider.
        float KF0    = 0.0;
        float KF1    = 1.0;
> = 0.0;







                                               



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//					|   
//                                      |                    Notes on multi-line macros: (Preprocessor)    
//					|
//            		 	 	|       Apart from the last macro line "}", the end of the line must be completed with backslash \
//            Definitions               |       After backslach, the line must actually be terminated (no subsequent comments, no blank spaces, etc.).
//                                      |       Before the backslash, comments can only be entered if these are    /* enclosed in comment delimiters, so that backslash is not interpreted as a comment. */\
//	   and declarations		|	The single-line comment delimiter //  can only be used for the last macro line.
//                                      |           
//					|	If a macro contains an error, the compiler error message often does not display the relevant macro line, but instead the line in the calling shader.
//					|
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float _OutputWidth;
float _OutputHeight;
float _OutputAspectRatio;	
float _Progress;



// ---------------------------------------------------------------------------
// ... Preprocessor, macros:

#define PI                   3.14159265
#define Y                    (1-xy.y)								// Conversion of Y coordinate direction: xy.y = top 0, bottom 1   converted to    Y = bottom 0, top 1		
#define XY                   float2 (xy.x , 1-xy.y)						// Conversion of Y coordinate direction: xy.y = top 0, bottom 1   converted to    Y = bottom 0, top 1
#define XSTEP                (1 / _OutputWidth)							// Step width (distance) between two horizontal adjacent pixels.
#define YSTEP                (1 / _OutputHeight)						// Step width (distance) between two vertically adjacent pixels.
#define XYDIST_AR(xPos,Ypos) (float2(( ((xPos)-XY.x) * _OutputAspectRatio), (Ypos) - XY.y))	// Float2 distance to the currently processed pixels (defined as float2 distance in X direction and in Y direktion. With a correction which is dependent on the aspect ratio.)  	

#define PROGRESS_TOLERANCE  (1 / max(frames_total , 4))						// Allowed deviation between the two variables "progress" and "_Progress". 
#define OVER_FRAME_MAX      62401								// Exceeding the maximum allowed effect length specified in frames. In the first frame progress can remain on the first frame too long. In tests, the critical limits ranged between 62488 and 62503 frames total.  (Side note: "_Progress" generates errors when using export function "use marked section",  and is therefore used only as a cross-check)
#define START_NEXT          tmp									// Start time of the next ramp within a cycle, Temporary recycling of the "tmp" variable for multi-line macros "HALF_WAVE...
#define AREA                (200-Area*201)
#define MIN_INTERVAL        2.001								// A cycle must be just over 2 frames long due to rounding tolerances in the zero point correction of the cycle.
#define INTERVAL1           (Interval + IntervalFine)						// Adjusted interval
#define INTERVAL            max(INTERVAL1 , MIN_INTERVAL)					// Possibly corrected main interval (cycle length in frames).
#define FRAMES_CYCLE        floor(INTERVAL)							// Number of integer frames that can be represented in a cycle.
#define TIME_CYCLE_FRAME    (1/FRAMES_CYCLE)							// Cycle Time between the beginning and the end of the same frame. Timebase expressed in 0 to 1, within the current cycle. 	  
#define HALF_FRAME          (0.5 /  frames_total)						// 1/2 Duration of a frame. Timebase expressed in 0 to 1, within the effekt .
#define START               saturate (start_time + start_fine*0.01 + start_fine00001*0.0001)

#define PROGRESS1        (progress + HALF_FRAME - START)							// Sets the position on the manually set start time. The duration of a half frame is added so that no pause in the effect progress occurs between the 1st and 2nd frame. 
#define PROGRESS         saturate (PROGRESS1)									
#define PROGRESS_CYCLE1  fmod((PROGRESS * frames_total) / INTERVAL , 1)						// Position in the current cycle, Intermediate step 1 without correction of the zero point
#define PROGRESS_CYCLE   (PROGRESS_CYCLE1 - (fmod (PROGRESS_CYCLE1 / TIME_CYCLE_FRAME , 1) * TIME_CYCLE_FRAME))	// Position in the current cycle, Correction of the zero point of the cycle 




// Transmitter, Status checks for transfer to the "Settings Display Unit"
    #define BEFORE_START 	(PROGRESS1 - PROGRESS   !=   0.0)						// It is checked whether the playhead is before a possibly set delayed start time.


// Transmitter, Plausibility check for transfer to the "Settings Display Unit"
    #define ERROR_FRAC 	     	step (1E-20, frames_total - floor(frames_total))				// It is checked whether "Total frames" contains a fractional part. (0 = ok, 1 = error)     (1E-20  is the tolerance)
    #define ERROR_PROGRESS  	step (PROGRESS_TOLERANCE, abs(_Progress - progress))				// It is checked whether the two progress variables differ.         (0 = ok, 1 = error)
    #define ERROR_FRAMES_TOTAL  step (OVER_FRAME_MAX, frames_total)						// It is checked whether the adjusted effect length is too high.    (0 = ok, 1 = error)
    #define ERROR_INTERVAL      step (INTERVAL1, MIN_INTERVAL)							// It is checked whether the set interval length is sufficient.     (0 = ok, 1 = error)


// Transmitter, transfer graphics variables
   #define POSy_CHANNELGROUP    (30 * 0.02) 									// Channelgroup 30        Multiplication with 0.02  =  y-Position of the upper edge of the color signal.
   #define POS_CHANNELGROUP  (xy.y > POSy_CHANNELGROUP  &&  xy.y < POSy_CHANNELGROUP + 0.02)			// Channel group for transmission of graphic variables. 0.02 is the y-size of the color signal areas.
      #define POSx_CHANNEL3001        (xy.x < 0.01)								// x - position position and dimensions of the the color point,   remote control signal (is also used by the "Settings Display Unit")
      #define POSx_CHANNEL3002        (xy.x > 0.01 && xy.x < 0.02)						// x - position position and dimensions of the the color point (used by the "Settings Display Unit")
      #define POSx_CHANNEL3003        (xy.x > 0.02 && xy.x < 0.03)						// x - position position and dimensions of the the color point (used by the "Settings Display Unit")
      #define POSx_CHANNEL3004        (xy.x > 0.03 && xy.x < 0.04)						// x - position position and dimensions of the the color point (used by the "Settings Display Unit")
      #define POSx_CHANNEL3005        (xy.x > 0.04 && xy.x < 0.05)						// x - position position and dimensions of the the color point (used by the "Settings Display Unit")
      #define POSx_CHANNEL3006        (xy.x > 0.05 && xy.x < 0.06)						// Option (free channel) 
      #define POSx_CHANNEL3007        (xy.x > 0.06 && xy.x < 0.07)						// x - position position and dimensions of the the color point (used by the "Settings Display Unit")
      #define POSx_CHANNEL3008        (xy.x > 0.07 && xy.x < 0.08)						// x - position position and dimensions of the the color point (used by the "Settings Display Unit")
  									

// Transmitter, transfer graphics data: Output of the waveform form encoded as a colored line (occupies Remote control channel 3101 to 3200)
   #define POSy_CHANNEL_WAVE1    (31 * 0.02)													//  Channelgroup 31        Multiplication with 0.02  =  y-Position of the upper edge of the color signal. 
   #define POS_CHANNEL_WAVE1  (xy.y > POSy_CHANNEL_WAVE1   &&  xy.y < POSy_CHANNEL_WAVE1 + 0.02)						// Transmitter: Position and dimensions of the color signal. 0.02 is the y-size of the color signal areas.








// -------- Multi-line macro "HALF_WAVE1" within the same cycle --------------------
// Note specifically the following variables:
// float tmp (hidden behind "START_NEXT")
// float strengthCycle    (The variable to be calculated.)
// float progressCycle    (corresponds to "PROGRESS_CYCLE" or xy.x  ,  depending on which shader function this macro is called from.)
// Theses variables must be declared in the calling program part.
//
#define HALF_WAVE1 \
{\
 strengthCycle = 0;\
 START_NEXT = Hold_Time1A;\
 if (progressCycle >= START_NEXT)\
 {\
    if (Ramp_Time1A > 0) strengthCycle = saturate( (progressCycle - START_NEXT) * (1 / Ramp_Time1A));		/* Ramp A Step 1 */\
    if (Ramp_Time1A == 0) strengthCycle = 1;									/* Ramp A */\
 }\
 START_NEXT = START_NEXT + Ramp_Time1A + Hold_Time1B;								/* Adds the Hold_Time to the already elapsed time. */\
 if (progressCycle >= START_NEXT)\
 {\
    if (Ramp_Time1B > 0) strengthCycle = saturate( 1 - ((progressCycle - START_NEXT) * (1 / Ramp_Time1B))); 	/* add Time Ramp B Step1.  */\
    if (Ramp_Time1B == 0) strengthCycle = 0;									/* Ramp B  */\
 }\
 if (!Linear_Ramp1) strengthCycle = (cos(strengthCycle * PI) *-0.5) + 0.5;				 	/* Cosine fallback (no sharp edges),   Cosine result: +1 to -1   , after correction:  0 = max zoom , 1 = no zoom */\
 strengthCycle = strengthCycle * Strength1;\
}



// ------------ Multi-line macro "HALF_WAVE2" within the same cycle ------------
// Note specifically the following variables:
// float tmp (hidden behind "START_NEXT")
// float strengthCycle2     (The variable to be calculated.)
// float progressCycle      (corresponds to "PROGRESS_CYCLE" or xy.x  ,  depending on which shader function this macro is called from.)
// Theses variables must be declared in the calling program part.
//
#define HALF_WAVE2 \
{\
 strengthCycle2 = 0;\
 START_NEXT = Hold_Time2A;\
 if (progressCycle >= START_NEXT)\
 {\
    if (Ramp_Time2A > 0) strengthCycle2 = saturate( (progressCycle - START_NEXT) * (1 / Ramp_Time2A));		/* Ramp A Step 1 */\
    if (Ramp_Time2A == 0) strengthCycle2 = 1;									/* Ramp A */\
 }\
 START_NEXT = START_NEXT + Ramp_Time2A + Hold_Time2B;								/* Adds the Hold_Time to the already elapsed time. */\
 if (progressCycle >= START_NEXT)\
 {\
    if (Ramp_Time2B > 0) strengthCycle2 = saturate(1 - ((progressCycle - START_NEXT) * (1 / Ramp_Time2B))); 	/* add Time Ramp B  Step1.   */\
    if (Ramp_Time2B == 0) strengthCycle2 = 0;				/* Ramp B  */\
 }\
 if (!Linear_Ramp2) strengthCycle2 = (cos(strengthCycle2 * PI) *-0.5) + 0.5;				 	/* Cosine fallback (no sharp edges),   Cosine result: +1 to -1   , after correction:  0 = max zoom , 1 = no zoom */\
 strengthCycle2 = strengthCycle2 * Strength2;\
}


   


// ---------- Transmitter / render -----------------------

// #define STATUS_OFF        0.0														// Status, Channel OFF  
   #define STATUS_DATA_ON    0.2 														// Status, Channel  ON ,   Content:  Data,                      Data for the "Settings Display Unit" 
   #define STATUS_RC_ON      0.4 														// Status, Channel  ON ,   Content:  Remote control,
// #define STATUS_RC_CLAMP   1.0  														// Status, Channel  ON ,   Content:  limited remote control,    The value of the remote control signal was limited by a remote controls.


// Transmits 3 values as 8-bit color (bzw. 1-bit, numeral system 0 to 1, in this effect, this macro is used only for boolean transfer) 
 #define RENDER8BIT(TXr,TXg,TXa)   return float4 (TXr , TXg , STATUS_DATA_ON , TXa)								// Blue = Status, transmitter ON



// "RENDER16BIT(Tx)"  (numeral system 0 to 1), Transmits the value of "Tx" as a 16-bit color by using two 8-bit colors 
 #define RENDER16BIT(Tx)   return float4 (Tx - BIT9TO16(Tx) / 255 , BIT9TO16(Tx) , STATUS_DATA_ON , 0.0)					// Return: Red = bit 1 to bit 8     Green (BIT9TO16) = bit 9 to bit 16     Blue = Status, transmitter ON
    #define BIT9TO16(Tx)     fmod(Tx * 255 , 1)													// Submacro.   Here the color channel for bit 9 to bit 16.


// "RENDER16BIT_1_0_1(Tx)"  (numeral system input -1 to +1, output 0 to 1), Transmits the value of "Tx" as a 16-bit color by using two 8-bit colors,  and transmits the value of ”Tx” as  a 8-bit color
 #define RENDER16BIT_1_0_1(Tx,Status)   return float4 (TRANSMIT(Tx) - BIT9TO16_1_0_1(Tx) / 255 , BIT9TO16_1_0_1(Tx) , Status , TRANSMIT(Tx))	// Return: Red = bit 1 to bit 8 of 16 Bit,     Green (BIT9TO16) = bit 9 to bit 16 of 16 Bit,      Blue = Status, transmitter ON,       Alpha = 8 Bit
    #define BIT9TO16_1_0_1(Tx)             fmod(TRANSMIT(Tx) * 255 , 1)										// Submacro.    Here the color channel for bit 9 to bit 16.
       #define TRANSMIT(Tx)		      ((Tx + 1) / 2)											// Submacro.    Adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1)






















/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//               *****  Pixel Shader  *****
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// These functions are used by "Technique"
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



// ------------- Transmission Step No 1a ,  Calculate and render the waveform encoded as a colored line (occupies Canal 5001 to 5100) ,  Simulates a run through a cycle.  -------------------------
float4 strengthCycleSimu (float2 xy : TEXCOORD0) : COLOR				// "TEXCOORD0" is used Because the effect can also be operated without a connected input, and the graphically encoded color signal is generated by the effect itself.
{ 
 float strengthCycle = 0.0; 								// 1nd half wave, or after the combination half waves, the variable contains the sum of the first half waves and the second half wave.   Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1).
 float strengthCycle2 = 0.0; 								// 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 float progressCycle = xy.x;								// Simulates a run through a cycle. Displays an idealized curve.
 float tmp;  										// Here, the variable is made available to different macros, which can be used to temporarily store different values.
 HALF_WAVE1;										// Macro, 1st half-wave: Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1)
 HALF_WAVE2;										// Macro, 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave 
 strengthCycle = clamp(strengthCycle + strengthCycle2 , -1.0 , 1.0);			// Combine the half waves
 if (POS_CHANNEL_WAVE1)  RENDER16BIT_1_0_1(strengthCycle,STATUS_DATA_ON);		// Output of the waveform form encoded as a colored line (occupies Canal 5001 to 5100).    Macro, Render a variable ("strengthCycle") as a 16-bit color by using two 8-bit colors (numeral system 0 to 1)
 return tex2D (remoteImput, xy);							// Pass the color signal from the remote input. Note the filter settings for the sampler!
} 


// ------------- Transmission Step No 1b (curve in frame steps) ,  Calculate and render the waveform , show actual curve in frame steps, and encoded as a colored line (occupies Canal 5001 to 5100) ,  Simulates a run through a cycle.  -------------------------
float4 strengthCycleSimuSteps (float2 xy : TEXCOORD0) : COLOR				// "TEXCOORD0" is used Because the effect can also be operated without a connected input, and the graphically encoded color signal is generated by the effect itself.
{ 
 float strengthCycle = 0.0; 								// 1nd half wave, or after the combination half waves, the variable contains the sum of the first half waves and the second half wave.   Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1).
 float strengthCycle2 = 0.0; 								// 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 float progressCycle = xy.x;								// Simulates a run through a cycle.
 float tmp;  										// Here, the variable is made available to different macros, which can be used to temporarily store different values.
 progressCycle = floor(xy.x*FRAMES_CYCLE)/FRAMES_CYCLE;					// Simulates a run through a cycle. Displays the actual curve in the frame steps.
 HALF_WAVE1;										// Macro, 1st half-wave: Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1)
 HALF_WAVE2;										// Macro, 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 strengthCycle = clamp(strengthCycle + strengthCycle2 , -1.0 , 1.0);			// Combine the half waves
 if (POS_CHANNEL_WAVE1)  RENDER16BIT_1_0_1(strengthCycle,STATUS_DATA_ON);		// Output of the waveform form encoded as a colored line (occupies Canal 5001 to 5100).    Macro, Render a variable ("strengthCycle") as a 16-bit color by using two 8-bit colors (numeral system 0 to 1)
 return tex2D (remoteImput, xy);							// Pass the color signal from the remote input. Note the filter settings for the sampler!
} 






// ------------- Transmission Step No 2 ,   Calculate and render the remote control signal and pass the signal from Step No1
float4 remoteControl (float2 xy : TEXCOORD0) : COLOR						// "TEXCOORD0" is used Because the effect can also be operated without a connected input, and the graphically encoded color signal is generated by the effect itself.
{ 
 float strengthCycle = 0.0; 									// 1nd half wave, or after the combination half waves, the variable contains the sum of the first half waves and the second half wave.   Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1).
 float strengthCycle2 = 0.0; 									// 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 float progressCycle = PROGRESS_CYCLE;
 float tmp;  											// Here, the variable is made available to different macros, which can be used to temporarily store different values.
 HALF_WAVE1;											// Macro, 1st half-wave: Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1)
 HALF_WAVE2;											// Macro, 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 strengthCycle = clamp(strengthCycle + strengthCycle2 , -1.0 , 1.0);				// Combine the half waves
 if (BEFORE_START) strengthCycle = 0.0;
 if (POS_CHANNELGROUP && POSx_CHANNEL3001)  RENDER16BIT_1_0_1(strengthCycle,STATUS_RC_ON); 	// Transmitting the remote control signal. 16 Bit (and adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1))
 return tex2D (transmission, xy);								// Pass the color signal from Render_transmission. Note the filter settings for the sampler!
}



// ------------- Transmission Step No 3 , Calculate and transmit selected values and pass the signal from Step No2

float4 transmitValues (float2 xy : TEXCOORD0) : COLOR						// "TEXCOORD0" is used Because the effect can also be operated without a connected input, and the graphically encoded color signal is generated by the effect itself.
{ 
 if (POS_CHANNELGROUP)									// Channel group for transmission of values needed to generate the graph.
 {
    if (POSx_CHANNEL3002)        RENDER16BIT(PROGRESS_CYCLE); 					// Transmission 16 Bit (numeral system  0 ... 1)
    if (POSx_CHANNEL3003)        RENDER16BIT(TIME_CYCLE_FRAME);					// Transmission 16 Bit (numeral system  0 ... 1)
    if (POSx_CHANNEL3004)  	 RENDER16BIT(progress);						// Transmission 16 Bit (numeral system  0 ... 1) 
    if (POSx_CHANNEL3005)        RENDER16BIT(START);						// Transmission 16 Bit (numeral system  0 ... 1)
    if (POSx_CHANNEL3007)        RENDER8BIT(ERROR_FRAC,ERROR_PROGRESS,ERROR_FRAMES_TOTAL);	// Boolean transmission of 3 possible error types.
    if (POSx_CHANNEL3008)        RENDER8BIT(BEFORE_START,ERROR_INTERVAL,0);			// Boolean transmission of 2 values ( the macro "RENDER8BIT" can transmit a maximum of 3 values)
 }
  return tex2D (transmission, xy);								// Pass the color signal from Render_transmission2. Note the filter settings for the sampler!
}







// ------------- Remote Control Transmitter, if only one shader is used (do not send graphic data),   Calculate and render the remote control signal and selected values and pass the signal from the remote input.
float4 singleRemoteControl (float2 xy : TEXCOORD0) : COLOR					// "TEXCOORD0" is used Because the effect can also be operated without a connected input, and the graphically encoded color signal is generated by the effect itself.
{ 
 float strengthCycle = 0.0; 									// 1nd half wave, or after the combination half waves, the variable contains the sum of the first half waves and the second half wave.   Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1).
 float strengthCycle2 = 0.0; 									// 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 float progressCycle = PROGRESS_CYCLE;
 float tmp;  											// Here, the variable is made available to different macros, which can be used to temporarily store different values.
 HALF_WAVE1;											// Macro, 1st half-wave: Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1)
 HALF_WAVE2;											// Macro, 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 strengthCycle = clamp(strengthCycle + strengthCycle2 , -1.0 , 1.0);				// Combine the half waves
 if (BEFORE_START) strengthCycle = 0.0;
 if (POS_CHANNELGROUP && POSx_CHANNEL3001)  RENDER16BIT_1_0_1(strengthCycle,STATUS_RC_ON); 	// Transmitting the remote control signal. 16 Bit (and adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1))
 return tex2D (remoteImput, xy);								// Pass the color signal from the remote input. Note the filter settings for the sampler!
}








///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// Technique
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#define PS_VERSION    PROFILE		// Pixel Shader version


technique Transmitter 
{
   pass one   < string Script = "RenderColorTarget0 = Render_transmission;"; >	    { PixelShader = compile PS_VERSION strengthCycleSimu(); }		// Transmission Step No 1 ,  Calculate and render the waveform  encoded as a colored line (occupies Canal 5001 to 5100) ,  Simulates a run through a cycle.
   pass two   < string Script = "RenderColorTarget0 = Render_transmission;"; >      { PixelShader = compile PS_VERSION remoteControl(); }		// Transmission Step No 2 ,  Calculate and render the remote control signal and selected values and pass the signal from Step No1
   pass three  { PixelShader = compile PS_VERSION transmitValues(); }											// Transmission Step No 3 ,  Calculate and transmit selected values and pass the signal from Step No2
}


technique Transmitter_curve_in_frame_steps
{
   pass one   < string Script = "RenderColorTarget0 = Render_transmission;"; >	    { PixelShader = compile PS_VERSION strengthCycleSimuSteps(); }	// Transmission Step No 1 ,  Calculate and render the waveform in frame steps, encoded as a colored line (occupies Canal 5001 to 5100) ,  Simulates a run through a cycle.
   pass two   < string Script = "RenderColorTarget0 = Render_transmission;"; >      { PixelShader = compile PS_VERSION remoteControl(); }		// Transmission Step No 2 ,  Calculate and render the remote control signal and selected values and pass the signal from Step No1
   pass three  { PixelShader = compile PS_VERSION transmitValues(); }											// Transmission Step No 3 ,  Calculate and transmit selected values and pass the signal from Step No2
}


technique Transmitter_without_graphics_data  
{
   pass one    { PixelShader = compile PS_VERSION singleRemoteControl(); }										// Remote Control Transmitter, if only one shader is used (do not send graphic data),   Calculate and render the remote control signal and selected values and pass the signal from the remote input.
}

