// @Maintainer jwrl
// @Released 2023-09-05
// @Author jwrl
// @Created 2018-03-20

/**
 This effect is a customised version of the Lightworks Chromakey effect with cropping and
 some simple transform adjustments added.  The ChromaKey section is copyright (c) LWKS
 Software Ltd., modified to improve keying over transparent backgrounds.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyTransform.fx
//
// Version history:
//
// Updated 2023-09-05 jwrl.
// Optimised the code to resolve a Linux/Mac compatibility issue.
//
// Updated 2023-06-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-27 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chromakey with transform", "Key", "Key Extras", "A Chromakey effect with cropping and a simple DVE", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareColourParam (KeyColour, "Key colour", "Chromakey", "SpecifiesColourRange", 150.0, 0.8, 0.8, -1.0);
DeclareColourParam (Tolerance, "Tolerance", "Chromakey", "SpecifiesColourRange|Hidden", 20.0, 0.2, 0.2, -1.0);
DeclareColourParam (ToleranceSoftness, "Tolerance softness", "Chromakey", "SpecifiesColourRange|Hidden", 10.0, 0.1, 0.1, -1.0);

DeclareFloatParam (KeySoftAmount, "Key softness", "Chromakey", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (RemoveSpill, "Remove spill", "Chromakey", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Invert, "Invert", "Chromakey", false);
DeclareBoolParam (Reveal, "Reveal", "Chromakey", false);

DeclareFloatParam (CentreX, "Position", "Foreground transform", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (CentreY, "Position", "Foreground transform", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareFloatParam (MasterScale, "Master", "Foreground scale", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (XScale, "Width", "Foreground scale", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (YScale, "Height", "Foreground scale", kNoFlags, 1.0, 0.0, 10.0);

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareIntParam (_FgOrientation);
DeclareFloat4Param (_FgExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HUE_IDX 0          // LWKS chromakey definitions
#define SAT_IDX 1
#define VAL_IDX 2

float _FallOff = 0.12;
float _oneSixth = 1.0 / 6.0;
float _minTolerance = 1.0 / 256.0;

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0  / 64.0, 1.0  / 64.0 };  // Pascal's Triangle

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
// A much cutdown version of the standard transform effect, this version doesn't include
// cropping or drop shadow generation which would be pointless in this configuration.
//-----------------------------------------------------------------------------------------//

DeclarePass (fgVid)
{
   // The first section adjusts the position allowing for the foreground orientation.

   float2 pos = (_FgOrientation == 0) || (_FgOrientation == 180)
              ? float2 (0.5 - CentreX, CentreY - 0.5)
              : 0.5.xx - float2 (CentreY, CentreX);

   if (_FgOrientation > 90) { pos = -pos; }

   float2 xtnts = float2 (_FgExtents.x - _FgExtents.z, _FgExtents.y - _FgExtents.w);
   float2 scale = MasterScale * float2 (XScale, YScale);
   float2 xy = uv1 + (pos * abs (xtnts)) - 0.5.xx;

   xy /= scale;
   xy += 0.5.xx;

   // That's all we need.  Now the scaled and positioned foreground is returned.

   return ReadPixel (Fg, xy);
}

DeclarePass (bgVid)
{ return ReadPixel (Bg, uv2); }

//-----------------------------------------------------------------------------------------//
// Key generation
//
// Convert the source to HSV and then compute its similarity to the specified key colour
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
   float4 rgba = tex2D (fgVid, uv3);
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
   float4 retval = tex2D (RawKey, uv3);

   // This next check will only be true if key generation has been bypassed.

   if (retval.z != 1.0) return retval;

   float2 onePixel    = float2 (KeySoftAmount / _OutputWidth, 0.0);
   float2 twoPixels   = onePixel + onePixel;
   float2 threePixels = onePixel + twoPixels;

   // Calculate return retval;

   retval.x *= blur [0];
   retval.x += tex2D (RawKey, uv3 + onePixel).x    * blur [1];
   retval.x += tex2D (RawKey, uv3 - onePixel).x    * blur [1];
   retval.x += tex2D (RawKey, uv3 + twoPixels).x   * blur [2];
   retval.x += tex2D (RawKey, uv3 - twoPixels).x   * blur [2];
   retval.x += tex2D (RawKey, uv3 + threePixels).x * blur [3];
   retval.x += tex2D (RawKey, uv3 - threePixels).x * blur [3];

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
   float4 retval = tex2D (Blur_X, uv3);

   if (retval.z != 1.0) return retval;

   float2 onePixel    = float2 (0.0, KeySoftAmount / _OutputHeight);
   float2 twoPixels   = onePixel + onePixel;
   float2 threePixels = onePixel + twoPixels;

   // Calculate return retval;

   retval.x *= blur [0];
   retval.x += tex2D (Blur_X, uv3 + onePixel).x    * blur [1];
   retval.x += tex2D (Blur_X, uv3 - onePixel).x    * blur [1];
   retval.x += tex2D (Blur_X, uv3 + twoPixels).x   * blur [2];
   retval.x += tex2D (Blur_X, uv3 - twoPixels).x   * blur [2];
   retval.x += tex2D (Blur_X, uv3 + threePixels).x * blur [3];
   retval.x += tex2D (Blur_X, uv3 - threePixels).x * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Main keyer
//
// Blend the foreground with the background using the key that was built earlier.
// Apply spill suppression as we go.  The foreground sampler has been replaced with
// the transformed version.
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ChromakeyTransform)
{
   float4 Fgd = tex2D (fgVid, uv3);
   float4 Bgd = tex2D (bgVid, uv3);
   float4 Key = tex2D (FullKey, uv3);

   // Key.w = spill removal amount
   // Key.x = blurred key
   // Key.y = raw, unblurred key

   // Using min (Key.x, Key.y) means that any softness around the key causes the
   // foreground to shrink in from the edges.  After we derive the mix amount we
   // invert the spill removal and the mix amount if necessary.

   float maskAmount = tex2D (Mask, uv3).x;
   float mixAmount  = saturate ((1.0 - min (Key.x, Key.y) * Fgd.a) * 2.0);

   if (Invert) {
      mixAmount = 1.0 - mixAmount;
      Key.w = 1.0 - Key.w;
   }

   // If we just want to show the key we can get out now.

   if (Reveal) return lerp (0.0.xxxx, float4 (mixAmount.xxx, 1.0), maskAmount);

   // Perform spill removal on the foreground if necessary

   if (Key.w > 0.8) {
      float4 FgdLum = float4 (((Fgd.r + Fgd.g + Fgd.b) / 3.0).xxx, 1.0);

      Fgd = lerp (Fgd, FgdLum, ((Key.w - 0.8) * 5.0) * RemoveSpill);    // Remove spill.
   }

   float4 retval = lerp (Bgd, lerp (Fgd, Bgd, mixAmount), Opacity);

   retval.a = max (Bgd.a, 1.0 - mixAmount);

   return lerp (Bgd, retval, maskAmount);
}

