// @Maintainer jwrl
// @Released 2018-04-05
// @Author schrauber
// @Created 2017
// @see https://www.lwks.com/media/kunena/attachments/6375/Rhythmic_pulsation_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect CameraShake.fx
//
//
// Thanks for your tips.
// I would be glad about your participation in the further development of the effect,
// as well as the code usage for other effects.
//
//
// Note: 
// LWKS-Kyframing should not be used with some parameters.
// E.g. A sliding change of the frames per cycle ("Main Interval") always shifts the
// position in the cycle, which can counteract the internally calculated positional
// change, which in the interplay will give a different cycle time than the Kyframe value.
// 
//
// Note: 
// For cycle frames with decimal places, the cycle progress (and the marker) will
// occasionally pause for 2 frames at a position to remain synchronized with the set value.
//
//
// Note also the document: Dynamically controlled effects __ warning symbols.pdf
//
//
// Version 14.5 update 5 December 2017 by jwrl.
// Added LINUX and MAC test to allow support for changing "Clamp" to "ClampToEdge" on
// those platforms.  It will now function correctly when used with Lightworks versions
// 14.5 and higher under Linux or OS-X and fixes a bug associated with using this effect
// with transitions on those platforms.  The bug still exists when using older versions
// of Lightworks.
//
// Modified by LW user jwrl 5 April 2018.
// Metadata header block added to better support GitHub repository.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Rhythmic pulsation";        // The title
   string Category    = "Stylize";
   string SubCategory = "Motion";
> = 0;





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Inputs       Samplers
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef MAC
#define Clamp ClampToEdge
#endif


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



//.... Rendered variable ("strengthCycle") as a 16-bit color by using two 8-bit colors
texture Render_strengthCycle : RenderColorTarget;
sampler strengthCycleSampler = sampler_state
{ 
   Texture = <Render_strengthCycle>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
};


