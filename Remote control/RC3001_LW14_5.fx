// @Released 2019-01-06
// @Author schrauber
// @Created 2017-02-13
// @see https://raw.githubusercontent.com/FxSchrauber/Images_for_effects_repository/master/RC/RC_3001_cyclic_control_Nov2018.png

/**
This is a version of the master controller for the remote control user effects subsystem
adds the ability to cycle the values of the effects channels.
This effect outputs the remote control signal on channel 3001. <br>
 <br>
In particular, if there are problems with the effect, I ask for feedback.
The effect should theoretically work across platforms, but until 10.11.2018 only a test on Windows was possible. <br>
 <br>
Revised version with better maneuvering compared to versions before November 2018. <br>
WARNING: THIS EFFECT REQUIRES LIGHTWORKS 14.5 OR BETTER
*/

//-----------------------------------------------------------------------------------------//
//
// Lightworks user effect RC3001_LW14_5.fx
//
//
// Details: 
// Note 1, Assistent effect for correct adjustment: 
// In particular, if a different cyclic waveform is to be set, 
// then it is recommended to add the effect "Setting Display Unit" at the end of the routing.
//
// Note 2, Remote control input:
// What is connected to the input of the effect has no effect on the effect itself. 
// However, the input can be used to pass the remote control signal from another remote control, 
// which is transmitting on another channel, to the output. 
// At the output of the effect then the remote control signals of both effects will be available. 
// That also works with more remote controls.
// If you do not need this feature, you can leave this input open.
//
// Note 3, Keyframing:
// A sliding change of the "Interval" will lead to unexpected interval times.
// The same applies to "Start delay", for which, however, only a static value makes sense anyway.
//
// Note 4, Export: 
//    If the "Setting Display Unit" was used for the effect setting, then deactivate it for the final export.
// Note 4b, when using the export option "Marked section": 
//   * In this case, let "Start Delay" be set to 0 to avoid unexpected behavior.
//   * The export always starts at the beginning of the interval curve. 
//     This may differ from the playback if the starting point of the "Marked section" 
//     is not the beginning of the segment (interval phase shift between playback and export). 
//
// Note 5, Cycle frames with decimal places : 
// The cycle progress will occasionally pause for 1 frames
// at a position to remain synchronized with the set value.
//
// 
// Update:
//
// 06 January 2018 by LW user schrauber: filename, effect name, subcategory and Notes minimally renamed
// 19. Nov, 2018 by LW user schrauber: Changed effect name 
//
// 10. Nov, 2018 by LW user schrauber: 
// Simplification of the effect settings
// Interval setting is now switchable between frames and seconds.
// Reduction of GPU load.
// The quality of the signal transmission should now be independent of the GPU/OS.                                   
//                                  
// 3. May 2018 by LW user schrauber:
// Unnecessary sampler settings removed.
// Subcategory defined, effect description and other data relevant to the user repository added.
//
// 18 Feb 2017 by LW user schrauber: 
// Status level of the blue transmission channel updated (standardization with the other remote control effects)
//
//
//
//
//--------------------------------------------------------------//
// END of effect description
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "RC 3001, cyclic control";
   string Category    = "User";
   string SubCategory = "Remote control";
   string Notes       = "Version January 2019 / THIS EFFECT REQUIRES LIGHTWORKS 14.5 OR BETTER";
> = 0;




//--------------------------------------------------------------//
// Compatibility check, and build a meaningful compiler warning
//--------------------------------------------------------------//

#ifndef _LENGTH
   THIS_EFFECT_REQUIRES_LIGHTWORKS_14_5_OR_BETTER
#endif





//--------------------------------------------------------------//
// Inputs   &    Samplers
//--------------------------------------------------------------//

texture remote;

sampler remoteImput = sampler_state
{
   Texture = <remote>;
};





//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float start_time
<
	string Description = "Start delay";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.0;

