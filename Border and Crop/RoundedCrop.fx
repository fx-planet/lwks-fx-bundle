// @Maintainer jwrl
// @Released 2023-01-06
// @Author jwrl
// @Released 2023-01-06

/**
 This is a bordered crop that produces rounding at the corners of the crop shape.  The
 border can be feathered, and is a mix of two colours.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RoundedCrop.fx
//
// Version history:
//
// Built 2023-01-06 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rounded crop", "DVE", "Border and crop", "A bordered, drop shadowed crop with rounded corners", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (CropR, "Top right", "Crop", "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (CropT, "Top right", "Crop", "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (CropL, "Bottom left", "Crop", "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (CropB, "Bottom left", "Crop", "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (BorderWidth, "Width", "Border", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (CropRadius, "Rounding", "Border", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BorderFeather, "Edge softness", "Border", kNoFlags, 0.05, 0.0, 1.0);
DeclareColourParam (BorderColour_1, "Colour 1", "Border", kNoFlags, 0.345, 0.655, 0.926);
DeclareColourParam (BorderColour_2, "Colour 2", "Border", kNoFlags, 0.655, 0.345, 0.926);

DeclareFloatParam (Shadow, "Opacity", "Shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (ShadowSoft, "Softness", "Shadow", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (ShadowX, "X offset", "Shadow", kNoFlags, 0.25, -1.0, 1.0);
DeclareFloatParam (ShadowY, "Y offset", "Shadow", kNoFlags, -0.25, -1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI       1.5707963268

#define EDGE_SCALE    0.075
#define RADIUS_SCALE  0.15

#define SHADOW_DEPTH  0.1
#define SHADOW_SOFT   0.025
#define TRANSPARENCY  0.75

#define MINIMUM       0.0001.xx

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (MaskShape)
{
   float adjust = max (0.0, max (CropL - CropR, CropB - CropT));

   float2 aspect  = float2 (1.0, _OutputAspectRatio);
   float2 center  = float2 (CropL + CropR, 2.0 - CropT - CropB) / 2.0;
   float2 border  = max (0.0, BorderWidth * EDGE_SCALE - adjust) * aspect;
   float2 feather = max (0.0, BorderFeather * EDGE_SCALE - adjust) * aspect;
   float2 F_scale = max (MINIMUM, feather * 2.0);
   float2 S_scale = F_scale + max (0.0, ShadowSoft * SHADOW_SOFT - adjust) * aspect;
   float2 outer_1 = float2 (CropR, 1.0 - CropB) - center;
   float2 outer_2 = max (0.0.xx, outer_1 + feather);

   float radius_1 = CropRadius * RADIUS_SCALE;
   float radius_2 = min (radius_1 + feather.x, min (outer_2.x, outer_2.y / _OutputAspectRatio));

   float2 inner = max (0.0.xx, outer_2 - (radius_2 * aspect));
   float2 xy = abs (uv0 - center);

   float scope = distance ((xy - inner) / aspect, 0.0.xx);

   float4 Mask = 0.0.xxxx;

   if ((xy.x < outer_2.x) && (xy.y < outer_2.y)) {
      Mask.x = min (1.0, min ((outer_2.y - xy.y) / F_scale.y, (outer_2.x - xy.x) / F_scale.x));

      if ((xy.x >= inner.x) && (xy.y >= inner.y)) {
         if (scope < radius_2) { Mask.x = min (1.0, (radius_2 - scope) / F_scale.x); }
         else Mask.x = 0.0;
      }
   }

   outer_1   = max (0.0.xx, outer_1 + border);
   outer_2  += border;
   radius_1  = min (radius_1 + border.x, min (outer_1.x, outer_1.y / _OutputAspectRatio));
   radius_2 += border.x;
   border    = max (MINIMUM, max (border, feather));
   adjust    = sin (min (1.0, CropRadius * 20.0) * HALF_PI);

   if ((xy.x < outer_2.x) && (xy.y < outer_2.y)) {
      Mask.y = min (1.0, min ((outer_1.y - xy.y) / border.y, (outer_1.x - xy.x) / border.x));
      Mask.z = min (1.0, min ((outer_2.y - xy.y) / F_scale.y, (outer_2.x - xy.x) / F_scale.x));
      Mask.w = min (1.0, min ((outer_2.y - xy.y) / S_scale.y, (outer_2.x - xy.x) / S_scale.x));

      if ((xy.x >= inner.x) && (xy.y >= inner.y)) {
         if (scope < radius_2) {
            Mask.y = lerp (Mask.y, min (1.0, (radius_1 - scope) / border.x), adjust);
            Mask.z = lerp (Mask.z, min (1.0, (radius_2 - scope) / F_scale.x), adjust);
            Mask.w = lerp (Mask.w, min (1.0, (radius_2 - scope) / S_scale.x), adjust);
         }
         else Mask.yzw *= 1.0 - adjust;
      }
   }

   Mask.yz *= sin (min (1.0, BorderWidth * 10.0) * HALF_PI);
   Mask.w  *= Shadow * TRANSPARENCY;

   return Mask;
}

DeclareEntryPoint (RoundedCrop)
{
   float2 xy = uv3 - (float2 (ShadowX / _OutputAspectRatio, -ShadowY) * SHADOW_DEPTH);

   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 Mask = tex2D (MaskShape, uv3);

   float3 Shad = IsOutOfBounds (xy) ? Bgnd.rgb : Bgnd.rgb * (1.0 - tex2D (MaskShape, xy).w);

   float4 Colour = lerp (BorderColour_2, BorderColour_1, Mask.y);
   float4 retval = lerp (float4 (Shad, Bgnd.a), Colour, Mask.z);

   return lerp (retval, Fgnd, Mask.x);
}

