// @Maintainer jwrl
// @Released 2023-06-19
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
// Updated 2023-06-19 jwrl.
// Changed DVE reference to transform.
//
// Updated 2023-06-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-27 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chromakey with transform", "Key", "Key Extras", "A Chromakey effect with cropping and a simple transform effect", CanSize);

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

#define allPos(RGB) (all (RGB > 0.0))

#define HUE_IDX 0          // LWKS chromakey definitions
#define SAT_IDX 1
#define VAL_IDX 2

float _FallOff = 0.12;
float _oneSixth = 1.0 / 6.0;
float _minTolerance = 1.0 / 256.0;

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0  / 64.0, 1.0  / 64.0 };  // Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// Transform
//
// A much cutdown version of the standard transform effect, this version doesn't include
// cropping or drop shadow generation which would be pointless in this configuration.
//-----------------------------------------------------------------------------------------//

DeclarePass (DVEvid)
{
   // The first section adjusts the position allowing for the foreground orientation.

   float2 pos = abs (abs (_FgOrientation - 90) - 90)
              ? 0.5.xx - float2 (CentreY, CentreX)
              : float2 (0.5 - CentreX, CentreY - 0.5);

   if (_FgOrientation > 90) { pos = -pos; }

   float2 xy = uv1 + (pos * abs (_FgExtents.xy - _FgExtents.zw));
   float2 scale = MasterScale * float2 (XScale, YScale);

   xy = ((xy - 0.5.xx) / scale) + 0.5.xx;

   // That's all we need.  Now the scaled and positioned foreground is returned.

   return ReadPixel (Fg, xy);
}

//-----------------------------------------------------------------------------------------//
// Key generation
//
// Convert the source to HSV and then compute its similarity to the specified key colour
//-----------------------------------------------------------------------------------------//

DeclarePass (RawKey)
{
   float4 Fgnd = ReadPixel (DVEvid, uv3);

   // This first block of code converts the input RGB to HSV for the colour match.

   float4 hsva = kTransparentBlack;

   float maxComponentVal = max (max (Fgnd.r, Fgnd.g), Fgnd.b);
   float minComponentVal = min (min (Fgnd.r, Fgnd.g), Fgnd.b);
   float componentRange  = maxComponentVal - minComponentVal;

   hsva [VAL_IDX] = maxComponentVal;
   hsva [SAT_IDX] = componentRange / maxComponentVal;

   if (hsva [SAT_IDX] != 0.0) {
      if (Fgnd.r == maxComponentVal) { hsva [HUE_IDX] = (Fgnd.g - Fgnd.b) / componentRange; }
      else if (Fgnd.g == maxComponentVal) { hsva [HUE_IDX] = 2.0 + ((Fgnd.b - Fgnd.r) / componentRange); }
      else hsva [HUE_IDX] = 4.0 + ((Fgnd.r - Fgnd.g) / componentRange);

      hsva [HUE_IDX] *= _oneSixth;

      if (hsva [HUE_IDX] < 0.0) { hsva [HUE_IDX] += 1.0; }
   }

   // Calculate the difference between current pixel and specified key colour

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) { diff [HUE_IDX] = 1.0 - diff [HUE_IDX]; }

   // Work out the opacity of the corrected pixel

   diff -= Tolerance + _minTolerance;

   float4 colourmatch = ToleranceSoftness - diff;

   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   if (allPos (colourmatch)) {
      if (allPos (diff)) {
         hueSimilarity = diff [HUE_IDX];
         diff /= ToleranceSoftness;
         keyVal = max (diff [HUE_IDX], max (diff [SAT_IDX], diff [VAL_IDX]));
         keyVal = pow (keyVal, 0.25);
         }
      else keyVal = 0.0;
      }
   else hueSimilarity = diff [HUE_IDX];

   return float4 (keyVal.xxx, 1.0 - hueSimilarity);
}

//-----------------------------------------------------------------------------------------//
// Blur 1
//
// Blurs the key horizontally using Pascal's triangle
//-----------------------------------------------------------------------------------------//

DeclarePass (BlurKey)
{
   float2 onePixel = float2 (KeySoftAmount / _OutputWidth, 0.0);
   float2 twoPixel = onePixel * 2.0;
   float2 threePix = onePixel * 3.0;

   float4 retval = tex2D (RawKey, uv3);

   retval.x *= blur [0];
   retval.x += tex2D (RawKey, uv3 + onePixel).x * blur [1];
   retval.x += tex2D (RawKey, uv3 - onePixel).x * blur [1];
   retval.x += tex2D (RawKey, uv3 + twoPixel).x * blur [2];
   retval.x += tex2D (RawKey, uv3 - twoPixel).x * blur [2];
   retval.x += tex2D (RawKey, uv3 + threePix).x * blur [3];
   retval.x += tex2D (RawKey, uv3 - threePix).x * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Blur 2
//
// Blurs the key vertically
//-----------------------------------------------------------------------------------------//

DeclarePass (FullKey)
{
   float2 onePixel = float2 (0.0, KeySoftAmount / _OutputHeight);
   float2 twoPixel = onePixel * 2.0;
   float2 threePix = onePixel * 3.0;

   float4 retval = tex2D (BlurKey, uv3);

   retval.x *= blur [0];
   retval.x += tex2D (BlurKey, uv3 + onePixel).x * blur [1];
   retval.x += tex2D (BlurKey, uv3 - onePixel).x * blur [1];
   retval.x += tex2D (BlurKey, uv3 + twoPixel).x * blur [2];
   retval.x += tex2D (BlurKey, uv3 - twoPixel).x * blur [2];
   retval.x += tex2D (BlurKey, uv3 + threePix).x * blur [3];
   retval.x += tex2D (BlurKey, uv3 - threePix).x * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Main code
//
// Blends the cropped, resized and positioned foreground with the background using the
// key that was built in the key generation pass.   Applies spill suppression as we go.
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ChromakeyTransform)
{
   float4 key = tex2D (FullKey, uv3);
   float4 fg  = tex2D (DVEvid, uv3);
   float4 bg  = ReadPixel (Bg, uv2);
   float4 retval;

   // key.w = spill removal amount
   // key.x = blurred key
   // key.y = raw, unblurred key

   // Using min (key.x, key.y) means that any softness around the key causes the foreground
   // to shrink in from the edges.

   float mix = saturate ((1.0 - min (key.x, key.y) * fg.a) * 2.0);

   // This section of the Lightworks key process previously took into account the presence
   // of transparency in the background video, and killed the foreground key if so.  That
   // has now been corrected and doesn't appear to have had any adverse effect on the result.
   // I believe that it was done mistakenly when what was intended was simply to pass any
   // alpha in the background video on for further use, which this version still does.

   if (Reveal) { retval = float4 ((Invert ? 1.0 - mix : mix).xxx, 1.0); }
   else {
      if (Invert) { retval = float4 (lerp (bg.rgb, fg.rgb, mix), max (bg.a, mix)); }
      else {
         if (key.w > 0.8) {
            float4 fgLum = (fg.x + fg.g + fg.b) / 3.0;

            fg = lerp (fg, fgLum, ((key.w - 0.8) / 0.2) * RemoveSpill);
         }

         retval = float4 (lerp (fg.rgb, bg.rgb, mix), max (bg.a, 1.0 - mix));
      }

      retval = lerp (bg, retval, Opacity);
   }

   return lerp (bg, retval, tex2D (Mask, uv3).x);
}