int DurationMode
<
  string Description = "Interval duration setting:";
  string Enum = "Frames (~2 frames minimum),"
                "Seconds (~2 frames minimum)";
> = 0;

float Interval
<
	string Description = "Interval";
	float MinVal = 0.03;
	float MaxVal = 300.0;
> = 10.0;





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


int lineChart
<
   string Group = "Remote control of the Setting Display Unit";
   string Description = "Line chart:";
   string Enum = "Idealized curve,Curve in frame steps";
> = 0;










                                               


//--------------------------------------------------------------//
// Definitions, declarations und macros
//--------------------------------------------------------------//
float _OutputWidth;


float _OutputHeight;
float _OutputAspectRatio;	
float _Progress;

// float _OutputFPS;
float _Length;
float _LengthFrames;



// ---------------------------------------------------------------------------
// ... Preprocessor, macros:

#define PI                   3.1415926

#define OVER_FRAME_MAX      62401.0								// Exceeding the maximum allowed effect length specified in frames. In the first frame progress can remain on the first frame too long. In tests, the critical limits ranged between 62488 and 62503 frames total.  (Side note: "_Progress" generates errors when using export function "use marked section",  and is therefore used only as a cross-check)
#define MIN_INTERVAL        2.001


#define PROJECTfps          (_LengthFrames / _Length)                                           // Project frame rate (not "_OutputFPS")
#define INTERVAL1           (DurationMode == 0 ? Interval : (Interval * PROJECTfps)) 



#define INTERVAL            max(INTERVAL1 , MIN_INTERVAL)					// Possibly corrected main interval (cycle length in frames).
#define FRAMES_CYCLE        floor(INTERVAL)							// Number of integer frames that can be represented in a cycle.
#define TIME_CYCLE_FRAME    (1.0/FRAMES_CYCLE)							// Cycle Time between the beginning and the end of the same frame. Timebase expressed in 0 to 1, within the current cycle. 	  
#define HALF_FRAME          (0.5 /  _LengthFrames)						// 1/2 Duration of a frame. Timebase expressed in 0 to 1, within the effekt .
#define START               saturate (start_time)

#define PROGRESS1        (_Progress + HALF_FRAME - START)							// Sets the position on the manually set start time. The duration of a half frame is added so that no pause in the effect progress occurs between the 1st and 2nd frame. 
#define PROGRESS         saturate (PROGRESS1)									
#define PROGRESS_CYCLE1  fmod((PROGRESS * _LengthFrames) / INTERVAL , 1.0)						// Position in the current cycle, Intermediate step 1 without correction of the zero point
#define PROGRESS_CYCLE   (PROGRESS_CYCLE1 - (fmod (PROGRESS_CYCLE1 / TIME_CYCLE_FRAME , 1.0) * TIME_CYCLE_FRAME))	// Position in the current cycle, Correction of the zero point of the cycle 




// Transmitter, Status checks for transfer to the "Settings Display Unit"
    #define BEFORE_START 	(PROGRESS1 - PROGRESS   !=   0.0)						// It is checked whether the playhead is before a possibly set delayed start time.


// Transmitter, Plausibility check for transfer to the "Settings Display Unit"
    #define ERROR_FRAC 	     	0.0                                                                             // This check is no longer needed, so this value was set to 0 (OK). (0 = ok, 1 = error)
    #define ERROR_PROGRESS  	0.0				                                                // This check is no longer needed, so this value was set to 0 (OK). (0 = ok, 1 = error)
    #define ERROR_FRAMES_TOTAL  step (OVER_FRAME_MAX, _LengthFrames)						// It is checked whether the adjusted effect length is too high.    (0 = ok, 1 = error)
    #define ERROR_INTERVAL      step (INTERVAL, MIN_INTERVAL)							// It is checked whether the set interval length is sufficient.     (0 = ok, 1 = error)


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






 


