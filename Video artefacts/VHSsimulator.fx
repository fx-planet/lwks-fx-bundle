// @Maintainer jwrl
// @Released 2023-01-26
// @Author khaver
// @Created 2014-11-19

/**
 This effect simulates a damaged VHS tape.  Use the Source X pos slider to locate the
 vertical strip down the frame that affects the distortion.  The horizontal distortion
 uses the luminance value along this vertical strip.  The threshold adjusts the value
 that triggers the distortion and white, red and blue noise can be added.  There's also
 a Roll control to roll the image up or down at different speeds.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VHSsimulator.fx
//
// Version history:
//
// Updated 2023-01-26 jwrl
// Updated to meet the needs of the revised Lightworks effects library code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("VHS simulator", "Stylize", "Video artefacts", "Simulates a damaged VHS tape", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Lines, "Vertical Resolution", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (ORGX, "Source X pos", "Distortion", kNoFlags, 0.02, 0.0, 1.0);

DeclareBoolParam (Invert, "Negate Source", "Distortion", false);

DeclareFloatParam (Strength, "Strength", "Distortion", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Threshold, "Threshold", "Distortion", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Bias, "Bias", "Distortion", kNoFlags, 0.0, -0.5, 0.5);

DeclareFloatParam (WNoise, "White Noise", "Noise", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (RNoise, "Red Noise", "Noise", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (BNoise, "Blue Noise", "Noise", kNoFlags, 0.1, 0.0, 1.0);

DeclareIntParam (RMult, "Speed Multiplier", "Roll", 0, "x1|x10|x100");

DeclareFloatParam (Roll, "Speed", "Roll", kNoFlags, 0.0, -10.0, 10.0);

DeclareBoolParam (Wrap, "Allow video wrap around", kNoGroup, false);

DeclareFloatParam (_Progress);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float random (float2 p)
{
   float2 r = float2 (23.140692632779269,  // e^pi (Gelfond's constant)
                      2.6651441426902251); // 2^sqrt(2) (Gelfond/Schneider constant)

   return frac (cos (fmod (123456789.0, 1e-7 + 256.0 * dot (p, r))));  
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Tex1)
{
   float4 source = float4 (0.0.xxx, 1.0);
   float4 ret = source;
   float4 strip = ReadPixel (Input, float2 (ORGX, uv1.y));

   float luma = (strip.r + strip.g + strip.b) / 3.0;

   luma = Invert ? 1.0 - ((abs (luma - (0.5 + Bias))) * 2.0)
                 : abs (luma - (0.5 + Bias)) * 2.0;

   if (luma >= Threshold) {

      float noiseW = WNoise / 5.0;
      float noiseR = RNoise / 10.0;
      float noiseB = BNoise / 10.0;

      if (random (float2 ((uv1.x + 0.5) * luma, (_Progress + 0.5) * uv1.y)) / Strength < noiseW)
         ret = 1.0.xxxx;

      if (random (float2 ((uv1.y + 0.5) * luma, (_Progress + 0.4) * uv1.x)) / Strength < noiseR)
         ret = float4 (0.75, 0.0.xx, 1.0) * (1.0 - luma - Threshold);

      if (random (float2 ((uv1.x + 0.5) * luma, (_Progress + 0.3) * uv1.x)) / Strength < noiseB)
         ret = float4 (0.0.xx, 0.75, 1.0) * (1.0 - luma - Threshold);
   }

   return (min (WNoise, Strength) == 0.0) && (min (RNoise, Strength) == 0.0) &&
          (min (BNoise, Strength) == 0.0) ? source : ret;
}

DeclarePass (Tex2)
{
   float4 source = ReadPixel (Input, uv1);

   float xSize = 5.0 / (Lines * _OutputWidth);
   float ySize = _OutputAspectRatio / (Lines * _OutputWidth);

   float2 xy = float2 (uv1.x - 0.5, round (( uv1.y - 0.5) / ySize ) * ySize) + 0.5;

   return ReadPixel (Input, xy);
}

DeclareEntryPoint (VHSsimulator)
{
   float xSize = 5.0 / (Lines * _OutputWidth);
   float ySize = _OutputAspectRatio / (Lines * _OutputWidth);
   float rmult = ceil (pow (10.0, (float) RMult));
   float flip = _Progress * Roll * rmult;

   float2 xy1 = float2 (uv2.x, uv2.y + flip);

   float4 orig, strip;

   if (Wrap) {
      orig = tex2D (Tex2, xy1);
      strip = tex2D (Tex2, float2 (ORGX, xy1.y));
   }
   else {
      orig = ReadPixel (Tex2, xy1);
      strip = ReadPixel (Tex2, float2 (ORGX, xy1.y));
   }

   float luma = (strip.r + strip.g + strip.b) / 3.0;

   luma = Invert ? 1.0 - ((abs (luma - (0.5 + Bias))) * 2.0) : abs (luma - (0.5 + Bias)) * 2.0;

   if (luma >= Threshold) {
      float2 xy2 = float2 (xy1.x - ((luma - Threshold) * Strength), xy1.y);
      float2 xy3 = float2 (round ((xy1.x - 0.5) / xSize ) * xSize,
                           round ((xy1.y - 0.5) / ySize) * ySize) + 0.5.xx;

      xy3.x -= (luma - Threshold) * Strength;

      float4 noise;

      if (Wrap) {
         orig.r = tex2D (Tex2, float2 (xy2.x + (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).r;
         orig.g = tex2D (Tex2, xy2).g;
         orig.b = tex2D (Tex2, float2 (xy2.x - (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).b;

         noise = tex2D (Tex1, xy3);
      }
      else {
         orig.r = ReadPixel (Tex2, float2 (xy2.x + (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).r;
         orig.g = ReadPixel (Tex2, xy2).g;
         orig.b = ReadPixel (Tex2, float2 (xy2.x - (xSize * (luma - Threshold) * Strength * 33.0), xy2.y)).b;

         noise = ReadPixel (Tex1, xy3);
      }

      orig = max (orig, noise);
   }

   return orig;
}

