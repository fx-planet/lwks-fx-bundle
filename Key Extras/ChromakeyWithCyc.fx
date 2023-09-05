// @Maintainer jwrl
// @Released 2023-09-05
// @Author jwrl
// @Created 2023-09-05

/**
 This effect is a customised version of the Lightworks Chromakey effect with some simple
 DVE adjustments added.  As the name suggests, a means of generating a cyclorama style
 background has also been included.  The colour of the background and its linearity can
 be adjusted to give a very realistic studio look.  The ChromaKey sections are based on
 work copyright (c) LWKS Software Ltd.

 There was a previous version of this effect called "Chromakey and background" which had
 full cropping.  That has been withdrawn, since the Lightworks native masking gives the
 same functionality and does it better.

 NOTE:  To allow full screen width of the background in all combinations of video and
 sequence this effect must break resolution independence.  It is only suitable for use
 with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyWithCyc.fx
//
// Version history:
//
// Built 2023-09-05 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chromakey with cyclorama", "Key", "Key Extras", "A chromakey effect with a simple DVE and cyclorama background generation.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareColourParam (KeyColour, "Key Colour", kNoGroup, "SpecifiesColourRange", 150.0, 0.7, 0.75, 0.0);
DeclareColourParam (Tolerance, "Tolerance", kNoGroup, "SpecifiesColourRange|Hidden", 20.0, 0.3, 0.25, 0.0);
DeclareColourParam (ToleranceSoftness, "Tolerance softness", kNoGroup, "SpecifiesColourRange|Hidden", 15.0, 0.115, 0.11, 0.0);

DeclareFloatParam (KeySoftAmount, "Key softness", "Key settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (RemoveSpill, "Remove spill", "Key settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareBoolParam (Reveal, "Reveal", "Key settings", false);

DeclareFloatParam (CentreX, "Position", kNoGroup, "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.5, 1.5);
DeclareFloatParam (CentreY, "Position", kNoGroup, "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.5, 1.5);
DeclareFloatParam (CentreZ, "Position", kNoGroup, "SpecifiesPointZ", 0.0, -1.0, 1.0);

DeclareColourParam (HorizonColour, "Lighting colour", "Cyclorama", kNoFlags, 0.631, 0.667, 0.702, 1.0);
DeclareFloatParam (Lighting, "Overhead light", "Cyclorama", "DisplayAsPercentage", 1.5, 0.5, 2.0);
DeclareFloatParam (Groundrow, "Groundrow light", "Cyclorama", "DisplayAsPercentage", 1.1, 0.5, 2.0);
DeclareFloatParam (Horizon, "Horizon line", "Cyclorama", "DisplayAsPercentage", 0.3, 0.1, 0.9);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloat4Param (_InpExtents);

DeclareIntParam (_InpOrientation);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HUE_IDX 0
#define SAT_IDX 1
#define VAL_IDX 2

float _FallOff = 0.12;
float _oneSixth = 1.0 / 6.0;
float _minTolerance = 1.0 / 256.0;

float blur [] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };  // See Pascal's Triangle

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool allPositive (float4 pix)
{
   return (pix.r > 0.0) && (pix.g > 0.0) && (pix.b > 0.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// Foreground transform
//
// This pass adjusts the position and scaling of the foreground image.
//-----------------------------------------------------------------------------------------//

DeclarePass (fgVid)
{
   // Adjust the position allowing for Inp size and orientation.

   float2 extents  = float2 (_InpExtents.x - _InpExtents.z, _InpExtents.y - _InpExtents.w);
   float2 position = (_InpOrientation == 0) || (_InpOrientation == 180)
                   ? float2 (0.5 - CentreX, CentreY - 0.5)
                   : 0.5.xx - float2 (CentreY, CentreX);

   if (_InpOrientation > 90) position = -position;

   position /= abs (extents);
   position += 0.5.xx;

   // Set up the scale factor, using the Z axis position.  Unlike the Lightworks 3D DVE
   // the range isn't linear and operates smallest to largest.  Since it is intended to
   // just fine tune position it does not cover the full range of the 3D DVE.

   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);

   // Set up the image position and scaling

   float2 xy = ((uv1 - 0.5.xx) / scale) + position;

   // Now return the repositioned and resized image.

   return ReadPixel (Inp, xy);
}

//-----------------------------------------------------------------------------------------//
// Background generation
//
// To create the background, the groundrow distance to the centre point, cg, is first
// calculated using a range limited version of Horizon.  Subtracting that from 1 gives
// the lighting distance to the centre point, which is stored in cl.
//-----------------------------------------------------------------------------------------//

DeclarePass (bgVid)
{
   float cg = clamp (Horizon, 0.1, 0.9);
   float cl = 1.0 - cg;

   // If we are at the top of the "cyclorama" the gamma uses the value set in Lighting,
   // otherwise the Groundrow value is used.  The amount of gamma correction to use is
   // given by the normalised distance of the Y position from Horizon.

   float gamma = (uv0.y < cl) ? lerp (1.0 / Lighting, 1.0, uv0.y / cl)
                              : lerp (1.0 / Groundrow, 1.0, (1.0 - uv0.y) / cg);

   if (gamma < 1.0) gamma = pow (gamma, 3.0);

   // The appropriate gamma correction is now applied to the colour of the "cyclorama"
   // to produce the desired lighting effect on the background.  The alpha channel is
   // then set to 1.0 and we quit.

   return float4 (pow (HorizonColour, gamma).rgb, 1.0);
}

//-----------------------------------------------------------------------------------------//
// Key generation
//
// Convert the source to HSV and then compute its similarity with the specified key-colour.
//
// This has had preamble code added to check for the presence of valid video, and if there
// is none, quit.  As a result the original foreground sampler code has been removed.
//
// A new flag is also set in the returned z component if the key is valid.
//-----------------------------------------------------------------------------------------//

DeclarePass (RawKey)
{
   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   // First recover the cropped image.

   float4 tolerance1 = Tolerance + _minTolerance;
   float4 tolerance2 = tolerance1 + ToleranceSoftness;
   float4 rgba = tex2D (fgVid, uv2);
   float4 hsva = 0.0.xxxx;

   // The float maxComponentVal has been set up here to save a redundant evalution
   // in the following conditional code.

   float maxComponentVal = max (max (rgba.r, rgba.g), rgba.b);

   // Check if rgba is zero and if it is we need do nothing.  This check is done
   // because up to now we have no way of knowing what the contents of rgba are.
   // This catches all null values in the original image.

   if (max (maxComponentVal, rgba.a) == 0.0) return rgba;

   // Now return to the Lightworks original, minus the rgba = tex2D() section and
   // the maxComponentVal initialisation for the HSV conversion.

   float minComponentVal = min (min (rgba.r, rgba.g), rgba.b);
   float componentRange  = maxComponentVal - minComponentVal;

   hsva [VAL_IDX] = maxComponentVal;
   hsva [SAT_IDX] = componentRange / maxComponentVal;

   if (hsva [SAT_IDX] == 0.0) { hsva [HUE_IDX] = 0.0; }      // undefined colour
   else {
      if (rgba.r == maxComponentVal) { hsva [HUE_IDX] = (rgba.g - rgba.b) / componentRange; }
      else if (rgba.g == maxComponentVal) { hsva [HUE_IDX] = 2.0 + ((rgba.b - rgba.r) / componentRange); }
      else { hsva [HUE_IDX] = 4.0 + ((rgba.r - rgba.g) / componentRange); }

      hsva [HUE_IDX] *= _oneSixth;
      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
   }

   // Calculate the difference between the current pixel and the specified key-colour

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) { diff [HUE_IDX] = 1.0 - diff [HUE_IDX]; }

   // Work out how transparent/opaque the corrected pixel will be

   if (allPositive (tolerance2 - diff)) {
      if (allPositive (tolerance1 - diff)) { keyVal = 0.0; }
      else {
         diff -= tolerance1;
         hueSimilarity = diff [HUE_IDX];
         diff /= ToleranceSoftness;
         keyVal = max (diff [HUE_IDX], max (diff [SAT_IDX], diff [VAL_IDX]));
         keyVal = pow (keyVal, 0.25);
      }
   }
   else {
      diff -= tolerance1;
      hueSimilarity = diff [HUE_IDX];
   }

   // New flag set in z to indicate that key generation actually took place

   return float4 (keyVal, keyVal, 1.0, 1.0 - hueSimilarity);
}

//-----------------------------------------------------------------------------------------//
// Blur 1
//
// Does the horizontal component of a box blur.  Added a check for a valid key presence
// at the start of the shader using the new flag in retval.z.  If it isn't set, quit.
//-----------------------------------------------------------------------------------------//

DeclarePass (Blur_X)
{
   float4 retval = tex2D (RawKey, uv2);

   // This next check will only be true if key generation has been bypassed.

   if (retval.z != 1.0) return retval;

   float2 onePixel    = float2 (KeySoftAmount / _OutputWidth, 0.0);
   float2 twoPixels   = onePixel + onePixel;
   float2 threePixels = onePixel + twoPixels;

   // Calculate return retval;

   retval.x *= blur [0];
   retval.x += tex2D (RawKey, uv2 + onePixel).x    * blur [1];
   retval.x += tex2D (RawKey, uv2 - onePixel).x    * blur [1];
   retval.x += tex2D (RawKey, uv2 + twoPixels).x   * blur [2];
   retval.x += tex2D (RawKey, uv2 - twoPixels).x   * blur [2];
   retval.x += tex2D (RawKey, uv2 + threePixels).x * blur [3];
   retval.x += tex2D (RawKey, uv2 - threePixels).x * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Blur 2
//
// Adds the vertical component of a box blur.  Added a check for a valid key presence
// at the start of the shader using the new flag in retval.z.  If it isn't set, quit.
//-----------------------------------------------------------------------------------------//

DeclarePass (FullKey)
{
   float4 retval = tex2D (Blur_X, uv2);

   if (retval.z != 1.0) return retval;

   float2 onePixel    = float2 (0.0, KeySoftAmount / _OutputHeight);
   float2 twoPixels   = onePixel + onePixel;
   float2 threePixels = onePixel + twoPixels;

   // Calculate return retval;

   retval.x *= blur [0];
   retval.x += tex2D (Blur_X, uv2 + onePixel).x    * blur [1];
   retval.x += tex2D (Blur_X, uv2 - onePixel).x    * blur [1];
   retval.x += tex2D (Blur_X, uv2 + twoPixels).x   * blur [2];
   retval.x += tex2D (Blur_X, uv2 - twoPixels).x   * blur [2];
   retval.x += tex2D (Blur_X, uv2 + threePixels).x * blur [3];
   retval.x += tex2D (Blur_X, uv2 - threePixels).x * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Main keyer
//
// Blend the foreground with the background using the key that was built earlier.
// Apply spill suppression as we go.
//
// New: 1. Original foreground sampler replaced with transform version.
//      2. Original background sampler replaced with generated cyclorama.
//      3. The invert key code has been removed.
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ChromakeyAndBg)
{
   float4 Fgd = tex2D (fgVid, uv2);
   float4 Bgd = tex2D (bgVid, uv2);          // Here we recover the cyclorama background.
   float4 Key = tex2D (FullKey, uv2);

   // Key.w = spill removal amount
   // Key.x = blurred key
   // Key.y = raw, unblurred key

   // Using min (Key.x, Key.y) means that any softness around the key causes the
   // foreground to shrink in from the edges.

   float maskAmount = tex2D (Mask, uv2).x;
   float mixAmount  = saturate ((1.0 - min (Key.x, Key.y) * Fgd.a) * 2.0);

   // If we just want to show the key we can get out now.  Because we no longer have the
   // invert key function this process has become simpler than the Lightworks original.

   if (Reveal) return lerp (0.0.xxxx, float4 (mixAmount.xxx, 1.0), maskAmount);

   // Perform spill removal on the foreground if necessary

   if (Key.w > 0.8) {
      float4 FgdLum = float4 (((Fgd.r + Fgd.g + Fgd.b) / 3.0).xxx, 1.0);

      Fgd = lerp (Fgd, FgdLum, ((Key.w - 0.8) * 5.0) * RemoveSpill);    // Remove spill.
   }

   float4 retval = lerp (Fgd, Bgd, mixAmount * Bgd.a);

   retval.a = max (Bgd.a, 1.0 - mixAmount);

   return lerp (Bgd, retval, maskAmount);
}