// ---------- Transmitter / render -----------------------
// Documentation see: https://github.com/FxSchrauber/Code_for_developing_Lightworks_effects/blob/master/Remote_control/README.md

// Blue color channel:
   #define STATUS_DATA_ON    0.2 														
   #define STATUS_RC_ON      0.4
   // Meaning of these definitions see: https://github.com/FxSchrauber/Code_for_developing_Lightworks_effects/blob/master/Remote_control/Channel_definitions/Channel_assignment.md#blue-color-channel-status-messages 

// Transmits 3 boolean values as color (numeral system 0 to 1) 
   #define RENDERboolean(TXr,TXg,TXa)   return float4 (TXr , TXg , STATUS_DATA_ON , TXa)



// "RENDERscalar(Tx)"  (numeral system 0 to 1), Transmits the value of "Tx" via the RG channels with increased precision.
 #define RENDERscalar(Tx)   return float4 (Tx - GREEN(Tx) / 255.0 , GREEN(Tx) , STATUS_DATA_ON , 0.0)
    #define GREEN(Tx)     fmod(Tx * 255.0 , 1.0)					// Submacro.


// "RENDERscalar_1_0_1(Tx)"  (numeral system input -1 to +1, output 0 to 1), Transmits the value of "Tx" coded over the RG channels with increased precision,
//  and transmits the same value with GPU precision setting on the alpha channel
 #define RENDERscalar_1_0_1(Tx,Status)   return float4 (TRANSMIT(Tx) - GREEN_1_0_1(Tx) / 255.0 , GREEN_1_0_1(Tx) , Status , TRANSMIT(Tx))
    #define GREEN_1_0_1(Tx)             fmod(TRANSMIT(Tx) * 255.0 , 1.0)		// Submacro
       #define TRANSMIT(Tx)		      ((Tx + 1.0) / 2.0)			// Submacro.    Adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1)














//-----------------------------------------------------------------------------------------//
// Shaders 
//-----------------------------------------------------------------------------------------//



// ------------- Calculate and render the remote control signal,
// ------------- and the waveform as a RC database for the graphical view in the RC effect "Setting Display Unit (Simulates a run through a cycle)

