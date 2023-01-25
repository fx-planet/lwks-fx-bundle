// @Maintainer jwrl
// @Released 2023-01-25
// @Author jwrl
// @Created 2023-01-25

/**
 To use this effect just apply it, select the colours to affect, then the spread and
 the amount of edge roughness that you need.  That really is all that there is to it.
 You can also control the edge jitter, the glitch rate and angle and the amount of
 video modulation that is applied to the image.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VideoGlitch.fx
//
// Version history:
//
// Built 2023-01-25 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Video glitch", "Stylize", "Special Effects", "Applies a glitch effect to video.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Mode, "Glitch channels", "Glitch settings", 3, "Red - cyan|Green - magenta|Blue - yellow|Full colour");

DeclareFloatParam (GlitchRate, "Glitch rate", "Glitch settings", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Modulation, "Modulation", "Glitch settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Rotation, "Rotation", "Glitch settings", kNoFlags, 0.0, -180.0, 180.0);
DeclareFloatParam (Spread, "Spread", "Glitch settings", kNoFlags, 0.5, -1.0, 1.0);
DeclareFloatParam (EdgeRoughen, "Edge roughen", "Glitch settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EdgeJitter, "Edge jitter", "Glitch settings", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Length);
DeclareFloatParam (_LengthFrames);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SCALE 0.01
#define MODLN 0.25
#define EDGE  9.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_noise (float y)
{
   float edge = _OutputWidth * _OutputAspectRatio;
   float rate = floor (_LengthFrames / _Length);

   edge  = floor ((edge * y) / ((EdgeJitter * EDGE) + 1.0)) / edge;
   rate -= (rate - 1.0) * ((GlitchRate * 0.2) + 0.8);
   rate *= floor ((_LengthFrames * _Progress) / rate) / _LengthFrames;

   float3 seed = frac (float3 (_Length, _LengthFrames, 1.0) * rate * 19.0);

   float n1 = 8192.0 * sin (dot (seed, float3 (17.0, 53.0, 7.0)));
   float n2 = 1024.0 * sin (((n1 / 1024.0) + edge) * 59.0);

   return frac (float2 (abs (n1), n2) * 256.0);
}
//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (VideoGlitch)
{
   float roughness = lerp (1.0, 0.25, saturate (EdgeRoughen)) * _OutputHeight;

   float2 xy = fn_noise (floor (uv1.y * roughness) / _OutputHeight);

   xy.x *= xy.y;

   float modulation = 1.0 - abs (dot (xy, 0.5.xx) * Modulation * MODLN);
   float x = dot (xy, Spread.xx) * SCALE;

   sincos (radians (Rotation), xy.y, xy.x);

   xy.y *= _OutputAspectRatio;
   xy *= x;

   if (Mode != 3) xy /= 2.0;

   float2 xy1 = uv1 + xy;
   float2 xy2 = uv1 - xy;

   float4 video = ReadPixel (Inp, uv1);
   float4 ret_1 = ReadPixel (Inp, xy1) * modulation;
   float4 ret_2 = ReadPixel (Inp, xy2) * modulation;
   float4 glitch;

   glitch.r = Mode == 0 ? ret_2.r : ret_1.r;
   glitch.g = Mode == 1 ? ret_2.g : ret_1.g;
   glitch.b = Mode == 2 ? ret_2.b : ret_1.b;
   glitch.a = video.a;

   glitch = lerp (video, glitch, video.a * Amount);

   return lerp (video, glitch, tex2D (Mask, uv1).x);
}

