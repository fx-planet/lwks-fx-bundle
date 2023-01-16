// @Maintainer jwrl
// @Released 2023-01-06
// @Author jwrl
// @Released 2023-01-06

/**
 This started out to be a revised SimpleCrop.fx, but since it adds a feathered,
 coloured border and a soft drop shadow was given its own name.  It's now essentially
 the same as DualDVE.fx without the DVE components.  The previous version also had
 input swapping, but because there's little point in that it has been removed.  Instead
 optional automatic cropping to background has been added.

 Any alpha information in the foreground is discarded by this effect.  This means that
 wherever the foreground and bevelled border appears will be opaque black.  The
 background alpha is preserved.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BorderedCrop.fx
//
// Version history:
//
// Built 2023-01-06 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bordered crop", "DVE", "Border and crop", "A crop tool with border, feathering and drop shadow", kNoFlags);

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

DeclareFloatParam (BorderWidth, "Width", "Border", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (BorderFeather, "Feathering", "Border", kNoFlags, 0.0, 0.0, 1.0);
DeclareColourParam (BorderColour, "Colour", "Border", kNoFlags, 0.694, 0.255, 0.710, 1.0);

DeclareFloatParam (Opacity, "Shadow density", "Drop shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Feather, "Feathering", "Drop shadow", kNoFlags, 0.15, 0.0, 1.0);
DeclareFloatParam (Shadow_X, "Shadow offset", "Drop shadow", "SpecifiesPointX", 0.6, 0.0, 1.0);
DeclareFloatParam (Shadow_Y, "Shadow offset", "Drop shadow", "SpecifiesPointY", 0.4, 0.0, 1.0);

DeclareBoolParam (CropToBgd, "Crop foreground to background", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BORDER_SCALE   0.0666667
#define BORDER_FEATHER 0.05

#define SHADOW_SCALE   0.2
#define SHADOW_FEATHER 0.1

#define BLACK float4(0.0.xxx,1.0)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FgdCrop)
{
   float bWidth = max (0.0, BorderWidth);

   float4 Fgnd   = ReadPixel (Fg, uv1);

   Fgnd = lerp (kTransparentBlack, Fgnd, Fgnd.a);
   Fgnd.a = 1.0;

   float4 retval = lerp (Fgnd, BorderColour, min (1.0, bWidth * 50.0));

   float2 fx1 = float2 (1.0, _OutputAspectRatio) * max (0.0, BorderFeather) * BORDER_FEATHER;
   float2 fx2 = fx1 / 2.0;

   float2 Border = float2 (1.0, _OutputAspectRatio) * bWidth * BORDER_SCALE;
   float2 brdrTL = uv0 - float2 (CropLeft, 1.0 - CropTop) + Border;
   float2 brdrBR = float2 (CropRight, 1.0 - CropBottom) - uv0 + Border;
   float2 bAlpha = min (brdrTL, brdrBR) / fx1;

   float2 cropTL = brdrTL - Border + fx2;
   float2 cropBR = brdrBR - Border + fx2;
   float2 cAlpha = min (cropTL, cropBR) / fx1;

   retval.a = saturate (min (bAlpha.x, bAlpha.y));

   return lerp (retval, Fgnd, saturate (min (cAlpha.x, cAlpha.y)));
}

DeclareEntryPoint (BorderedCrop)
{
   if (CropToBgd && IsOutOfBounds (uv2)) return kTransparentBlack;

   float2 aspect = float2 (1.0, _OutputAspectRatio);
   float2 Border = aspect * max (0.0, BorderWidth) * BORDER_SCALE;
   float2 xy     = uv3 - float2 ((Shadow_X - 0.5), (0.5 - Shadow_Y) * _OutputAspectRatio) * SHADOW_SCALE;

   float4 Bgnd   = ReadPixel (Bg, uv2);
   float4 Fgnd   = tex2D (FgdCrop, uv3);
   float4 retval = tex2D (FgdCrop, xy);

   float2 shadowTL = xy - float2 (CropLeft, 1.0 - CropTop) + Border;
   float2 shadowBR = float2 (CropRight, 1.0 - CropBottom) - xy + Border;
   float2 sAlpha   = saturate (min (shadowTL, shadowBR) / (aspect * Feather * SHADOW_FEATHER));

   float alpha = sAlpha.x * sAlpha.y * retval.a * Opacity;

   retval = lerp (Bgnd, BLACK, alpha);

   return lerp (retval, Fgnd, Fgnd.a);
}

