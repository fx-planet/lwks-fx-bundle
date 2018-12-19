// @Maintainer jwrl
// @Released 2018-12-19
// @Author schrauber
// @Created 2016-08-03
// @see https://www.lwks.com/media/kunena/attachments/6375/Flyaway_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/FlyAway.mp4
//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fly away.fx
//
// This cute transition effect "flies" the image off to reveal the new image.  The
// process is divided into 2 phases in order to always ensure a clean transition at
// different effect positions.  The first phase transforms the outgoing image into the
// centre of the frame as a butterfly shape.  In this part of the transition the
// position is fixed. The second part is the actual flight phase.  Adjustment of the
// final destination is possible, but the default is a destination outside of the screen.
//
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//
// Cross platform compatibility check 5 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
//
// Version 14.5 update 5 December 2017 by jwrl.
// Added LINUX and OSX test to allow support for changing "Clamp" to "ClampToEdge" on
// those platforms.  It will now function correctly when used with Lightworks versions
// 14.5 and higher under Linux or OS-X and fixes a bug associated with using this effect
// with transitions on those platforms.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 19 December 2018 jwrl.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Fly away";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

#ifdef LINUX
#define Clamp ClampToEdge
#endif

#ifdef OSX
#define Clamp ClampToEdge
#endif

sampler FgSampler = sampler_state
{
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Xcentre
<
   string Description = "Flight destination (only influences the flight phase)";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.2;
   float MaxVal = 1.5;
> = 1.1;

float Ycentre
<
   string Description = "Flight destination (only influences the flight phase)";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.2;
   float MaxVal = 1.5;
> = 0.90;

float reduction
<
   string Group = "Settings for the first clip";
   string Description = "Reduction";
   float MinVal = 0;
   float MaxVal = 1;
   float KF0    = 0;
   float KF1    = 1;
> = 0.5;

float layout
<
   string Group = "Settings for the first clip";
   string Description = "Layout";
   float MinVal = 0.8;
   float MaxVal = 1.5;
> = 1.2;

float borderX
<
   string Group = "Settings for the first clip";
   string Description = "Border X";
   float MinVal = -1;
   float MaxVal = 1;
   float KF0    = 0;
   float KF1    = 0.02;
> = 0;

float borderY
<
   string Group = "Settings for the first clip";
   string Description = "Border Y";
   float MinVal = -1;
   float MaxVal = 1;
   float KF0    = 0;
   float KF1    = 0.02;
> = 0;


float frequency
<
   string Group = "Fluttering, first clip (only influences the flight phase)";
   string Description = "Frequency";
   float MinVal = 0;
   float MaxVal = 100;
> = 50;

float amplitude
<
   string Group = "Fluttering, first clip (only influences the flight phase)";
   string Description = "Amplitude";
   float MinVal = 0;
   float MaxVal = 0.1;
> = 0.03;

float fluttering_zoom
<
   string Group = "Fluttering, first clip (only influences the flight phase)";
   string Description = "cyclical zoom";
   float MinVal = 0;
   float MaxVal = 20;
> = 8;

float fluttering_y
<
   string Group = "Fluttering, first clip (only influences the flight phase)";
   string Description = "cyclical Y";
   float MinVal = 0;
   float MaxVal = 20;
> = 8;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _Progress;

#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR : COLOR 
{ 


   // ... Definitions, declarations, adaptation and defaults ...

   float2 border = float2 (abs(borderX) , abs(borderY));		// Border to the flying first clip
   float zoom = reduction * (-0.8);					// Parameter acquisition and adaptation
   float2 XYc;								// automatically adjusted Effect Centering
   float2 XYcDiv; 							// XY Distance: Frame Center to the adjusted Effect Center
   float2 DivCxy = float2 (Xcentre, 1.0 - Ycentre) - 0.5;		// XY Distance: Frame Center to the manual Effekt Center setting, with adaptation of Y direction
   float2 xydist;							// XY Distance between the current position to the adjusted effect centering, but excluding layout changes in the next step.
   float2 xydistance;							// XY Distance between the current position to the adjusted effect centering
   float _distance;							// Hypotenuse of xydistance, the shortest distance between the current position to the center of the distortion.
   float cycle = 0;							// Wave for generation of flutter / wing beat. Default is 0 to disable when Progress <= 0.5
   float distortion;							// Intensity of the deformation and the cyclical zoom during the wing beat.
   float2 xydistortion;							// Source pixel position


 

  // ... Wave for generation of flutter / wing beat. (disabled when Progress <= 0.5) ...
   if (_Progress > 0.5) cycle = sin (_Progress * frequency) * amplitude ;						// wave
 

   // ... Distances from the effect center ...
   XYc = 0.5;														// This default is used only when Progress <= 0.5
   if (_Progress > 0.5) XYc = 0.5 + DivCxy * (2 * (_Progress - 0.5));							// Activating effect centering settings when Progress> 0.5 ; and adaptation 
   xydist = XYc - xy;													// XY Distance between the current position to the adjusted effect centering	
   xydistance = float2 (xydist.x * layout, xydist.y / layout);								// Similar xydist + Layout
   _distance = distance ((0.0).xx, xydistance);										// Hypotenuse of xydistance, the shortest distance between the current position to the center of the distortion.

   
   // ... Deformation , Intensity of the deformation and fluttering- zoom ....
   distortion = (zoom / _distance) + cycle * fluttering_zoom;


  // ... xy-Distance of the frame-center to the adjusted effect centering ...
  XYcDiv = 0.5 - XYc; 													


   // ... Pixel position of the source whose signal is to be distorted ...
   xydistortion = distortion * xydist + xy;										// xydistortion Step 1: Source pixel position, without subsequent adjustments
   xydistortion = xydistortion + XYcDiv;										// xydistortion Step 2: Calibrated to the center of the source frame.
   xydistortion = xydistortion + cycle + float2 (0 , cycle * fluttering_y);						// xydistortion Step 3: Source pixel position (including flutter and and including the adjustment in step 1 & 2).

     
   // ........ Output ........  

     // Use the input Fg, if the position of the distorted Fg-pixel inside of the frame and outside the borders:
     if ((xydistortion.x >= 0+border.x) && (xydistortion.x <= 1-border.x) && (xydistortion.y >= 0+border.y) && (xydistortion.y <= 1-border.y)) return tex2D (FgSampler, xydistortion);

    // Use the input Bg, if the position of the Fg-pixel outside the Frame:
    if ((xydistortion.x < 0) || (xydistortion.x > 1) || (xydistortion.y < 0) || (xydistortion.y > 1)) return tex2D (BgSampler, xy);

    // Use the input Bg, when the manual frame settings are negative and the Sorce-position of the pixel inside the border-position:
   if ((borderX < 0) && ((xydistortion.x < border.x) || (xydistortion.x > (1-border.x)))) return tex2D (BgSampler, xy);
   if ((borderY < 0) && ((xydistortion.y < border.y) || (xydistortion.y > (1-border.y)))) return tex2D (BgSampler, xy); 

   // Black border:
   return (0.0).xxxx;
   
} 

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE ps_main ();
   }
}
