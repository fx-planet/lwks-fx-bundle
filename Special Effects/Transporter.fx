// @Maintainer jwrl
// @Released 2023-01-11
// @Author jwrl
// @Author LWKS Software Ltd
// @Created 2023-01-11
// @Licence LWKS Software Ltd.  All Rights Reserved

/**
 This is a customised version of the Lightworks Chromakey effect with a transitional
 Star Trek-like transporter sparkle effect added.  This is definitely not a copy of
 any of the Star Trek versions of that effect, nor is it intended to be.  At most it
 should be regarded as an interpretation of the idea behind the effect.

 The transition is quite complex.  During the first 0.3 of the transition progress the
 sparkles/stars build, then hold for the next 0.4 of the transition.  They then decay.
 Under that, after the first 0.3 of the transition the chromakey starts a linear fade
 in, reaching full value at 70% of the transition progress.  When the transition is at
 100% the result is exactly the same as a standard chromakey.

 Because significant sections of this effect are copyright (c) LWKS Software Ltd and
 all rights are reserved it cannot be used in other effects in whole or in part without
 the express written permission of LWKS Software Ltd.  The additional DVE component and
 the sparkle generation is an original implementation, although it is based on common
 algorithms.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Transporter.fx
//
// Version history:
//
// Built 2023-01-11 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Transporter", "Key", "Special Effects", "A modified chromakey to provide a Star Trek-like transporter effect", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Transition, "Transition", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareColourParam (KeyColour, "Key Colour", kNoGroup, "SpecifiesColourRange", 150.0, 0.7, 0.75, 0.0);
DeclareColourParam (Tolerance, "Tolerance", kNoGroup, "SpecifiesColourRange|Hidden", 20.0, 0.3, 0.25, 0.0);
DeclareColourParam (ToleranceSoftness, "Tolerance softness", kNoGroup, "SpecifiesColourRange|Hidden", 15.0, 0.115, 0.11, 0.0);

DeclareFloatParam (KeySoftAmount, "Key softness", "Key settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (RemoveSpill, "Remove spill", "Key settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareBoolParam (NoAlpha, "Ignore foreground alpha", "Key settings", false);

DeclareFloatParam (CentreX, "Position", "DVE", "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (CentreY, "Position", "DVE", "SpecifiesPointY", 0.0, -1.0, 1.0);
DeclareFloatParam (CentreZ, "Position", "DVE", "SpecifiesPointZ", 0.0, -1.0, 1.0);

DeclareFloatParam (CropLeft, "Top left", "Crop", "SpecifiesPointX", 0.0, 0.0, 1.0);
DeclareFloatParam (CropTop, "Top left", "Crop", "SpecifiesPointY", 1.0, 0.0, 1.0);
DeclareFloatParam (CropRight, "Bottom right", "Crop", "SpecifiesPointX", 1.0, 0.0, 1.0);
DeclareFloatParam (CropBottom, "Bottom right", "Crop", "SpecifiesPointY", 0.0, 0.0, 1.0);

DeclareFloatParam (starSize, "Spot size", "Sparkle", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (starLength, "Star length", "Sparkle", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (starStrength, "Star strength", "Sparkle", kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (starColour, "Colour", "Sparkle", kNoFlags, 0.9, 0.75, 0.0, 1.0);

DeclareBoolParam (HideBgd, "Hide background", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define AllPos(XYZ) (min (XYZ.x, min (XYZ.y, XYZ.z)) > 0.0)

#define HUE_IDX   0
#define SAT_IDX   1
#define VAL_IDX   2

#define MIN_TOL   0.00390625
#define ONE_SIXTH 0.1666666667
#define HALF_PI   1.5707963268

#define W_SCALE   0.0005208
#define S_SCALE   0.000868
#define FADER     0.9333333333
#define FADE_DEC  0.0666666667

float _Pascal [] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// These first two shaders simply isolate the foreground and background nodes from the
// resolution.  After this process they can be accessed using TEXCOORD3 coordinates.
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

//-----------------------------------------------------------------------------------------//
// The DVE and has been added to give masking, scaling and position adjustment.
//-----------------------------------------------------------------------------------------//

DeclarePass (DVE)
{
   // First set up the scale factor, using the Z axis position.  Unlike the Lightworks
   // 3D DVE the transition isn't linear and operates smallest to largest.  Since it has
   // been designed to fine tune position it does not cover the full range of the 3D DVE.

   float Xcntr = 0.5 - CentreX;
   float Ycntr = 0.5 + CentreY;
   float scale = pow (max ((CentreZ + 1.0) * 0.5, 0.0001) + 0.5, 4.0);

   // Set up the image position

   float2 xy = ((uv3 - 0.5.xx) / scale) + float2 (Xcntr, Ycntr);

   // Now return the cropped and resized image.  To ensure that we don't get half pixel
   // oddities at the edge of frame we limit the range to 0.0 - 1.0.  This ensures that
   // we don't get over- or underflow.  If we do, black with no alpha is returned.

   float left = max (0.0, ((CropLeft - 0.5) / scale + Xcntr));
   float top = max (0.0, ((0.5 - CropTop) / scale + Ycntr));
   float right = min (1.0, ((CropRight - 0.5) / scale + Xcntr));
   float bottom = min (1.0, ((0.5 - CropBottom) / scale + Ycntr));

   if ((xy.x < left) || (xy.x > right) || (xy.y < top) || (xy.y > bottom)) return kTransparentBlack;

   // Finally, if we don't want to use the foreground alpha, it's turned on regardless
   // of its actual value.

   return NoAlpha ? float4 (tex2D (Fgd, xy).rgb, 1.0) : tex2D (Fgd, xy);
}

//-----------------------------------------------------------------------------------------//
// This generates the key by converting the source to HSV and then computing its
// similarity with the specified key colour.  It uses the DVE sampler for input instead
// of the original foreground sampler.  New code then checks for the presence of alpha
// data, and if there is none, returns.  This is the same result as that produced if the
// foreground colour exactly matches the key colour.
//
// From that point on the code is as used in the original effect.  Some const variables
// have been replaced with actual values.
//-----------------------------------------------------------------------------------------//

DeclarePass (RawKey)
{
   float4 rgba = tex2D (DVE, uv3);

   // Check if alpha is zero and if it is we need do nothing.  There is no image so quit.

   if (rgba.a == 0.0) return rgba;

   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   float4 hsva = 0.0.xxxx;
   float4 tolerance1 = Tolerance + MIN_TOL.xxxx;
   float4 tolerance2 = tolerance1 + ToleranceSoftness;

   float maxComponentVal = max (max (rgba.r, rgba.g), rgba.b);
   float minComponentVal = min (min (rgba.r, rgba.g), rgba.b);
   float componentRange  = maxComponentVal - minComponentVal;

   hsva [VAL_IDX] = maxComponentVal;
   hsva [SAT_IDX] = componentRange / maxComponentVal;

   if (hsva [SAT_IDX] == 0.0) { hsva [HUE_IDX] = 0.0; }     // undefined
   else {
      if (rgba.r == maxComponentVal) {
         hsva [HUE_IDX] = (rgba.g - rgba.b) / componentRange;
      }
      else if (rgba.g == maxComponentVal) {
         hsva [HUE_IDX] = 2.0 + ((rgba.b - rgba.r) / componentRange);
      }
      else hsva [HUE_IDX] = 4.0 + ((rgba.r - rgba.g) / componentRange);

      hsva [HUE_IDX] *= ONE_SIXTH;

      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
   }

   // Calc difference between current pixel and specified key-colour

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) diff [HUE_IDX] = 1.0 - diff [HUE_IDX];

   // Work out how transparent/opaque the corrected pixel will be

   float3 range = (tolerance2 - diff).rgb;

   if (AllPos (range)) {
      range = (tolerance1 - diff).rgb;

      if (AllPos (range)) { keyVal = 0.0; }
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

   return float2 (keyVal, 1.0 - hueSimilarity).xxxy;
}

//-----------------------------------------------------------------------------------------//
// This does the horizontal component of the blur used for generating key softness.  It
// has a pseudo random noise generator which returns in Z.  Z was unused in the original
// effect and gives the required noise for the sparkles that the effect needs for the
// final transporter effect.
//-----------------------------------------------------------------------------------------//

DeclarePass (BlurKey1)
{
   float2 xy1 = float2 (KeySoftAmount * W_SCALE, 0.0);
   float2 xy2 = xy1 * 2.0;
   float2 xy3 = xy1 + xy2;

   float4 result = tex2D (RawKey, uv3);

   // Calculate return result;

   result.x *= _Pascal [0];
   result.x += tex2D (RawKey, uv3 + xy1).x * _Pascal [1];
   result.x += tex2D (RawKey, uv3 - xy1).x * _Pascal [1];
   result.x += tex2D (RawKey, uv3 + xy2).x * _Pascal [2];
   result.x += tex2D (RawKey, uv3 - xy2).x * _Pascal [2];
   result.x += tex2D (RawKey, uv3 + xy3).x * _Pascal [3];
   result.x += tex2D (RawKey, uv3 - xy3).x * _Pascal [3];

   float scale = (1.0 - starSize) * 800.0;
   float seed  = Transition;
   float Y = saturate ((round (uv3.y * scale) / scale) + 0.000123);

   scale *= _OutputAspectRatio;

   float X = saturate ((round (uv3.x * scale) / scale) + 0.00013);
   float rndval = frac (sin ((X * 13.9898) + (Y * 79.233) + seed) * 43758.5453);

   rndval = sin (X) + cos (Y) + rndval * 1000.0;
   scale = (starStrength * 0.3) - 0.15;

   float amt   = (frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0) + scale;
   float alpha = max (0.0, abs (sin (Transition * HALF_PI) - 0.5) - 0.2) + 2.7;

   result.z = amt <= alpha ? 0.0 : tex2D (RawKey, uv3).y;

   return result;
}

//-----------------------------------------------------------------------------------------//
// This does the vertical component of the blur used for generating key softness.  It
// also supplies gated noise in Z which is used to create the star/sparkle effect for
// the transporter.
//-----------------------------------------------------------------------------------------//

DeclarePass (BlurKey2)
{
   float2 xy1 = float2 (0.0, KeySoftAmount * _OutputAspectRatio * W_SCALE);
   float2 xy2 = xy1 + xy1;
   float2 xy3 = xy1 + xy2;

   float4 result = tex2D (BlurKey1, uv3);

   // Calculate return result;

   result.x *= _Pascal [0];
   result.x += tex2D (BlurKey1, uv3 + xy1).x * _Pascal [1];
   result.x += tex2D (BlurKey1, uv3 - xy1).x * _Pascal [1];
   result.x += tex2D (BlurKey1, uv3 + xy2).x * _Pascal [2];
   result.x += tex2D (BlurKey1, uv3 - xy2).x * _Pascal [2];
   result.x += tex2D (BlurKey1, uv3 + xy3).x * _Pascal [3];
   result.x += tex2D (BlurKey1, uv3 - xy3).x * _Pascal [3];

   float stars = 0.0;
   float fader = FADER;

   xy1 = 0.0.xx;
   xy2 = 0.0.xx;
   xy3 = float2 (starLength * S_SCALE, 0.0);

   float2 xy4 = xy3.yx * _OutputAspectRatio;

   for (int i = 0; i <= 15; i++) {
      stars += tex2D (BlurKey1, uv3 + xy1).z * fader;
      stars += tex2D (BlurKey1, uv3 - xy1).z * fader;
      stars += tex2D (BlurKey1, uv3 + xy2).z * fader;
      stars += tex2D (BlurKey1, uv3 - xy2).z * fader;

      xy1 += xy3;
      xy2 += xy4;
      fader -= FADE_DEC;
   }

   result.z = saturate (max (tex2D (BlurKey1, uv3).z, stars));

   return result;
}

//-----------------------------------------------------------------------------------------//
// Blends the foreground with the background using the key that was built earlier.  Spill
// suppression is also performed.
//
// Key channels used: 1.  key.w = spill removal amount
//                    2.  key.x = blurred key
//                    3.  key.y = raw, unblurred key
//                    4.  key.z = star key for sparkle generation
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Transporter1)
{
   float4 Fgnd = tex2D (DVE, uv3);
   float4 key  = tex2D (BlurKey2, uv3);

   // Using min (key.x, key.y) means that any softness around the key causes the
   // foreground to shrink in from the edges.

   float mix = saturate ((1.0 - min (key.x, key.y) * Fgnd.a) * 2.0);

   if (key.w > 0.8) {

      // This next section has been slightly rewritten to correct for a potential
      // cross-platform issue.

      float fgLum = (Fgnd.r + Fgnd.g + Fgnd.b) / 3.0;    // Originally a float4

      // Remove spill.  Now swizzle fgLum to float4 here and change the original
      // divide by 0.2 to a multiply by 5.0.  Functionally the same, but simpler.

      Fgnd = lerp (Fgnd, fgLum.xxxx, (key.w - 0.8) * RemoveSpill * 5.0);
   }

   float4 Bgnd = HideBgd ? kTransparentBlack : tex2D (Bgd, uv3);
   float4 result = lerp (Fgnd, Bgnd, mix * Bgnd.a);

   result.a = max (Bgnd.a, 1.0 - mix);

   float Amount = min (max (sin (Transition * HALF_PI) - 0.3, 0.0) * 2.5, 1.0);

   result = lerp (Bgnd, result, Amount);

   Amount = saturate ((0.5 - abs (Transition - 0.5)) * 4.0);

   return lerp (result, starColour, key.z * Amount);
}