//.... Rendered simulated variable for graphics ("strengthCycle") as a 16-bit color by using two 8-bit colors
texture Render_strengthCycleSimu : RenderColorTarget;
sampler strengthCycleSimuSampler = sampler_state
{ 
   Texture = <Render_strengthCycleSimu>;
   AddressU = Mirror;
   AddressV = Mirror;
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

sampler GraphicSamplerLin = sampler_state
{
   Texture = <RenderGraphic>;
   AddressU = Wrap;
   AddressV = Wrap;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};





//.... Rendered cycle graph 2
texture RenderGraphic2 : RenderColorTarget;
sampler Graphic2Sampler = sampler_state
{
   Texture = <RenderGraphic2>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
};

sampler Graphic2SamplerLin = sampler_state
{
   Texture = <RenderGraphic2>;
   AddressU = Clamp;
   AddressV = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};





//.... Rendered video to which the effect was applied 
texture RenderVideo : RenderColorTarget;
sampler VideoRenderSampler = sampler_state
{
   Texture = <RenderVideo>;
   AddressU = Border;
   AddressV = Border;
   MinFilter = None;
   MagFilter = None;
   MipFilter = None;
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
> = 5.0;

float Interval
<
	string Group = "Effect frames (First enter correct total frames of this effect)";
	string Description = "Per Cycle";
	float MinVal = 2.0011;
	float MaxVal = 500.0;
> = 5.0;

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
   string Enum = "Export or editing: Video only,Editing: Split screen (video & graphics)";
> = 1;


float mix_VideoGraph
<
   string Group = "Effect mode";
   string Description = "Split screen setting";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.2;


int curveFrameSteps
<
   string Group = "Effect mode";
   string Description = "Graphic & curves";
   string Enum = "Show idealized curve,Show actual curve in frame steps";
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


float Strength
<
	string Group = "Zoom effect (these settings only affect the video)";
	string Description = "Total Strength";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.2;



float Area
<
	string Group = "Zoom effect (these settings only affect the video)";
	string Description = "Area";
	float MinVal = 0.0;
	float MaxVal = 1.0;
> = 0.95;


float Xcentre
<
   string Description = "Effect centre (these settings only affect the video)";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre (these settings only affect the video)";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;



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




// Option, Receiver, Remote control channel.  Example of the reception channel 1001. 
//	float ChanelTest
//	<
//		string Description =  "ChanelTest";
//		float MinVal = 1;
//		float MaxVal = 10000;
//	> = 1001;







                                               



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
#define MAX_FRAME_TOTAL     62400								// Allowed maximum effect length specified in frames. In the first frame progress can remain on the first frame too long. In tests, the critical limits ranged between 62488 and 62503 frames total.  (Side note: "_Progress" generates errors when using export function "use marked section",  and is therefore used only as a cross-check)
#define START_NEXT          tmp									// Start time of the next ramp within a cycle, Temporary recycling of the "tmp" variable for multi-line macros "HALF_WAVE...
#define AREA                (200-Area*201)
#define INTERVAL1           (Interval + IntervalFine)						// Adjusted interval
#define INTERVAL            max(INTERVAL1, 2.001)						// Possibly corrected main interval (cycle length in frames). A cycle must be just over 2 frames long (approximately> 2.001?), Because of rounding toreances in the zero-point correction of the cycles.
#define FRAMES_CYCLE        floor(INTERVAL)							// Number of integer frames that can be represented in a cycle.
#define TIME_CYCLE_FRAME    (1/FRAMES_CYCLE)							// Cycle Time between the beginning and the end of the same frame. Timebase expressed in 0 to 1, within the current cycle. 	  
#define HALF_FRAME          (0.5 /  frames_total)						// 1/2 Duration of a frame. Timebase expressed in 0 to 1, within the effekt .
#define START               (start_time + start_fine*0.01 + start_fine00001*0.0001)

#define PROGRESS1        (progress + HALF_FRAME - START)							// Sets the position on the manually set start time. The duration of a half frame is added so that no pause in the effect progress occurs between the 1st and 2nd frame. 
#define PROGRESS         saturate (PROGRESS1)									
#define PROGRESS_CYCLE1  fmod((PROGRESS * frames_total) / INTERVAL , 1)						// Position in the current cycle, Intermediate step 1 without correction of the zero point
#define PROGRESS_CYCLE   (PROGRESS_CYCLE1 - (fmod (PROGRESS_CYCLE1 / TIME_CYCLE_FRAME , 1) * TIME_CYCLE_FRAME))	// Position in the current cycle, Correction of the zero point of the cycle 

#define STARTOK      	 (PROGRESS1 == PROGRESS)								// It is checked whether the playhead is on or after a possibly set start time.
#define BEFORE_START 	 (PROGRESS1 != PROGRESS)								// It is checked whether the playhead is before a possibly set delayed start time.

// Plausibility check
   #define ERROR_FRAC 	    (frames_total != floor(frames_total))						// It is checked whether "Total frames" contains a fractional part.
   #define ERROR_PROGRESS   (abs(_Progress - progress) > PROGRESS_TOLERANCE)					// It is checked whether the two progress variables differ.

// Others
   #define BIT9TO16 tmp												// Render a variable as a 16-bit color by using two 8-bit colors: Here the color channel for bit 9 to bit 16. Temporary recycling of the "tmp" variable. 
   #define COMBINEWAVES clamp(strengthCycle + strengthCycle2 , -1.0 , 1.0)					// Combine the half waves. The variables must be declared in the calling program part.
   #define COMBINE_WAVES strengthCycle = COMBINEWAVES								// The variables must be declared in the calling program part. (strengthCycle + strengthCycle2 (hidden behind "COMBINEWAVES"))


#define COLOR_BLACK             float4 (0.0, 0.0,0.0,1.0)
#define COLOR_BACKGROUND10      float4 (0.75,0.83,1.0,1.0)  							// Background color, total progress bar
#define COLOR_BACKGROUND11      float4 (0.6,0.6,1.0,1.0)  							// Background color, total progress bar
#define COLOR_BEFORE_STARTTIME 	0.4										// Background color, when the set start time has not yet been reached.

// Split screen: video / graphics
   #define COLOR_BORDER_ERROR   float4 (1.0,0.0,0.0,1.0)							// Color of the border of the cyclic graphic, if a too short set interval length has been corrected automatically.
   #define BORDER_MIX_X         0.004										// Border X of the cyclical graphic (above)
   #define BORDER_MIX_Y         (BORDER_MIX_X * _OutputAspectRatio)						// Border Y of the cyclical graphic (above) 
   #define HEIGHT_BAR           0.05										// Height of the progress bar       (below) 
   #define BORDER2_MIX_X   (Y > 0.05  &&  Y < 0.06  &&  frames_total <= MAX_FRAME_TOTAL) || (Y > 0.1  &&  Y < 0.11  &&  frames_total > MAX_FRAME_TOTAL)		// Border X of the progress bar (below.   The positioning depends on whether the maximum permissible total frames are exceeded.

// Creating vertical lines,   with a correction which is dependent on the aspect ratio "AR". 
// Output to the variable "ret", which has previously been declared as a float4 variable by the calling program part.							
   // Lines without interpolation of the line width:
         #define YLINE_AR(xPos,Ypos,length,half_Lineweight,color) 	if (xy.x >= (xPos) - (half_Lineweight)/_OutputAspectRatio && xy.x <= (xPos) + (half_Lineweight)/_OutputAspectRatio && Y >= (Ypos) && Y <= (Ypos) + (length)) ret = color	// Currently used to create the line of exclamation marks (less GPU load than with interpolation).
 
  // Lines with interpolation of line width:
        #define YLINE_TOTAL_IAR(pos,half_Lineweight,color)         ret = lerp( (color), ret,  saturate( saturate(abs(xy.x - (pos)) - ((half_Lineweight) / _OutputAspectRatio) ) / XSTEP) );							// Length from bottom to top.   Vertical line with interpolation of the line width (broadening the line by a maximum of 1 interpolated pixel per line outer edge).      The formula part  " abs(X - pos) " means:   Horizontal distance of the currently calculated pixel to the horizontal center of a vertical line.
        // Option, currently not in use:
        //     #define YLINE_IAR(xPos,Ypos,length,half_Lineweight,color)  if( Y >= (Ypos) && Y <= (Ypos) + (length) ) ret = lerp( (color), ret,  saturate( saturate(abs(xy.x - (xPos)) - ((half_Lineweight) / _OutputAspectRatio) ) / XSTEP) );	// Vertical line with interpolation of the line width (broadening the line by a maximum of 1 interpolated pixel per line outer edge).      The formula part  " abs(X - pos) " means:   Horizontal distance of the currently calculated pixel to the horizontal center of a vertical line.
  


//  "frame maker" in the bar
   #define COLOR_POS       float4 (0.8,0.0,0.0,1.0)				//  The color of the position marker. (red)
   #define COLOR_OUT_POS   float4 (1.0,1.0,0.0,1.0)				//  Bar: The color of the position marker, if this is before the set start time. (yellow)
   #define SKALE_DIAMOND   (min(Y/2, HEIGHT_BAR/2) - max(Y - HEIGHT_BAR/2, 0))	// Defines the width of the diamond. Because the width at the upper and lower end is defined as zero, the diamond size is also limited in the Y axis.
   #define DIAMOND(color) YLINE_TOTAL_IAR(progress,SKALE_DIAMOND,color);	// Output to the variable "ret", which has previously been declared as a float4 variable by the calling program part.
 


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


   



// -------- Multi-line macro "RENDER16BIT" .  Render a variable ("strengthCycle") as a 16-bit color by using two 8-bit colors (numeral system 0 to 1) ---------
// Note specifically the following variables:
// float tmp  		(hidden behind "BIT9TO16") , float tmp must be declared in the calling program part)
// float strengthCycle 	(must be declared in the calling program part)
//
#define RENDER16BIT \
{\
 strengthCycle = (strengthCycle + 1) / 2;										/* Adjustment of the numeral system from (-1 ... +1)   to   ( 0 ... 1)   */\
 BIT9TO16 = fmod(strengthCycle * 255 , 1);										/* Here the color channel for bit 9 to bit 16. BIT9TO16: Temporary recycling of the "tmp" variable. */\
 return float4 (strengthCycle - BIT9TO16 / 255 , BIT9TO16 , 0.0 , 0.0); 						/* Return: Red = bit 1 to bit 8     Green (BIT9TO16) = bit 9 to bit 16  */\
}




// --------  Receiving the sum of the first half waves and the second half wave.   16-bit color by using two 8-bit colors (numeral system 0 to 1) ---------
// Note specifically the following variables: float strengthCycle 	(must be declared in the calling program part)
//

#define RECEIVING1  (tex2D(strengthCycleSampler,xy).r + ((tex2D(strengthCycleSampler,xy).g) / 255))		// Receiving the sum of the first half waves and the second half wave.     Numeral system 0 to 1       Red = bit 1 to bit 8     Green = bit 9 to bit 16
#define RECEIVING2  (RECEIVING1 * 2 - 1)									// Adjustment of the numeral system from  ( 0 ... 1) to (-1 ... +1)




// -------- Multi-line macro "PICKSIMU16BIT" . Pick up the rendered simulated variable for graphics ("strengthCycle" , 16-bit color by using two 8-bit colors (numeral system 0 to 1) ---------
// Note specifically the following variables:
// float strengthCycle (must be declared in the calling program part)
// float strengthCycle0to1 (is declared in this macro)
//
#define PICKSIMU16BIT \
{\
 float strengthCycle0to1 = tex2D(strengthCycleSimuSampler,xy).r + ((tex2D(strengthCycleSimuSampler,xy).g) / 255);		/* Pick up "strengthCycle0to1"      Numeral system 0 to 1       Red = bit 1 to bit 8     Green = bit 9 to bit 16  */\
 strengthCycle = strengthCycle0to1 * 2 - 1;											/* Adjustment of the numeral system from  ( 0 ... 1) to (-1 ... +1)   */\
}









// ......................................................................................................................................................................
// .......   Only for cyclic graphics:  
// ......................................................................................................................................................................

   #define COLOR1_CURVE float4 (0.6,0.85,0.6,1.0) 						// Graphic no. 1 and no. 2: Fill color for positive components in the curve profile. In case of changes, please note: These colors are evaluated and compared to create some lines in the graphic no. 2.
   #define COLOR2_CURVE float4 (0.9,0.65,0.65,1.0)						// Graphic no. 1 and no. 2: Fill color for negaitive components in the curve profile. In case of changes, please note: These colors are evaluated and compared to create some lines in the graphic no. 2. 
   #define COLOR_BACKGROUND1 float4 (0.9,0.9,1.0,1.0)						// Graphic no. 2 ,  Background color
   #define COLOR_BACKGROUND3 float4 (1.0,1.0,1.0,1.0)						// Graphic no. 2 ,  Background color ,  top and bottom of the graphic (limiting the control signal)
   #define COLOR_ERROR_BACKGROUND1 0.3								// Background color of the graphic2 in case of a detected error.
   #define SCALE_GRAPH_CYCLE 0.95								// Scale of the graph. External scaling (e.g., after rendering) is disregarded.. 
   #define OUT_YSCALE (1 - SCALE_GRAPH_CYCLE) / 2						// Graphic no. 2 , Width of the gray lines (top and bottom), which identifies the graphics area, located outside the allowable Y scaling.
   #define HIGHT05_GRAPH_CYCLE (SCALE_GRAPH_CYCLE * 0.5)					// The height measured by the zero line. 
   #define POS_GRAPH_CYCLE 0.5									// The Y position of the zero line. 
   #define STRENGTH_GRAPHIC_SCALED   (POS_GRAPH_CYCLE + strengthCycle * HIGHT05_GRAPH_CYCLE)	// The variable (range - 1 to +1) is adjusted to the the zero line, and the internal Y scale of the graph (hight 0.05 to 0.95). External scaling (e.g., after rendering) is disregarded. The variable (float strengthCycle) must be declared in the calling program part.
   #define IMPRECISION_8BIT 0.002								// When entering floating-point color values (0 to 1), these are output as integer 8-bit color values (0 to 255). From this it follows a maximum deviation of 0.5 * (1/255).

   // "frame maker" = "playhead"
      #define COLOR_POS             float4 (0.8,0.0,0.0,1.0)									//  The color of the position marker. (red)
      #define COLOR_FRAME           float4 (0.8,0.0,0.0,1.0)									//  The color of the red symbolized frame (at the bottom of the chart).
      #define LINEWIDHT_FRAME       0.01											//  The linewidth of the red symbolized frame (at the bottom of the chart).
      #define LINEWIDHT_POS         (0.004 / (pow(GraphicScaling, 1.5) + 0.02))							//  Linewidht of the red position marker.   If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0  
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
               ret = lerp( COLOR_POS, ret,  saturate( (LEFT_LINEWIDHT_POS - xy.x) / XSTEP) );			/* Length from bottom to top. */\
            }



   //  Amplitude marker,  the strength of the effect for the current frame
      #define COLOR_AMPLITUDE float4 (0.0,0.0,1.0,1.0)						//  The color of the Amplitude marker.
      #define HALF_LINEWIDHT_STRENGTH (0.001 / (pow(GraphicScaling, 1.5) + 0.01))		//  HALF line of the Amplitude marker. If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0

   //  Ledger lines
      #define HALF_LINEWIDHT1LL   (3 / _OutputHeight + 0.001)					//  Half line width of the +- 100 % Ledger lines
      #define HALF_LINEWIDHT2LL   (0.8 / _OutputHeight + 0.001)					//  Half line width of the +- 50 % Ledger lines
      #define HALF_LINEWIDHT10LL  (0.6 / _OutputHeight + 0.0005)				//  Half line width of the +- 10%, 20%, 30% ...  Ledger lines  
      #define HALF_LINEWIDHT20LL   0.0004							//  Half line width of the +- 5%, 10%, 15%, 20% ...  Ledger lines  
      #define HALF_LINEWIDHT100LL  0.0003							//  Half line width of the +- 1%, 2%, 3%, 4%, 5%, 6% ....  Ledger lines  
      #define HALF_LINEWIDHT_FRAME 0.005
      #define COLOR_LEDGERLINE1     float4 (0.0,0.0,0.0,1.0)
      #define COLOR_LEDGERLINE2     float4 (0.6,0.6,0.6,1.0)
      #define COLOR_LEDGERLINE10    float4 (0.7,0.7,0.7,1.0)
      #define COLOR_LEDGERLINE20    float4 (0.84,0.84,0.84,1.0)
      #define COLOR_LEDGERLINE100   float4 (0.87,0.87,0.87,1.0)

   //  Chart line in the graphic.
      #define COLOR3_CURVE float4 (0.0,0.5,0.0,1.0)					//  Line color for positive components in the curve profile.
      #define COLOR4_CURVE float4 (0.7,0.0,0.0,1.0)					//  Line color for negaitive components in the curve profile. 
      #define LINEWIDHT_CURVE_DX (0.001 / (GraphicScaling + 0.01))			//  X-positioning: Linewidth for diagonale components of the chart. If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0
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


   //  Creates horizontal line across the entire width of the cyclic graphic.
   //  Output to the variable "ret", which has previously been declared as a float4 variable by the calling program part.							
 
       #define YGAP2LINECENTER(pos)  abs( Y - (pos * HIGHT05_GRAPH_CYCLE + POS_GRAPH_CYCLE) ) 														// For use in XLINE_TOTAL .   Vertical distance of the currently calculated pixel to the vertical center of a horizontal line.   The part of the formula: (pos * HIGHT05_GRAPH_CYCLE + POS_GRAPH_CYCLE)  adjusted the range (- 1 to +1) to the the zero line, and the internal Y scale of the graph (hight 0.05 to 0.95). External scaling (e.g., after rendering) is disregarded. 
      #define XLINE_TOTAL(pos,half_Lineweight,color) ret = lerp (color, ret,  saturate( saturate(YGAP2LINECENTER(pos) - half_Lineweight) / YSTEP) );				// Horizontal lines with interpolation of the line width (broadening the line by a maximum of 1 interpolated pixel per top and bottom edge).

          #define POS_XMULTILINES(lines)                        (round(((Y - OUT_YSCALE) *2) * (lines / SCALE_GRAPH_CYCLE))  / (lines / SCALE_GRAPH_CYCLE))						// Horizontal Multiple Lines ( For use in XLINE_TOTAL ): Position of the line that is at the position of the currently calculated pixel.
         #define YGAP3LINECENTER(pos)                           abs(Y - (pos * POS_GRAPH_CYCLE + OUT_YSCALE) )												// For use in XMULTILINES_TOTAL.   Vertical distance of the currently calculated pixel to the vertical center of a horizontal line.
        #define XMULTILINES_TOTAL(lines,half_Lineweight,color) 	ret = lerp (color, ret, saturate( saturate(YGAP3LINECENTER(POS_XMULTILINES(lines)) - half_Lineweight) / YSTEP) );	// Creates several horizontal lines (with interpolation of the line width) at the same distance from each other. 

 
 



   // ------------ Multi-line macro "GRAPHICAL2STEP2" one cycle,  graphic no. 2,  processing step 2  ------------
   // Note specifically the following variables:
   // float4 ret      (The variable to be calculated,    is declared in this macro)
   //
   #define GRAPHICAL2STEP2 \
   {\
      float4 ret = tex2D(GraphicSampler, xy);	/* Holt the pixel from the buffered graphic. */\
      if (ret.a == 0) \
      {\
         ret = COLOR_BACKGROUND1;\
         \
         if (GraphicScaling > 0.8) \
         {\
            XMULTILINES_TOTAL (100,HALF_LINEWIDHT100LL,COLOR_LEDGERLINE100);				/* Horizontal ledger line.  If the video-output-format is large enough, 200 horizontal ledger line are displayed,  Creates 100 Lines above und 100 Lines below the zero line.   If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0 */\
            XMULTILINES_TOTAL (20,HALF_LINEWIDHT20LL,COLOR_LEDGERLINE20);				/* Horizontal ledger line.  If the video-output-format is large enough, 40 horizontal ledger line are displayed,  Creates 20 Lines above und 20 Lines below the zero line.   If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0 */\
         }\
         if ( fmod( (xy.x / TIME_CYCLE_FRAME) , 2 ) < 1.0 ) ret = ret - 0.04;	/* Correction of the background color, and the color of the fine ledgerlines for every 2nd frame. */\
         \
         if (GraphicScaling > 0.5) 									/* If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0 */\
         {\
            XMULTILINES_TOTAL (10,HALF_LINEWIDHT10LL,COLOR_LEDGERLINE10);				/* Horizontal ledger line,  Creates 10 Lines above und 10 Lines below the zero line*/\
            XMULTILINES_TOTAL (2,HALF_LINEWIDHT2LL,COLOR_LEDGERLINE2);					/* Horizontal ledger line,  Creates 2 Lines above und 2 Lines below the zero line (50% + 100 % )*/\
            XLINE_TOTAL (1.0,HALF_LINEWIDHT1LL,COLOR_LEDGERLINE1);					/* Horizontal ledger line (100%) */\
            XLINE_TOTAL (-1.0,HALF_LINEWIDHT1LL,COLOR_LEDGERLINE1);					/* Horizontal ledger line (-100%) */\
         }\
         \
         if (xy.y < OUT_YSCALE - HALF_LINEWIDHT1LL || Y < OUT_YSCALE - HALF_LINEWIDHT1LL ) ret = COLOR_BACKGROUND3;	/* Background color ,  top and bottom of the graphic (limiting the control signal) */\
         if ( ERROR_PROGRESS || ERROR_FRAC ) ret = COLOR_ERROR_BACKGROUND1;						/* Background color in case of a detected progress error.*/\
      }\
      \
      /* >>>>>                      ............. CURVE .........................					   <<<<<\
         >>>>>      It is checked whether the respective pixel is in the colored or black area of rendered graphics.	   <<<<<\
         >>>>> If the surrounding area darker or lighter, then a color edge is generated there. This edge is the curve. <<<<<\
      */\
      /* Green, line width of the chart */\
      if (tex2D(GraphicSampler, xy).g < REF_PIXEL_GREEN_BELOW_RIGHT && REF_PIXEL_GREEN_BELOW_RIGHT > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;\
      if (tex2D(GraphicSampler, xy).g < REF_PIXEL_GREEN_BELOW_LEFT && REF_PIXEL_GREEN_BELOW_LEFT > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;\
      if (tex2D(GraphicSampler, xy).g > REF_PIXEL_GREEN_ABOVE_RIGHT && tex2D(GraphicSampler, xy).g > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;\
      if (tex2D(GraphicSampler, xy).g > REF_PIXEL_GREEN_ABOVE_LEFT && tex2D(GraphicSampler, xy).g > COLOR1_CURVE.g - IMPRECISION_8BIT) ret = COLOR3_CURVE;\
      \
      return ret;\
   }



   // ------------ Multi-line macro "GRAPHICAL2STEP3" one cycle ( graphic no. 2, processing step 3 ) ------------
   // Note specifically the following variables:
   // float4 ret (The variable to be calculated,      is declared in this macro)
   //
   #define GRAPHICAL2STEP3 \
   {\
      float4 ret = tex2D(Graphic2Sampler, xy);			/* Holt the pixel from the buffered graphic. */\
      \
      /* >>>>>                      ............. CURVE .........................					   <<<<<\
         >>>>>      It is checked whether the respective pixel is in the colored or black area of rendered graphics.	   <<<<<\
         >>>>> If the surrounding area darker or lighter, then a color edge is generated there. This edge is the curve. <<<<<\
      */\
      /* Red,  line width of the chart */\
      if (tex2D(GraphicSampler, xy).r < REF_PIXEL_RED_BELOW_RIGHT && REF_PIXEL_RED_BELOW_RIGHT > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;\
      if (tex2D(GraphicSampler, xy).r < REF_PIXEL_RED_BELOW_LEFT && REF_PIXEL_RED_BELOW_LEFT > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;\
      if (tex2D(GraphicSampler, xy).r > REF_PIXEL_RED_ABOVE_RIGHT && tex2D(GraphicSampler, xy).r > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;\
      if (tex2D(GraphicSampler, xy).r > REF_PIXEL_RED_ABOVE_LEFT && tex2D(GraphicSampler, xy).r > COLOR2_CURVE.r - IMPRECISION_8BIT) ret = COLOR4_CURVE;\
      \
      \
      /* ... "frame maker" / "playhead" ... */\
      if (STARTOK) \
      {\
         PLAYHEAD;																				/*  Your position in the cycle. This indicator is disabled when the set start time has not yet been reached   */\
         if (STARTOK && PROGRESS_CYCLE > xy.x - TIME_CYCLE_FRAME && PROGRESS_CYCLE < xy.x && ( xy.y <  LINEWIDHT_FRAME || Y < LINEWIDHT_FRAME)) ret = COLOR_FRAME;	/* Displays the width of the current frame in the diagram. This indicator is disabled when the set start time has not yet been reached. */\
      }\
      \
      /* ... Amplitude marker, the strength of the effect for the current frame*/\
      XLINE_TOTAL(RECEIVING2,HALF_LINEWIDHT_STRENGTH,COLOR_AMPLITUDE);\
      \
      if (BEFORE_START)   ret = ret * 0.5;			/* Dimming of the graph if the progress variables differ. */\
      \
      /* .... Error checks and warnings  */\
      if (ERROR_FRAC)     EXCLAMATION1;							/* Display an exclamation point in the graphic, if "Total frames" contains a fractional part. */\
      if (ERROR_PROGRESS) EXCLAMATION2;							/* Display an exclamation point in the graphic, if "Total frames" contains a fractional part. */\
     \
      return ret;\
   }























/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//               *****  Pixel Shader  *****
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// These functions are used by "Technique"
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






// --------------  Main zoom Fg-imput  -------------------------
float4 mainZoom (float2 xy : TEXCOORD1) : COLOR
{
 float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - xy; 				// XY Distance between the current position to the adjusted effect centering
  float distance = length (float2 (xydist.x, xydist.y / _OutputAspectRatio)); 	// Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
 										// Macro, Pick up the rendered variable ( "strengthCycle" (-1 to +1) , 16-bit color by using two 8-bit colors)
 float zoom = Strength * RECEIVING2;						// "RECEIVING2" : The sum of the first half waves and the second half wave.
 float distortion = (distance * ((distance * AREA) + 1.0) + 1);			// Creates the distortion
 if (Area != 1) zoom = zoom / max( distortion, 0.1 ); 				// If the area = 1, then normal zoom works. Otherwise, a local zoom is active.   "0.1" prevents a division by zero 

 return tex2D (FgSampler, zoom * xydist + xy); 
} 





// --------------  Main graphic ,  the raw version of the graphic, processing step 1  -------------------------

// *** Please note when changing the program: 
// *** Because the graphic2 is formed from this raw graphic,
// *** changes in this graphic shader can affect the graphic2. 

float4 mainGraphic (float2 xy : TEXCOORD1, uniform float GraphicScaling) : COLOR		// If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0
{ 
 float strengthCycle; 										// The sum of the first half waves and the second half wave.   Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1).
 
 PICKSIMU16BIT;											// Macro, Pick up the rendered simulated variable for graphics ( "strengthCycle" (-1 to +1) , 16-bit color by using two 8-bit colors)

  // Output: render cycle graph (raw version)
  // Please note that these colors are evaluated elsewhere in order to create the graphic2.
     if (STRENGTH_GRAPHIC_SCALED > Y && Y > POS_GRAPH_CYCLE - LINEWIDHT_CURVE_DY) return COLOR1_CURVE;
     if (STRENGTH_GRAPHIC_SCALED < Y && Y < POS_GRAPH_CYCLE ) return COLOR2_CURVE;
   
        return 0;										// Black, transparent.  In case of changes, please note: This background color is evaluated elsewhere to create the graphic2.
} 




// --------------   Main graphic2,  processing step 2  -------------------------

float4 Graphic2step2 (float2 xy : TEXCOORD1, uniform float GraphicScaling) : COLOR		// If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0
{ 
 GRAPHICAL2STEP2;				// Macro, Editing the buffered graphic
} 




// -------------- Main graphic2, processing step 3  -------------------------

float4 Graphic2step3 (float2 xy : TEXCOORD1, uniform float GraphicScaling) : COLOR		// If the dimensions of the graphics depend on the slider "mix_VideoGraph", then "GraphicScaling" = "mix_VideoGraph".   Otherwise: "GraphicScaling" = 1.0
{ 
 GRAPHICAL2STEP3;						// Macro, Editing the buffered graphic
} 







// --------------  Main mix Video & Cyclical graphic & total position graphic. -------------------------
float4 mainMixVideoGraph (float2 xy : TEXCOORD1) : COLOR
{ 										
float4 ret;
// Cyclic graphic:
 if (mix_VideoGraph > 0 && xy.x / mix_VideoGraph < 1.0 && xy.y / mix_VideoGraph < 1.0) return tex2D (Graphic2SamplerLin, xy / mix_VideoGraph );		// Cyclic graphic2 and their size
 if (mix_VideoGraph > 0 && xy.x < mix_VideoGraph + BORDER_MIX_X && xy.y < mix_VideoGraph + BORDER_MIX_Y ) 						// Border of the graphic2
 {
     if(INTERVAL ==  INTERVAL1) 
     {
        return COLOR_BLACK;
     }else{
        return COLOR_BORDER_ERROR;															// Color of the border of the cyclic graphic, if a too short set interval length has been corrected automatically.
     }
 }				

// Progress bar of the whole effect:
 if (BORDER2_MIX_X) return COLOR_BLACK;															// Border of the bar
 ret = COLOR_BACKGROUND10;															// Background color for the bar
 if (xy.x < START)   ret = COLOR_BEFORE_STARTTIME;												// Background color for the bar when the set start time has not yet been reached.
 if (frames_total > MAX_FRAME_TOTAL) EXCLAMATION3;													// Warning
 if (!BEFORE_START  &&  START > progress && xy.x > progress && xy.x < START) ret = COLOR_BACKGROUND11;						// Extension of the bar to the playhead if the set start time is still within the same frame as the playhead.
 DIAMOND(COLOR_POS);																	// Frame maker
 if (BEFORE_START)   DIAMOND(COLOR_OUT_POS);														// frame maker,  when the set start time has not yet been reached. 
 if ((frames_total <= MAX_FRAME_TOTAL  &&  Y <= HEIGHT_BAR) || (frames_total > MAX_FRAME_TOTAL  &&  Y <= HEIGHT_BAR * 2) ) return ret;  	// Height of the progress bar depending on whether a warning symbol is displayed.				

 // Video
 return tex2D (VideoRenderSampler, xy);
} 







// ------------- Calculate and render the variable "strengthCycle"  -------------------------
float4 strengthCycle (float2 xy : TEXCOORD1) : COLOR
{ 
 float strengthCycle = 0.0; 		// 1. half wave, or after the combination half waves, the variable contains the sum of the first half waves and the second half wave.   Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1).
 float strengthCycle2 = 0.0; 		// 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 float tmp;  				// Here, the variable is made available to different macros, which can be used to temporarily store different values.

 float progressCycle = PROGRESS_CYCLE;
 HALF_WAVE1;				// Macro, 1st half-wave: Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1)
 HALF_WAVE2;				// Macro, 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 COMBINE_WAVES;				// Combine the half waves
 if (BEFORE_START) strengthCycle = 0.0;
 RENDER16BIT;				// Macro, Render a variable ("strengthCycle") as a 16-bit color by using two 8-bit colors (numeral system 0 to 1)
} 

// ------------- Graphic: Calculate and render the variable "strengthCycle" ,  Simulates a run through a cycle.  -------------------------
float4 strengthCycleSimu (float2 xy : TEXCOORD1) : COLOR
{ 
 float strengthCycle = 0.0; 								// 1. half wave, or after the combination half waves, the variable contains the sum of the first half waves and the second half wave.   Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1).
 float strengthCycle2 = 0.0; 								// 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 float tmp;  										// Here, the variable is made available to different macros, which can be used to temporarily store different values.
 float progressCycle = xy.x;								// Simulates a run through a cycle. Displays an idealized curve.
 if (curveFrameSteps == 1) progressCycle = floor(xy.x*FRAMES_CYCLE)/FRAMES_CYCLE;	// Simulates a run through a cycle. Displays the actual curve in the frame steps.
 HALF_WAVE1;										// Macro, 1st half-wave: Relative strenth of the effect of the current position in the cycle (relative from 0 to 1 or 0 to -1)
 HALF_WAVE2;										// Macro, 2nd half-wave: Relative strenth of the effect of the current position in the cycle, or mixed with the first half-wave
 COMBINE_WAVES;										// Combine the half waves
 if (BEFORE_START) strengthCycle = 0.0;
 RENDER16BIT;										// Macro, Render a variable ("strengthCycle") as a 16-bit color by using two 8-bit colors (numeral system 0 to 1)
} 























///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
// Technique
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#define PS_VERSION    PROFILE		// Pixel Shader version


// In splitscreen mode, the graphic dimensions can be changed, which also affects the line width. 
// By means of the variable "GraphicScaling", this is partially compensated for better visibility.
// In the relevant techniques, the value is passed to the shader function.
// These shader functions assign this value to the variable "GraphicScaling".
// If the dimensions of the graphics depend on the slider "mix_VideoGraph", then the value = "mix_VideoGraph". 
// Otherwise: value = 1.0 (Not used in this effect)


technique Video_only
{
   pass one   < string Script = "RenderColorTarget0 = Render_strengthCycle;"; >		{ PixelShader = compile PS_VERSION strengthCycle(); }
   pass two { PixelShader = compile PS_VERSION mainZoom();}
}


technique Split_screen
{
   // Graphic
   pass one   < string Script = "RenderColorTarget0 = Render_strengthCycleSimu;"; >	{ PixelShader = compile PS_VERSION strengthCycleSimu(); }
   pass two   < string Script = "RenderColorTarget0 = RenderGraphic;"; >		{ PixelShader = compile PS_VERSION mainGraphic(mix_VideoGraph); }	// Transfer the value (mix_VideoGraph, coming from the slider) for the variable GraphicScaling. In this function, this setting affects only the zero line. If the dimensions of the rendered graphic are changed, then the line width is automatically adjusted so that the line remains visible even with a very small graphic.
   pass three < string Script = "RenderColorTarget0 = Render_strengthCycle;"; >		{ PixelShader = compile PS_VERSION strengthCycle(); }
   pass four  < string Script = "RenderColorTarget0 = RenderGraphic2;"; > 		{ PixelShader = compile PS_VERSION Graphic2step2(mix_VideoGraph); }	// Transfer the value (mix_VideoGraph, coming from the slider) for the variable GraphicScaling. If the dimensions of the rendered graphic are changed, then the line width is automatically adjusted so that the line remains visible even with a very small graphic.
   pass five  < string Script = "RenderColorTarget0 = RenderGraphic2;"; > 		{ PixelShader = compile PS_VERSION Graphic2step3(mix_VideoGraph); }	// Transfer the value (mix_VideoGraph, coming from the slider) for the variable GraphicScaling. If the dimensions of the rendered graphic are changed, then the line width is automatically adjusted so that the line remains visible even with a very small graphic.

   // Video
   pass six   < string Script = "RenderColorTarget0 = RenderVideo;"; >			{ PixelShader = compile PS_VERSION mainZoom();}

   // Mix video & Graphic
   pass seven { PixelShader = compile PS_VERSION mainMixVideoGraph(); }
}