float4 ps_main (float2 xy : TEXCOORD0 , float2 xy1 : TEXCOORD1) : COLOR
{ 
 float2 strengthCycleRampA; 						
 float2 strengthCycle1   = 0.0.xx;                                               // 1nd half wave
 float2 strengthCycle2   = 0.0.xx;                                               // 2nd half-wave, or after the combination half waves, the variable contains the sum of the first half waves and the second half wave.
 float progressCycleSimu = xy.x;                                                 // Simulates a run through a cycle
 if (lineChart == 1) progressCycleSimu = floor(xy.x*FRAMES_CYCLE)/FRAMES_CYCLE;  // Simulates a run through a cycle. Displays the actual curve in the frame steps.
 float2 progressCycle = float2 (PROGRESS_CYCLE, progressCycleSimu);
 float startNext;                                                                // Start time of the next ramp within a cycle

 // .... "HALF_WAVE1" within the same cycle
 startNext = Hold_Time1A;
 strengthCycleRampA = 1.0.xx;
 if (Ramp_Time1A > 0.0) strengthCycleRampA = saturate( (progressCycle - startNext) * (1.0 / Ramp_Time1A));       // Ramp A
 startNext += Ramp_Time1A + Hold_Time1B;                                                                         // Adds the Hold_Time to the already elapsed time.
 strengthCycle1 = 0.0;  
 if (Ramp_Time1B > 0.0) strengthCycle1 = saturate( 1.0 - ((progressCycle - startNext) * (1.0 / Ramp_Time1B)));   // add Time Ramp B
 if (progressCycle.x < startNext) strengthCycle1.x = strengthCycleRampA.x;
 if (progressCycle.y < startNext) strengthCycle1.y = strengthCycleRampA.y;
 if (!Linear_Ramp1) strengthCycle1 = (cos(strengthCycle1 * PI) *-0.5) + 0.5;                                     // Cosine fallback (no sharp edges),   Cosine result: +1 to -1   , after correction:  0 = max zoom , 1 = no zoom
 strengthCycle1 *= Strength1;

 // ... "HALF_WAVE2" within the same cycle
 startNext = Hold_Time2A;
 strengthCycleRampA = 1.0.xx;
 if (Ramp_Time2A > 0.0) strengthCycleRampA = saturate( (progressCycle - startNext) * (1.0 / Ramp_Time2A));      // Ramp A
 startNext += Ramp_Time2A + Hold_Time2B;                                                                        // Adds the Hold_Time to the already elapsed time.
 strengthCycle2 = 0.0;  
 if (Ramp_Time2B > 0.0) strengthCycle2 = saturate( 1.0 - ((progressCycle - startNext) * (1.0 / Ramp_Time2B)));  // add Time Ramp B
 if (progressCycle.x < startNext) strengthCycle2.x = strengthCycleRampA.x;
 if (progressCycle.y < startNext) strengthCycle2.y = strengthCycleRampA.y;
 if (!Linear_Ramp2) strengthCycle2 = (cos(strengthCycle2 * PI) *-0.5) + 0.5;                                     // Cosine fallback (no sharp edges),   Cosine result: +1 to -1   , after correction:  0 = max zoom , 1 = no zoom
 strengthCycle2 *= Strength2;


 // Combine the half waves
 strengthCycle2 = clamp(strengthCycle1 + strengthCycle2 , -1.0 , 1.0);
 if (BEFORE_START) strengthCycle2.x = 0.0;


 // ... Output 
 if (POS_CHANNELGROUP && POSx_CHANNEL3001)  RENDERscalar_1_0_1(strengthCycle2.x, STATUS_RC_ON); // Output the remote control signal.  (and adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1))
 if (POS_CHANNEL_WAVE1)  RENDERscalar_1_0_1(strengthCycle2.y, STATUS_DATA_ON);		        // Output of the waveform form encoded as a colored line (occupies Canal 5001 to 5100).    Macro, Render a variable ("strengthCycle2") a via the RG channels with increased precision (numeral system 0 to 1)
 if (POS_CHANNELGROUP)                                                                          // Channel group for transmission of values needed to generate the graph.
 {
    if (POSx_CHANNEL3002)        RENDERscalar(PROGRESS_CYCLE);                                  // Numeral system  0 ... 1 (Transfer of a float variable via the RG channels with increased precision.)
    if (POSx_CHANNEL3003)        RENDERscalar(TIME_CYCLE_FRAME);                                // Numeral system  0 ... 1 (Transfer of a float variable via the RG channels with increased precision.)
    if (POSx_CHANNEL3004)  	 RENDERscalar(_Progress);                                       // Numeral system  0 ... 1 (Transfer of a float variable via the RG channels with increased precision.)
    if (POSx_CHANNEL3005)        RENDERscalar(START);                                           // Numeral system  0 ... 1 (Transfer of a float variable via the RG channels with increased precision.)
    if (POSx_CHANNEL3007)        RENDERboolean(ERROR_FRAC,ERROR_PROGRESS,ERROR_FRAMES_TOTAL);	// Boolean transmission of 3 possible error types.
    if (POSx_CHANNEL3008)        RENDERboolean(BEFORE_START,ERROR_INTERVAL,0);			// Boolean transmission of 2 values ( the macro "RENDERboolean" can transmit a maximum of 3 values)
 }
 return tex2D (remoteImput, xy1);                                                               // Pass the color signal from the remote input. 

} 








//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//


#ifdef WINDOWS
   #define PROFILE2   ps_3_0
#else
   #define PROFILE2   PROFILE
#endif


technique tech_main
{
    pass P_1    { PixelShader = compile PROFILE2 ps_main(); }
}
