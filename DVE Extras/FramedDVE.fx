// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2018-11-14

/**
 This is a combination of two 2D DVEs designed to provide a drop shadow and vignette
 effect while matching Lightworks' 2D DVE parameters.  Because of the way that the DVEs
 are created and applied they have exactly the same quality impact on the final result
 as a single DVE would.  The main DVE adjusts the foreground, crop, frame and drop shadow.
 When the foreground is cropped it can be given a bevelled textured border.  The bevel
 can be feathered, as can the drop shadow.  The second DVE adjusts the size and position
 of the foreground inside the frame.

 There is actually a third DVE of sorts that adjusts the size and offset of the border
 texture.  This is extremely rudimentary though.  Also LW masking hasn't been included
 because it was impossible to do that and still control the edges of the frame.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FramedDVE.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Framed DVE", "DVE", "DVE Extras", "Creates a textured frame around the foreground image and resizes and positions the result.", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg, Tx);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (DVE_Scale, "Scale", "DVE", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (DVE_Z_angle, "Z angle", "DVE", kNoFlags, 0.0, -360.0, 360.0);
DeclareFloatParam (DVE_PosX, "X position", "DVE", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (DVE_PosY, "Y position", "DVE", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (TLcropX, "Top left crop", kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (TLcropY, "Top left crop", kNoGroup, "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (BRcropX, "Bottom right crop", kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (BRcropY, "Bottom right crop", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (VideoScale, "Scale", "Video insert", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (VideoPosX, "X position", "Video insert", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (VideoPosY, "Y position", "Video insert", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (BorderWidth, "Width", "Border", kNoFlags, 0.4, 0.0, 1.0);
DeclareFloatParam (BorderBevel, "Bevel", "Border", kNoFlags, 0.4, 0.0, 1.0);
DeclareFloatParam (BorderSharpness, "Bevel sharpness", "Border", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (BorderOuter, "Outer edge", "Border", kNoFlags, 0.6, -1.0, 1.0);
DeclareFloatParam (BorderInner, "Inner edge", "Border", kNoFlags, -0.4, -1.0, 1.0);
DeclareFloatParam (TexScale, "Texture scale", "Border", kNoFlags, 1.0, 0.5, 2.0);
DeclareFloatParam (TexPosX, "Texture X", "Border", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (TexPosY, "Texture Y", "Border", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (ShadowOpacity, "Opacity", "Shadow", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (ShadowSoft, "Softness", "Shadow", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (ShadowAngle, "Angle", "Shadow", kNoFlags, 45.0, -180.0, 180.0);
DeclareFloatParam (ShadowOffset, "Offset", "Shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (ShadowDistance, "Distance", "Shadow", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (CropToBgd, "Crop to background", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);

DeclareIntParam (_FgOrientation);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define CropXY(XY, L, R, T, B)  (BadPos (XY.x, L, -R) || BadPos (XY.y, -T, B))

#define BLACK float2(0.0, 1.0).xxxy

#define BdrPixel(SHADER,XY) (IsOutOfBounds(XY) ? BLACK : tex2D(SHADER, XY))
#define GetMirror(SHD,UV,XY) (any (abs (XY - 0.5.xx) > 0.5) \
                             ? kTransparentBlack \
                             : tex2D (SHD, saturate (1.0.xx - abs (1.0.xx - abs (UV)))))

// Definitions used by this shader

#define HALF_PI      1.5707963268
#define PI           3.1415926536

#define BEVEL_SCALE  0.04
#define BORDER_SCALE 0.05

#define SHADOW_DEPTH 0.1
#define SHADOW_SOFT  0.05

#define CENTRE       0.5.xx

#define WHITE        1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Texture)
{ return GetMirror (Tx, uv3, uv3); }

DeclarePass (CropMask)
{
/* Returned values: crop.w - master crop 
                    crop.x - master border (inside crop) 
                    crop.y - border shading
                    crop.z - drop shadow
*/
   float cropX = TLcropX < BRcropX ? TLcropX : BRcropX;
   float cropY = TLcropY > BRcropY ? TLcropY : BRcropY;

   float2 aspect = float2 (1.0, _OutputAspectRatio);
   float2 offset = aspect / _OutputWidth;
   float2 xyCrop = float2 (cropX, 1.0 - cropY);
   float2 ccCrop = (xyCrop + float2 (BRcropX, 1.0 - BRcropY)) * 0.5;
   float2 uvCrop = abs (uv4 - ccCrop);

   xyCrop = abs (xyCrop - ccCrop);

   float2 border = max (0.0.xx, xyCrop - (aspect * BorderWidth * BORDER_SCALE));
   float2 edge_0 = aspect * BorderWidth * BorderBevel * BEVEL_SCALE;
   float2 edge_1 = max (0.0.xx, border + edge_0);

   edge_0 = max (0.0.xx, xyCrop - edge_0);
   edge_0 = (smoothstep (edge_0, xyCrop, uvCrop) + smoothstep (border, edge_1, uvCrop)) - 1.0.xx;
   edge_0 = (clamp (edge_0 * (1.0 + (BorderSharpness * 9.0)), -1.0.xx, 1.0.xx) * 0.5) + 0.5.xx;
   edge_1 = max (0.0.xx, xyCrop - (aspect * ShadowSoft * SHADOW_SOFT));
   edge_1 = smoothstep (edge_1, xyCrop, uvCrop);

   float4 crop = smoothstep (xyCrop - offset, xyCrop + offset, uvCrop).xyxy;

   crop.xy = smoothstep (border - offset, border + offset, uvCrop);
   crop.w = 1.0 - max (crop.w, crop.z);
   crop.x = 1.0 - max (crop.x, crop.y);
   crop.y = max (edge_0.x, edge_0.y);
   crop.z = (1.0 - edge_1.x) * (1.0 - edge_1.y);

   return crop;
}

