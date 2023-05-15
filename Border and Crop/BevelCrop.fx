// @Maintainer jwrl
// @Released 2023-05-15
// @Author jwrl
// @Created 2019-11-06

/**
 This is a crop tool that provides a bevelled border.  The lighting of the bevel can be
 adjusted in intensity, and the lighting angle can be changed.  Fill lighting is also
 included to soften the shaded areas of the bevel.  A hard-edged drop shadow is provided
 which simply shades the background by an adjustable amount.

 X-Y positioning of the border and its contents has been included, but since this is not
 intended as a comprehensive DVE replacement that's as far as it goes.  There isn't any
 scaling or rotation provided, nor is there intended to be.  It's complex enough for the
 user as it is!!!

 Any alpha information in the foreground is discarded by this effect.  This means that
 wherever the foreground and bevelled border appears will be opaque black.  The
 background alpha is preserved.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BevelCrop.fx
//
// Version history:
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bevel edged crop", "DVE", "Border and Crop", "This provides a simple crop with a bevelled border and a hard-edged drop shadow", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (CropLeft, "Top left", "Crop", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (CropTop, "Top left", "Crop", "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (CropRight, "Bottom right", "Crop", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (CropBottom, "Bottom right", "Crop", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (Scale, "Size", kNoGroup, "DisplayAsPercentage", 1.0, 0.1, 5.0);
DeclareFloatParam (PosX, "Position", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (PosY, "Position", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Border, "Width", "Border", kNoFlags, 0.25, 0.0, 1.0);
DeclareColourParam (Colour, "Colour", "Border", kNoFlags, 0.375, 0.625, 0.75, 1.0);

DeclareFloatParam (Bevel, "Percent width", "Bevel", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Intensity, "Light level", "Bevel", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle, "Light angle", "Bevel", kNoFlags, 80.0, -180.0, 180.0);
DeclareFloatParam (Fill, "Fill light", "Bevel", kNoFlags, 0.4, 0.0, 1.0);
DeclareColourParam (Light, "Colour", "Bevel", kNoFlags, 0.375, 0.625, 0.75, 1.0);

DeclareFloatParam (Strength, "Strength", "Drop shadow", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (ShadowX, "Offset", "Drop shadow", "SpecifiesPointX", -0.25, -1.0, 1.0);
DeclareFloatParam (ShadowY, "Offset", "Drop shadow", "SpecifiesPointY", -0.25, -1.0, 1.0);
DeclareColourParam (Shade, "Colour", "Drop shadow", kNoFlags, 0.125, 0.2, 0.25, 1.0);

DeclareBoolParam (CropToBgd, "Crop foreground to background", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SCALE  0.1
#define SHADOW 0.025

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_rgb2hsv (float3 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float3 hsv  = float3 (0.0.xx, Cmax);

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float3 fn_hsv2rgb (float3 hsv)
{
   if (hsv.y == 0.0) return hsv.zzz;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (2.0 - hsv.y) - q;

   if (i == 0) return float3 (hsv.z, r, p);
   if (i == 1) return float3 (q, hsv.z, p);
   if (i == 2) return float3 (p, hsv.z, r);
   if (i == 3) return float3 (p, q, hsv.z);
   if (i == 4) return float3 (r, p, hsv.z);

   return float3 (hsv.z, p, q);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Bvl)
{
   // Get the foreground but discard the alpha channel after first using it to mask
   // transparent sections of the image to black.

   float4 Fgnd = ReadPixel (Fg, uv1);

   float3 retval = lerp (kTransparentBlack, Fgnd, Fgnd.a).rgb;

   // Now set up the crop boundaries, the size of the border and the percentage of the
   // border that we want to be bevelled.

   float2 cropSize   = float2 (abs (CropRight - CropLeft), abs (CropTop - CropBottom));
   float2 cropBevel  = float2 (1.0, _OutputAspectRatio) * Border * SCALE;
   float2 cropBorder = cropBevel + cropSize;

   // Because we have to be able to obtain an accurate 45 degree angle at the corners
   // of the bevel we need to set up several xy coordinates.  For ease of later maths
   // we swing uv around the mid point of the crop and put that value in xy1.  This
   // will be used later to determine which quadrant we're working in.

   float2 xy1 = uv0 - float2 (CropRight + CropLeft, 2.0 - CropTop - CropBottom) / 2.0;

   // The absolute value of xy1 is doubled and stored in xy2.  This can be used to
   // produce the crop simply later.

   float2 xy2 = abs (xy1) * 2.0;

   // The crop size is then subtracted from xy2 and clamped between 0 and 1.  By
   // doing this we can reliably calculate the corner angle without resorting to
   // trig functions or distance calculations.

   float2 xy3 = saturate (xy2 - cropSize);

   // The X coordinate of xy3 must be corrected for the project aspect ratio, and
   // the bevel thickness is also calculated as a percentage of the border width.

   xy3.x *= _OutputAspectRatio;
   cropBevel = cropBorder - (cropBevel * saturate (Bevel));

   // The border colour is now applied.  If either component of xy2 exceeds the crop
   // size we replace the foreground already in retval with our border colour.

   if ((xy2.x > cropSize.x) || (xy2.y > cropSize.y)) retval = Colour.rgb;

   // The next section calculates the bevel colours.  If either component of xy2 exceeds
   // the bevel bounary we replace the border colour in retval with our derived bevel
   // colour.  This is reasonably complex to do because we need to be able to change the
   // angle of the bevel lighting in a way logical for the user.

   if ((xy2.x > cropBevel.x) || (xy2.y > cropBevel.y)) {

      // Bevel lighting is calculated in the hue/sat/value domain.  While it would be
      // possible to do this in the RGB domain, this way is much simpler.

      float3 hsv = fn_rgb2hsv (Light.rgb);

      // The lit values of the X and Y planes are calulated trigonometrically.  This
      // is the only time that a trig function is required in this routine.  Instead of
      // swinging between +1 and -1 we need to swing from 0 to 1 for later level maths.

      float2 lit;

      sincos (radians (Angle), lit.x, lit.y);
      lit = (lit + 1.0.xx) * 0.5;

      // This sets up the amount by which to adjust the bevel colour.  If xy1.y is less
      // than zero we're in the lower half of the border, and the bevel amt can be set
      // to lit.y.  Otherwise it is inverted by subtracting lit.y from 1.0.

      float amt = (xy1.y > 0.0) ? 1.0 - lit.y : lit.y;

      // The values of amt at either side are now set up.  If we're on the left hand
      // side and if xy3.x is greater than xy3.y we invert the value in lit.x and put
      // it in amt.  Because of the earlier clamping and scaling of xy3 this gives us
      // an accurate 45 degree angle at top and bottom right the corners.  A similar
      // test is used to replace amt with the value in lit.x on the right hand side.

      if (xy1.x > 0.0) {
         if (xy3.x > xy3.y) {
            amt = lit.x;
         }
      }
      else if (xy3.x > xy3.y) amt = 1.0 - lit.x;

      // The border amount is now scaled by the intensity and the fill is added.  Both
      // are adjusted before application so that the parameter settings make sense to
      // the user.  The result is then inverted, clamped and scaled by 6.

      amt = (amt * Intensity * 2.0) + Fill;
      amt = saturate (1.5 - amt) * 6.0;

      // This test converts amt to swing between 0.25 and 1.0 for positive exposure
      // values, and between 1.0 and 4.0 for negative exposure.

      amt = (amt >= 3.0) ? amt - 2.0 : 1.0 / (4.0 - amt);

      // The border value is halved and amt is used as the power to raise it to.  It's
      // then checked for overflow to see if we also need to desaturate then doubled.
      // Both value and saturation are clamped between 0 and 1 after adjustment.

      hsv.z = pow (hsv.z * 0.5, amt);

      if (hsv.z > 0.5) hsv.y = saturate (hsv.y - hsv.z + 0.5);

      hsv.z = saturate (hsv.z * 2.0);

      // The complete border including the bevel is converted and placed in retval.

      retval = fn_hsv2rgb (hsv);
   }

   // We now turn the alpha channel on and blank anything outside the border boundary.

   return ((xy2.x > cropBorder.x) || (xy2.y > cropBorder.y)) ? kTransparentBlack : float4 (retval, 1.0);
}

DeclareEntryPoint (BevelCrop)
{
   // First we check to see if we're outside the background and masked and quit if so

   if (CropToBgd && IsOutOfBounds (uv2)) return kTransparentBlack;

   // Now we calculate the position offset and and scale and put it in xy1.  The
   // drop shadow is also calculated and placed in xy2.  While it would be possible
   // to use the bevel angle parameter to do this, it's much simpler this way.

   float2 xy1 = ((uv3 - float2 (PosX, 1.0 - PosY)) / max (1e-6, Scale)) + 0.5.xx;
   float2 xy2 = xy1 - float2 (ShadowX, -ShadowY * _OutputAspectRatio) * SHADOW;

   // The alpha channel in Bvl is obtained using xy2 and scaled by the drop shadow
   // strength parameter.  This is used later to create our drop shadow.

   float alpha = ReadPixel (Bvl, xy2).a * Strength;

   // The foreground is recovered from Bvl using the position corrected xy1 and the
   // background is recovered using the uv coordinates directly.

   float4 Fgnd = tex2D (Bvl, xy1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   // The background now has the drop shadow applied.  Note that opacity is preserved.

   Bgnd.rgb = lerp (Bgnd.rgb, Shade.rgb, alpha);

   // Finally the bevelled cropped image is overlaid and the whole thing is returned.

   return lerp (Bgnd, Fgnd, Fgnd.a);
}
