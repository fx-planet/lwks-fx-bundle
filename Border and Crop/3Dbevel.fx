// @Maintainer jwrl
// @Released 2023-01-22
// @Author jwrl
// @Released 2023-01-22

/**
 This is a crop tool that provides a 3D bevelled border.  As the bevel width is adjusted
 it is assumed that the angle of the bevel changes, causing the refraction to change.
 In addition, the lighting of the bevel can be adjusted in intensity, and the lighting
 angle can be changed.  Fill lighting is also included to soften the shaded areas of the
 bevel.  A hard-edged outer border is also included which simply shades the background
 by an adjustable amount.

 X-Y positioning of the border and its contents has been included, and simple scaling is
 available.  Since this is not intended as a comprehensive DVE replacement no X-Y scale
 factors nor rotation have been provided.  Finally, if desired the bevelled foreground
 can be automatically cropped to fit inside the background boundaries.

 Any alpha information in the foreground is discarded by this effect.  This means that
 wherever the foreground and bevelled border appears will be opaque black.  The
 background alpha is preserved.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3Dbevel.fx
//
// Version history:
//
// Built 2023-01-22 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("3D bevelled crop", "DVE", "Border and crop", "This provides a simple crop with an inner 3D bevelled edge and a flat coloured outer border", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Scale, "Size", "Foreground size and position", "DisplayAsPercentage", 1.0, 0.1, 5.0);
DeclareFloatParam (PosX, "Position", "Foreground size and position", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (PosY, "Position", "Foreground size and position", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (CropLeft, "Top left", "Foreground crop", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (CropTop, "Top left", "Foreground crop", "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (CropRight, "Bottom right", "Foreground crop", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (CropBottom, "Bottom right", "Foreground crop", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (Border, "Width", "Border settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareColourParam (Colour, "Colour", "Border settings", kNoFlags, 0.18, 0.06, 0.0, 1.0);

DeclareFloatParam (Bevel, "Width", "Bevel settings", kNoFlags, 0.125, 0.0, 1.0);
DeclareFloatParam (Bstrength, "Strength", "Bevel settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Intensity, "Light level", "Bevel settings", kNoFlags, 0.45, 0.0, 1.0);
DeclareFloatParam (Angle, "Light angle", "Bevel settings", kNoFlags, 80.0, -180.0, 180.0);
DeclareColourParam (Light, "Colour", "Bevel settings", kNoFlags, 1.0, 0.67, 0.0, 1.0);

DeclareBoolParam (CropToBgd, "Crop foreground to background", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define jSaturate(n)    min(max (n, 0.0), 1.0)

#define BEVEL  0.1
#define BORDER 0.0125

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
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bvl)
{
   float4 Fgnd = ReadPixel (Fgd, uv3);

   float3 retval = lerp (kTransparentBlack, Fgnd, Fgnd.a).rgb;

   float2 cropAspect = float2 (1.0, _OutputAspectRatio);
   float2 centreCrop = float2 (abs (CropRight - CropLeft), abs (CropTop - CropBottom));
   float2 cropBevel  = centreCrop - (cropAspect * Bevel * BEVEL);
   float2 cropBorder = centreCrop + (cropAspect * Border * BORDER);

   float2 xy1 = uv3 - float2 (CropRight + CropLeft, 2.0 - CropTop - CropBottom) / 2.0;
   float2 xy2 = abs (xy1) * 2.0;
   float2 xy3 = jSaturate (xy2 - cropBevel);

   xy3.x *= _OutputAspectRatio;

   if ((xy2.x > cropBevel.x) || (xy2.y > cropBevel.y)) {
      float3 hsv = fn_rgb2hsv (Light.rgb);

      hsv.y *= 0.25;
      hsv.z *= 0.375;

      float2 lit;

      sincos (radians (Angle), lit.x, lit.y);
      lit = (lit + 1.0.xx) * 0.5;

      float amt = (xy1.y > 0.0) ? 1.0 - lit.y : lit.y;

      float2 uv = pow (abs (uv3 - 0.5.xx) * 2.0, 1.75 - (Bevel * 0.5)) / 2.0;

      if (xy3.x > xy3.y) {
         amt = (xy1.x > 0.0) ? lit.x : 1.0 - lit.x;
         uv.x = uv3.x;
         uv.y = (uv3.y < 0.5) ? 0.5 - uv.y : 0.5 + uv.y;
      }
      else {
         uv.x = (uv3.x < 0.5) ? 0.5 - uv.x : 0.5 + uv.x;
         uv.y = uv3.y;
      }

      Fgnd = ReadPixel (Fgd, uv);
      retval = lerp (kTransparentBlack, Fgnd, Fgnd.a).rgb;

      amt = jSaturate (0.95 - (amt * Intensity * 2.0)) * 6.0;
      amt = (amt >= 3.0) ? amt - 2.0 : 1.0 / (4.0 - amt);
      hsv.z = pow (hsv.z, amt);

      if (hsv.z > 0.5) hsv.y = jSaturate (hsv.y - hsv.z + 0.5);

      hsv.z = jSaturate (hsv.z * 2.0);

      retval = lerp (retval, fn_hsv2rgb (hsv), (Bstrength * 0.5) + 0.25);
   }

   if ((xy2.x > centreCrop.x) || (xy2.y > centreCrop.y)) { retval = Colour.rgb; }

   return ((xy2.x > cropBorder.x) || (xy2.y > cropBorder.y)) ? kTransparentBlack : float4 (retval, 1.0);
}

DeclareEntryPoint (Bevel3D)
{
   if (CropToBgd && IsOutOfBounds (uv2)) return kTransparentBlack;

   float2 xy = ((uv3 - float2 (PosX, 1.0 - PosY)) / max (1e-6, Scale)) + 0.5.xx;

   float4 Fgnd = tex2D (Bvl, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a);
}

