// @Maintainer jwrl
// @Released 2021-07-25
// @Author schrauber
// @Created 2017-11-13
// @see https://www.lwks.com/media/kunena/attachments/6375/SwirlMix_Dx_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/SwirlMix_Dx.mp4
// @see https://www.lwks.com/media/kunena/attachments/6375/SwirlMix_Dx_pinch.mp4

/**
 This effect transitions to the incoming clip by causing it to rise from the depths
 like a geyser.  During the first half of the effect the whirl begins and increases
 its rotation to a maximum at the 50% point.  A zoom in is also applied during this
 phase.  During the second half the zoom oscillates as the incoming image mixes in.
 Finally, the zoom reduces to zero as the transition completes.

 If the spin rotation is reduced to zero the outgoing image pinches to the centre
 and holds up to the 50% point.  It then bounces back and produces ripples in the
 outgoing image which cause it to transition from the centre to the incoming image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SwirlMix_Dx.fx
//
// Phase of the transition effect (schrauber's original notes):
//
// Progress 0 to 0.5:
//  -Whirl begins to wind, and reaches the highest speed of rotation at Progress 0.5.
//  -Increasing negative zoom in the center.
//
// Progress 0.5 to 1: Unroll
//  -Progress 0.5  to 0.75 : constant zoom
//  -Progress 0.75 to 1    : Positive zoom (geyser), oscillating zoom, subside
//  -Progress 0.78 to 0.95 : Mixing the inputs, starting in the center
//
// Version history:
//
// Modified 2021-07-25 jwrl.
// Added CanSize switch for 2021 support.
// Added preamble code to convert input addressing to sequence addressing.
// Reformatted code and addressing to support resolution independence.
// Modification date does not reflect upload date because of forum upload problems.
//
// Modified 2020-07-29 jwrl.
// Reformatted the effect header.
//
// Modified 23 December 2018 jwrl.
// Reformatted the effect description for markup purposes.
//
// Modified 13 December 2018 jwrl.
// Changed subcategory.
// Added "Notes" to _LwksEffectInfo.
//
// Modified 9 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Version 14.5 update 5 December 2017 by jwrl.
// Added LINUX and OSX test to allow support for changing "Clamp" to "ClampToEdge" on
// those platforms.  It will now function correctly when used with Lightworks versions
// 14.5 and higher under Linux or OS-X and fixes a bug associated with using this effect
// with transitions on those platforms.
// 
// Version 14 update 18 Feb 2017 by jwrl - added subcategory to effect header.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Swirl mix";
   string Category    = "Mix";
   string SubCategory = "Blur transitions";
   string Notes       = "Uses a spin effect to transition between two sources";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = Mirror;                \
   AddressV  = Mirror;                \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }
#define ExecuteParam(SHDR,PM) { PixelShader = compile PROFILE SHDR (PM); }

#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define FG      true
#define BG      false

#define PI      3.1415926536
#define TWO_PI  6.2831853072

#define CENTRE     0.5

#define FREQ       20.0      // Frequency of the zoom oscillation
#define PHASE      0.5       // 90 ° phase shift of the zoom oscillation. Valid from progress 0.75
#define AREA       100.0     // Area of the regional zoom
#define ZOOMPOWER  12.0

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_RawFg);
DefineInput (Bg, s_RawBg);

DefineTarget (Source, SourceSampler);
DefineTarget (Twist, TwistSampler);
DefineTarget (FgZoom, FgZoomSampler);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Progress
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float Zoom
<
   string Description = "Swirl depth";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Spin
<
   string Group = "Rotation";
   string Description = "Revolutions";
   float MinVal = -62.0;
   float MaxVal = 62.0;
> = 10.0;

float Border
<
   string Group = "Rotation";
   string Description = "Fill gaps";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.9;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_initFg (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_RawFg, uv); }
float4 ps_initBg (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_RawBg, uv); }

float4 ps_rotation (float2 uv : TEXCOORD3) : COLOR
{ 
   float2 vCT = (uv - CENTRE);        // Vector between Center and Texel

   // ------ ROTATION --------

   // WhirlCenter:  Number of revolutions in the center. With increasing distance from the center, this number of revolutions decreases.
   // WhirlOutside: Unrolling from the outside. The number corresponds to the rotation in the center, with an undistorted rotation. (undistorted: WhirlOutside = WhirlCenter)

   float WhirlCenter  = (1.0 - cos (Progress * PI)) * 0.5;                          // Rotation starts slowly, gets faster, and ends slowly (S-curve).
   float WhirlOutside = (1.0 - cos (saturate ((Progress * 2.0 - 1.0)) * PI)) * 0.5; // Unrolling starts slowly from the middle of the effect runtime (S-curve).

   WhirlCenter -= WhirlOutside;
   WhirlCenter *= length (float2 (vCT.x, vCT.y / _OutputAspectRatio));              // Distance from the center
   WhirlCenter += WhirlOutside;

   float angle = radians (WhirlCenter * round (Spin) * 360.0);
   float Tsin, Tcos;    // Sine and cosine of the set angle.

   sincos (angle, Tsin , Tcos);
   vCT.x *= _OutputAspectRatio;       // Vector between Center and Texel, corrected the aspect ratio.

   // Position vectors

   float2 posSpin = float2 ((vCT.x * Tcos) - (vCT.y * Tsin), (vCT.x * Tsin) + (vCT.y * Tcos)); 

   posSpin = float2 (posSpin.x / _OutputAspectRatio, posSpin.y) + CENTRE;

   // ------ OUTPUT-------

   float overEdge = (pow (1.0 - Border, 2.0) * 1000.0);       // Setting characteristic of the border width

   float4 retval = tex2D (SourceSampler, posSpin);

   posSpin = max (abs (posSpin - CENTRE) - CENTRE, 0.0);
   overEdge = saturate (overEdge * max (posSpin.x, posSpin.y));

   return lerp (retval, float4 (0.0.xxx, retval.a), overEdge);
}

float4 ps_zoom (float2 uv : TEXCOORD3, uniform bool firstPass) : COLOR
{ 
   // --- Automatic zoom change in effect progress ----
   // Progress 0    to  0.5 : increasing negative zoom
   // Progress 0.5  to  0.75: constant zoom
   // Progress 0.75 to  1   : Oscillating zoom, subside

   float zoom = min (Progress, 0.5);                          // negative zoom (Progress 0 to 0.75)

   zoom = Zoom * (1.0 - cos (zoom * TWO_PI)) * 0.5;           // Creates a smooth zoom start & zoom end (S-curve) from Progress 0 to 0.5

   if (Progress > 0.75) {                                     // Progress 0.75 to 1 (Swinging zoom)
      zoom = sin (((Progress * FREQ) - PHASE) * PI);          // Zoom oscillation
      zoom *= Zoom * saturate ((1.0 - Progress) * 4.0);       // Damping the zoom from progress 0.75   The formula scales the progress range from 0.75 ... 1   to   1 ... 0; 
   }

   // ------  Inverted regional zoom ------

   float2 vCT = CENTRE - uv;                                  // Vector between Center and Texel

   float distC = length (float2 (vCT.x * _OutputAspectRatio, vCT.y));

   float distortion  = (distC * ((distC * AREA) + 1.0)) + 1.0; 
   float distortion2 = min (length (vCT), CENTRE) - CENTRE;   // The limitation to CENTRE (0.5) preventing distortion of the corners.

   zoom /= max (distortion, 1e-6);

   float2 posZoom = uv + (distortion2 * vCT * zoom * ZOOMPOWER); 

   // ------ OUTPUT-------

   float4 zoomed = tex2D (TwistSampler, posZoom);           

   if (firstPass) return zoomed;           

   float mix = saturate ((Progress - 0.78) * 6.0);            // Scales the progress range from > 0.78 to 0 ... 1

   mix = saturate (mix / distC);                              // Divide mix by distance from the center
   mix = (1.0 - cos (mix * PI)) * 0.5;                        // Makes the spatial boundary of the blended clips narrower.
   mix = (1.0 - cos (mix * PI)) * 0.5;                        // Makes the spatial boundary of the mixed clips even narrower.

   return lerp (tex2D (FgZoomSampler, uv), zoomed, mix);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique main
{
   pass Pfg < string Script = "RenderColorTarget0 = Source;"; > ExecuteShader (ps_initFg)
   pass Pbg < string Script = "RenderColorTarget0 = Twist;"; > ExecuteShader (ps_rotation)
   pass P_1 < string Script = "RenderColorTarget0 = FgZoom;"; > ExecuteParam (ps_zoom, FG)
   pass P_2 < string Script = "RenderColorTarget0 = Source;"; > ExecuteShader (ps_initBg)
   pass P_3 < string Script = "RenderColorTarget0 = Twist;"; > ExecuteShader (ps_rotation)
   pass P_4 ExecuteParam (ps_zoom, BG)
}

