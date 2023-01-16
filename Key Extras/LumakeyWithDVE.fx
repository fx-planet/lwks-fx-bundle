// @Maintainer jwrl
// @Released 2023-01-10
// @Author jwrl
// @Created 2023-01-10

/**
 DESCRIPTION:
 This is a luminance key similar to the Lightworks effect, but with some differences.  A crop
 function and a simple DVE have been included to provide these often-needed functions without
 the need to add any external effects.

 DIFFERENCES:
 The most obvious difference from the Lightworks version is in the way that the parameters
 are identified.  "Tolerance" is labelled "Key clip" in this effect, "Edge Softness" is now
 "Key Softness" and "Invert" has become "Invert key".  These are the industry standard terms
 used for these functions, so this change makes the effect more consistent with any existing
 third party key software.

 Regardless of whether the key is inverted or not, the clip setting in this keyer always works
 from black at 0% to white at 100%.  In the Lightworks effect the equivalent setting changes
 sense when the key is inverted.  This is unexpected to say the least and has been avoided.
 Key softness in this effect is symmetrical around the key edge.  This is consistent with the
 way that a traditional analog luminance keyer works.  The background image can be suppressed
 so that the alpha signal produced can be passed on to other effects.

 DVE AND CROP COMPONENTS:
 Cropping can be set up by dragging the upper left and lower right corners of the crop area
 on the edit viewer, or in the normal way by dragging the sliders.  The crop is a simple hard
 edged one, and operates before the DVE.  The DVE is a simple 2D DVE, and unlike the earlier
 version of this effect scaling is now implemented identically to the Lightworks 2D DVE.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyWithDVE.fx
//
// Version history:
//
// Built 2023-01-10 jwrl
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lumakey with DVE", "Key", "Key Extras", "A keyer which respects any existing foreground alpha and can pass the generated alpha to external effects", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (KeyClip, "Key clip", "Key settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Softness, "Key softness", "Key settings", kNoFlags, 0.1, 0.0, 1.0);

DeclareBoolParam (InvertKey, "Invert key", "Key settings", false);
DeclareBoolParam (ShowAlpha, "Display alpha channel", "Key settings", false);
DeclareBoolParam (HideBg, "Hide background", "Key settings", false);

DeclareFloatParam (CentreX, "Position", "Foreground DVE", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (CentreY, "Position", "Foreground DVE", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareFloatParam (MasterScale, "Master", "DVE Scale", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (XScale, "Width", "DVE Scale", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (YScale, "Height", "DVE Scale", kNoFlags, 1.0, 0.0, 10.0);

DeclareFloatParam (Left, "Left", "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Right, "Right", "Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Top, "Top", "Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bottom, "Bottom", "Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (_FgOrientation);

DeclareFloat4Param (_FgExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define BrdrPixel(SHADER,XY) (IsOutOfBounds(XY) ? BLACK : tex2D(SHADER, XY))

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define SHOW_BGD 1

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// Crop and position parameters
//
// This function recovers cropping and position parameters, corrected for image size,
// rotation and aspect ratio.
//-----------------------------------------------------------------------------------------//

float4 fn_FgParams (out float2 p)
{
   float4 crop = float4 (Left, 1.0 - Top, 1.0 - Right, Bottom);

   p = float2 (0.5 - CentreX, CentreY - 0.5);

   if (abs (abs (_FgOrientation - 90) - 90)) {
      p = 0.5.xx - float2 (CentreY, CentreX);
      crop = crop.wxyz;
   }

   if (_FgOrientation > 90) {
      p = -p;
      crop = crop.zwxy;
   }

   p *= abs (_FgExtents.xy - _FgExtents.zw);

   crop.zw = 1.0 - crop.zw;

   return crop;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (LumakeyWithDVE)
{
   // This DVE section is a much cutdown version of the Lightworks 2D DVE.  It doesn't
   // include drop shadow generation which would be pointless in this configuration.
   // The first section adjusts the position allowing for the foreground resolution.
   // Resolution and orientation corrected cropping is also created.

   float2 pos;

   float4 Crop = fn_FgParams (pos);

   float2 xy = uv1 + pos;
   float2 scale = MasterScale * float2 (XScale, YScale);

   xy = ((xy - 0.5.xx) / scale) + 0.5.xx;

   // Now the scaled, cropped and positioned foreground is recovered along with the
   // background.  Any background transparency is preserved.

   float4 Fgd, Bgd = HideBg ? BLACK : BrdrPixel (Bg, uv2);

   // The crop data is stored as a float4, ordered suc that W corresponds to the
   // bottom edge of the foreground, X to the left, Y to the top, and Z to the right.

   if ((xy.x >= Crop.x) && (xy.x <= Crop.z) && (xy.y >= Crop.y) && (xy.y <= Crop.w)) {
      Fgd = ReadPixel (Fg, xy);
   }
   else Fgd = kTransparentBlack;

   // From now on is the lumakey.  We first set up the key clip and softness from the
   // Fgd luminance.

   float luma  = dot (Fgd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   // Now invert the alpha channel if necessary and combine it with Fgd.a.

   if (InvertKey) alpha = 1.0 - alpha;

   alpha = min (Fgd.a, alpha);

   // Exit, showing the composite result or the alpha channel as opaque white on black.

   return (ShowAlpha) ? lerp (kTransparentBlack, alpha.xxxx, tex2D (Mask, uv1))
                      : lerp (Bgd, lerp (Bgd, Fgd, alpha * Opacity), tex2D (Mask, uv1));
}

