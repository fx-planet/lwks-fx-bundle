// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2017-12-29

/**
 This effect is designed to produce a highlighted spotlight effect on the source video.
 It's a simple single effect solution for the alternative, a wipe/matte combination
 used in conjunction with a blend or DVE.  The spot can be scaled, have its aspect ratio
 adjusted, and rotated through plus or minus 90 degrees.  The edge of the effect can
 also be feathered.

 Foreground and background exposure can be adjusted, as can saturation and vibrance.  The
 background can also be slightly blurred to give a soft focus effect, and the foreground
 and background can be individually tinted.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spotlight.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Spotlight", "Stylize", "Special Effects", "Creates a spotlight highlight over a slightly blurred darkened background", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (SpotSize, "Size", "Spot shape", kNoFlags, 0.3, 0.0, 1.0);
DeclareFloatParam (SpotFeather, "Feather", "Spot shape", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (SpotAspect, "Aspect ratio", "Spot shape", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (SpotAngle, "Angle", "Spot shape", kNoFlags, 0.0, -90.0, 90.0);
DeclareFloatParam (CentreX, "Position", "Spot shape", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Position", "Spot shape", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (FgdExposure, "Exposure", "Spot settings", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (FgdSaturation, "Saturation", "Spot settings", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (FgdVibrance, "Vibrance", "Spot settings", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (FgdTint, "Tint", "Spot settings", kNoFlags, 0.0, 0.0, 1.0);

DeclareColourParam (FgdColour, "Colour", "Spot settings", kNoFlags, 1.0, 0.8, 0.0, 1.0);

DeclareFloatParam (BgdFocus, "Focus", "Background settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BgdExposure, "Exposure", "Background settings", kNoFlags, -0.5, -1.0, 1.0);
DeclareFloatParam (BgdSaturation, "Saturation", "Background settings", kNoFlags, -0.5, -1.0, 1.0);
DeclareFloatParam (BgdVibrance, "Vibrance", "Background settings", kNoFlags, -0.5, -1.0, 1.0);
DeclareFloatParam (BgdTint, "Tint", "Background settings", kNoFlags, 0.25, 0.0, 1.0);

DeclareColourParam (BgdColour, "Colour", "Background settings", kNoFlags, 0.0, 0.5, 1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define MIN_EXP  0.00000001
#define LUMAFIX  float3(0.299,0.587,0.114)

#define ASPECT_RATIO  0.2
#define FEATHER_SCALE 0.05
#define RADIUS_SCALE  1.6666666667
#define FOCUS_SCALE   0.002

#define PI            3.1415926536
#define ROTATE        0.0174532925

float _Pascal [] = { 3432.0 / 16384.0, 3003.0 / 16384.0, 2002.0 / 16384.0, 1001.0 / 16384.0,
                     364.0 / 16384.0, 91.0 / 16384.0, 14.0 / 16384.0, 1.0 / 16384.0 };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FgdProc)
{
   float4 retval = ReadPixel (Fg, uv1);

   float alpha = retval.a;
   float gamma = saturate ((1.0 - FgdExposure) * 0.5);

   // Process the exposure

   gamma  = max (MIN_EXP, (gamma * gamma * 2.0) + 0.5);
   retval = saturate (pow (retval, gamma));

   // Process the saturation

   float luma = dot (retval.rgb, LUMAFIX);

   retval = lerp (luma.xxxx, retval, 1.0 + FgdSaturation);

   // Process the vibrance

   float vibval = (retval.r + retval.g + retval.b) / 3.0;
   float maxval = max (retval.r, max (retval.g, retval.b));

   vibval = 3.0 * FgdVibrance * (vibval - maxval);
   retval = lerp (retval, maxval.xxxx, vibval);

   // Process the tint settings

   float4 tint = FgdColour * sin (luma * PI) + retval;

   float Tluma = dot (tint.rgb, LUMAFIX);

   retval   = lerp (retval, saturate (tint * luma / Tluma), FgdTint);
   retval.a = alpha;

   return retval;
}

DeclarePass (BgdProc)
{
   float4 retval = ReadPixel (Fg, uv1);

   float alpha = retval.a;
   float gamma = saturate ((1.0 - BgdExposure) * 0.5);

   gamma  = max (MIN_EXP, (gamma * gamma * 2.0) + 0.5);
   retval = saturate (pow (retval, gamma));

   float luma = dot (retval.rgb, LUMAFIX);

   retval = lerp (luma.xxxx, retval, 1.0 + BgdSaturation);

   float vibval = (retval.r + retval.g + retval.b) / 3.0;
   float maxval = max (retval.r, max (retval.g, retval.b));

   vibval = 3.0 * BgdVibrance * (vibval - maxval);
   retval = lerp (retval, maxval.xxxx, vibval);

   float4 tint = BgdColour * sin (luma * PI) + retval;

   float Tluma = dot (tint.rgb, LUMAFIX);

   retval   = lerp (retval, saturate (tint * luma / Tluma), BgdTint);
   retval.a = alpha;

   return retval;
}

DeclarePass (BgdBlur)
{
   // This is a simple box blur using Pascal's triangle to calculate the blur

   float2 xy1 = float2 ((1.0 - BgdFocus) * FOCUS_SCALE, 0.0);
   float2 xy2 = xy1;

   float4 retval = tex2D (BgdProc, uv2) * _Pascal [0];

   // Blur the background component horizontally

   for (int i = 1; i < 8; i++) {
      retval += tex2D (BgdProc, uv2 + xy1) * _Pascal [i];
      retval += tex2D (BgdProc, uv2 - xy1) * _Pascal [i];
      xy1 += xy2;
   }

   return retval;
}

DeclareEntryPoint ()
{
   float2 xy1 = float2 (0.0, (1.0 - BgdFocus) * FOCUS_SCALE * _OutputAspectRatio);
   float2 xy3, xy2 = xy1;

   float4 retval = tex2D (BgdBlur, uv2) * _Pascal [0];

   // Blur the background component vertically - looks familiar!

   for (int i = 1; i < 8; i++) {
      retval += tex2D (BgdProc, uv2 + xy1) * _Pascal [i];
      retval += tex2D (BgdProc, uv2 - xy1) * _Pascal [i];
      xy1 += xy2;
   }

   // Now calculate the spotlight size, aspect ratio and angle.  We must
   // first set up the size, aspect ratio and edge feathering parameters

   float size    = max (0.0, SpotSize);
   float aspect  = SpotAspect * ASPECT_RATIO;
   float feather = SpotFeather * FEATHER_SCALE;

   // Now compensate for the frame aspect ratio when scaling the spot vertically
   // If the aspect ratio is negative we scale it, if not we use it as-is

   aspect = 1.0 - max (aspect, 0.0) - (min (aspect, 0.0) * _OutputAspectRatio);

   // Put position adjusted uv2 in xy2 and the rotational x and y scale factors in xy3

   xy2 = float2 (CentreX, 1.0 - CentreY) - uv2;
   sincos (SpotAngle * ROTATE, xy3.y, xy3.x);

   // Calculate the angular rotation and put the corrected position in xy1

   xy1.x = (xy2.x * xy3.x) + (xy2.y * xy3.y / _OutputAspectRatio);
   xy1.y = (xy2.y * xy3.x) - (xy2.x * xy3.y * _OutputAspectRatio);

   // Now determine if the current pixel falls inside the spot boundaries, and if so
   // generate the appropriate alpha value to key the foreground over the background.

   float radius = length (float2 (xy1.x / aspect, (xy1.y / _OutputAspectRatio) * aspect)) * RADIUS_SCALE;
   float alpha  = feather > 0.0 ? saturate ((size + feather - radius) / (feather * 2.0))
                : radius < size ? 1.0 : 0.0;

   // Exit, inserting the processed foreground into the processed background.

   return lerp (retval, tex2D (FgdProc, uv2), alpha);
}

