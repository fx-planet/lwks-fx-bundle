// @Maintainer jwrl
// @Released 2023-02_17
// @Author jwrl
// @Created 2023-01-09

/**
 This is a a combination of three DVEs.  The foreground DVE and bacground DVE 2 operate
 independently of each other.  The foreground can be cropped with rounded corners and
 given a bi-colour border.  Both the edges and borders can be feathered, and a drop
 shadow can be applied.

 The master DVE takes the cropped, bordered output of DVE 1 as its input.  This means
 that it's possible to scale the background and foreground independently, then adjust
 the position and size of the cropped foreground.  Also available is the ability to
 crop the output of the effect to sit inside the boundaries of the background video.
 This means that if your background is letterboxed, the effect can be too.

 Scaling settings follow a square law, which means that although the range covered is
 still 0 to 10, the settings range from 0 to just over 3.  This has two advantages.
 The first is that there is more control over size reduction.  The second is more
 subtle.  Doubling the scale setting doubles the AREA of the image.  This makes a
 keyframed zoom feel like a linear push in or out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TripleDVE.fx
//
// Version history:
//
// Updated 2023-02-17 jwrl
// Corrected header.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Triple DVE", "DVE", "DVE Extras", "Foreground, background and the overall effect each have independent DVE adjustment.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (PosX_3, "Position", "Foreground DVE", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (PosY_3, "Position", "Foreground DVE", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Scale_3, "Master scale", "Foreground DVE", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (ScaleX_3, "Scale X", "Foreground DVE", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (ScaleY_3, "Scale Y", "Foreground DVE", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (Amt_3, "Opacity", "Foreground DVE", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (CropT, "Top", "Crop", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (CropB, "Bottom", "Crop", kNoFlags, 0.9, 0.0, 1.0);
DeclareFloatParam (CropL, "Left", "Crop", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (CropR, "Right", "Crop", kNoFlags, 0.9, 0.0, 1.0);
DeclareFloatParam (CropRadius, "Rounding", "Crop", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BorderFeather, "Edge softness", "Crop", kNoFlags, 0.05, 0.0, 1.0);

DeclareFloatParam (BorderWidth, "Width", "Border", kNoFlags, 0.25, 0.0, 1.0);
DeclareColourParam (BorderColour_1, "Colour 1", "Border", kNoFlags, 0.855, 0.855, 0.855);
DeclareColourParam (BorderColour_2, "Colour 2", "Border", kNoFlags, 0.345, 0.655, 0.926);

DeclareFloatParam (Shadow, "Opacity", "Shadow", kNoFlags, 0.50, 0.0, 1.0);
DeclareFloatParam (ShadowSoft, "Softness", "Shadow", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (ShadowX, "X offset", "Shadow", kNoFlags, 0.5, -1.0, 1.0);
DeclareFloatParam (ShadowY, "Y offset", "Shadow", kNoFlags, -0.5, -1.0, 1.0);

DeclareFloatParam (PosX_1, "Position", "Fill DVE", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (PosY_1, "Position", "Fill DVE", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Scale_1, "Master scale", "Fill DVE", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (ScaleX_1, "Scale X", "Fill DVE", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (ScaleY_1, "Scale Y", "Fill DVE", kNoFlags, 1.0, 0.0, 3.16227766);

DeclareFloatParam (PosX_2, "Position", "Background DVE", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (PosY_2, "Position", "Background DVE", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Scale_2, "Master scale", "Background DVE", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (ScaleX_2, "Scale X", "Background DVE", kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (ScaleY_2, "Scale Y", "Background DVE", kNoFlags, 1.0, 0.0, 3.16227766);

DeclareIntParam (Blanking, "Crop image to background", kNoGroup, 0, "No|Yes");

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK float2(0.0, 1.0).xxxy

#define HALF_PI       1.5707963

#define BORDER_SCALE  0.05
#define FEATHER_SCALE 0.05
#define RADIUS_SCALE  0.1

#define SHADOW_DEPTH  0.1
#define SHADOW_SCALE  0.05
#define SHADOW_SOFT   0.025
#define TRANSPARENCY  0.75

#define MINIMUM       0.0001.xx

#define CENTRE        0.5.xx

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Msk)
{
   float adjust = max (0.0, max (CropL - CropR, CropT - CropB));

   float2 aspect  = float2 (1.0, _OutputAspectRatio);
   float2 center  = float2 (CropL + CropR, CropT + CropB) / 2.0;
   float2 border  = max (0.0, BorderWidth * BORDER_SCALE - adjust) * aspect;
   float2 feather = max (0.0, BorderFeather * FEATHER_SCALE - adjust) * aspect;
   float2 F_scale = max (MINIMUM, feather * 2.0);
   float2 S_scale = F_scale + max (0.0, ShadowSoft * SHADOW_SOFT - adjust) * aspect;
   float2 outer_0 = float2 (CropR, CropB) - center;
   float2 outer_1 = max (0.0.xx, outer_0 + feather);
   float2 outer_2 = outer_1 + border;

   float radius_0 = CropRadius * RADIUS_SCALE;
   float radius_1 = min (radius_0 + feather.x, min (outer_1.x, outer_1.y / _OutputAspectRatio));
   float radius_2 = radius_1 + border.x;

   float2 inner   = max (0.0.xx, outer_1 - radius_1 * aspect);
   float2 xy = abs (uv3 - center);
   float2 XY = (xy - inner) / aspect;

   float scope = distance (XY, 0.0.xx);

   float4 Mask = kTransparentBlack;

   if (all (xy < outer_1)) {
      Mask.r = min (1.0, min ((outer_1.y - xy.y) / F_scale.y, (outer_1.x - xy.x) / F_scale.x));

      if (all (xy >= inner)) {
         if (scope < radius_1) { Mask.r = min (1.0, (radius_1 - scope) / F_scale.x); }
         else Mask.r = 0.0;
      }
   }

   outer_0  = max (0.0.xx, outer_0 + border);
   radius_0 = min (radius_0 + border.x, min (outer_0.x, outer_0.y / _OutputAspectRatio));
   border   = max (MINIMUM, max (border, feather));
   adjust   = sin (min (1.0, CropRadius * 20.0) * HALF_PI);

   if (all (xy < outer_2)) {
      Mask.g = min (1.0, min ((outer_0.y - xy.y) / border.y, (outer_0.x - xy.x) / border.x));
      Mask.b = min (1.0, min ((outer_2.y - xy.y) / F_scale.y, (outer_2.x - xy.x) / F_scale.x));
      Mask.a = min (1.0, min ((outer_2.y - xy.y) / S_scale.y, (outer_2.x - xy.x) / S_scale.x));

      if (all (xy >= inner)) {
         if (scope < radius_2) {
            Mask.g = lerp (Mask.g, min (1.0, (radius_0 - scope) / border.x), adjust);
            Mask.b = lerp (Mask.b, min (1.0, (radius_2 - scope) / F_scale.x), adjust);
            Mask.a = lerp (Mask.a, min (1.0, (radius_2 - scope) / S_scale.x), adjust);
         }
         else Mask.gba = lerp (Mask.gba, 0.0.xxx, adjust);
      }
   }

   adjust  = sin (min (1.0, BorderWidth * 10.0) * HALF_PI);
   Mask.gb = lerp (0.0.xx, Mask.gb, adjust);
   Mask.a  = lerp (0.0, Mask.a, Shadow * TRANSPARENCY);

   return Mask;
}

DeclareEntryPoint (TripleDVE)
{
   float2 posn_Factor = float2 (PosX_3, 1.0 - PosY_3);
   float2 scaleFactor = max (MINIMUM, Scale_3 * float2 (ScaleX_3, ScaleY_3));

   float2 xy1 = (uv3 - posn_Factor) / scaleFactor + CENTRE;
   float2 xy2 = (uv3 - float2 (PosX_2, 1.0 - PosY_2)) / max (MINIMUM, Scale_2 * float2 (ScaleX_2, ScaleY_2)) + CENTRE;
   float2 xy3 = (uv3 - posn_Factor) / scaleFactor + CENTRE;
   float2 xy4 = xy3 - (float2 (ShadowX / _OutputAspectRatio, -ShadowY) * scaleFactor * SHADOW_DEPTH);

   xy1 = (xy1 - float2 (PosX_1, 1.0 - PosY_1)) / max (MINIMUM, Scale_1 * float2 (ScaleX_1, ScaleY_1)) + CENTRE;

   float4 Fgnd = ReadPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bgd, xy2);
   float4 Mask = ReadPixel (Msk, xy3);

   float3 Base = IsOutOfBounds (xy4) ? Bgnd.rgb : Bgnd.rgb * (1.0 - ReadPixel (Msk, xy4).w);

   float4 Colour = lerp (BorderColour_2, BorderColour_1, Mask.y);
   float4 retval = lerp (float4 (Base, Bgnd.a), Colour, Mask.z);

   retval = lerp (retval, Fgnd, Mask.x);

   return Blanking && (Bgnd.a == 0.0) ? kTransparentBlack : lerp (Bgnd, retval, Amt_3);
}