DeclareEntryPoint (FramedDVE)
{
   float temp, ShadowX, ShadowY, scale = DVE_Scale < 0.0001 ? 10000.0 : 1.0 / DVE_Scale;

   sincos (radians (ShadowAngle), ShadowY, ShadowX);

   float2 xy0, xy1 = (uv4 - CENTRE) * scale;
   float2 xy2 = float2 (ShadowX, ShadowY * _OutputAspectRatio) * ShadowOffset * SHADOW_DEPTH;
   float2 xy3;

   sincos (radians (DVE_Z_angle), xy0.x, xy0.y);
   temp = (xy0.y * xy1.y) - (xy0.x * xy1.x * _OutputAspectRatio);
   xy1  = float2 ((xy0.x * xy1.y / _OutputAspectRatio) + (xy0.y * xy1.x), temp);

   xy1 += CENTRE - (float2 (DVE_PosX, -DVE_PosY) * 2.0);
   xy3  = xy1;

   float shadow = ShadowDistance * 0.3333333333;

   xy2 += float2 (1.0, 1.0 / _OutputAspectRatio) * shadow * xy2 / max (xy2.x, xy2.y);
   temp = (xy0.y * xy2.y) - (xy0.x * xy2.x * _OutputAspectRatio);
   xy2  = float2 ((xy0.x * xy2.y / _OutputAspectRatio) + (xy0.y * xy2.x), temp);
   xy2  = ((xy1 - xy2 - CENTRE) * (shadow + 1.0) / ((ShadowSoft * 0.05) + 1.0)) + CENTRE;

   float4 Mask = ReadPixel (CropMask, xy3);

   Mask.z = IsOutOfBounds (xy2) ? 0.0 : tex2D (CropMask, xy2).z;

   scale = VideoScale < 0.0001 ? 10000.0 : 1.0 / VideoScale;
   xy1   = (CENTRE + ((xy1 - CENTRE) * scale)) - (float2 (VideoPosX, -VideoPosY) * 2.0);
   scale = TexScale < 0.0001 ? 10000.0 : 1.0 / TexScale;
   xy3   = (CENTRE + ((xy3 - CENTRE) * scale)) - (float2 (TexPosX, -TexPosY) * 2.0);

   float4 Fgnd = BdrPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 frame = GetMirror (Texture, xy3, uv4);
   float4 retval = lerp (Bgnd, BLACK, Mask.z * ShadowOpacity);

   float alpha_O = ((2.0 * Mask.y) - 1.0);
   float alpha_I = max (0.0, -alpha_O) * abs (BorderInner);

   alpha_O = max (0.0, alpha_O) * abs (BorderOuter);
   frame = BorderOuter > 0.0 ? lerp (frame, WHITE, alpha_O) : lerp (frame, BLACK, alpha_O);
   frame = BorderInner > 0.0 ? lerp (frame, WHITE, alpha_I) : lerp (frame, BLACK, alpha_I);
   retval = lerp (retval, frame, Mask.w);
   retval = lerp (retval, Fgnd, Mask.x);

   return CropToBgd && IsOutOfBounds (uv2) ? kTransparentBlack : lerp (Bgnd, retval, Opacity);
}

