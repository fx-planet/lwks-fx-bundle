// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2020-06-22

/**
 This simple effect produces individually sized and positioned images of up to four sources
 at a time from the inputs A, B, C and D.  Input X (for eXternal) is a background source
 that can be used to daisy chain other instances of this effect to produce much more than
 four images on screen.

 The images can be individually cropped to create differing aspect ratios of the source
 media.  The cropping is symmetrical to reduce the number of controls necessary.  To make
 sizing and position calculation simpler for the user, sizing scales around the top left
 corner of the frame.  This means that a position setting of 0%, 0% will place the image at
 the top left of the frame, and if you reduce the size of all frames to 25% the next image
 will be at 25%, 0%, the third at 50%, 0% and fourth at 75%, 0% for a vertical column of
 four images.  In other words, you always add the size percentages to get the appropriate
 position.

 A hard edged border which erodes the image by the border thickness has also been provided.
 It applies to all images simultaneously.  If desired the A input's settings for size and
 cropping can also be used for all four of the images.  That can make setting up much faster.

 The order of the various parameters in the user interface is the suggested order in which
 they should be set up.  No adjustments are provided for input X.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadSplitPlus.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Quad split plus", "DVE", "Multiscreen Effects", "Produces four split screen images with borders over an optional daisy-chained background", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (A, B, C, D, X);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (A_Opacity, "Opacity", "Source A", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (A_Group, "Crop / size grouping", "Source A", 0, "Set each input individually|Use source A settings for all");
DeclareFloatParam (A_Size, "Size", "Source A", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (A_Crop_X, "Symmetrical crop", "Source A", "SpecifiesPointX", 1.0, 0.0, 1.0);
DeclareFloatParam (A_Crop_Y, "Symmetrical crop", "Source A", "SpecifiesPointY", 1.0, 0.0, 1.0);
DeclareFloatParam (A_Position_X, "Position", "Source A", "SpecifiesPointX|DisplayAsPercentage", 0.0, -0.5, 1.5);
DeclareFloatParam (A_Position_Y, "Position", "Source A", "SpecifiesPointY|DisplayAsPercentage", 1.0, -0.5, 1.5);

DeclareFloatParam (B_Opacity, "Opacity", "Source B", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (B_Group, "Crop / size grouping", "Source B", 1, "Only use B settings|Follow source A group settings)";
DeclareFloatParam (B_Size, "Size", "Source B", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (B_Crop_X, "Symmetrical crop", "Source B", "SpecifiesPointX", 1.0, 0.0, 1.0);
DeclareFloatParam (B_Crop_Y, "Symmetrical crop", "Source B", "SpecifiesPointY", 1.0, 0.0, 1.0);
DeclareFloatParam (B_Position_X, "Position", "Source B", "SpecifiesPointX|DisplayAsPercentage", 0.25, -0.5, 1.5);
DeclareFloatParam (B_Position_Y, "Position", "Source B", "SpecifiesPointY|DisplayAsPercentage", 1.0, -0.5, 1.5);

DeclareFloatParam (C_Opacity, "Opacity", "Source C", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (C_Group, "Crop / size grouping", "Source C", 1, "Only use C settings|Follow source A group settings)";
DeclareFloatParam (C_Size, "Size", "Source C", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (C_Crop_X, "Symmetrical crop", "Source C", "SpecifiesPointX", 1.0, 0.0, 1.0);
DeclareFloatParam (C_Crop_Y, "Symmetrical crop", "Source C", "SpecifiesPointY", 1.0, 0.0, 1.0);
DeclareFloatParam (C_Position_X, "Position", "Source C", "SpecifiesPointX|DisplayAsPercentage", 0.5, -0.5, 1.5);
DeclareFloatParam (C_Position_Y, "Position", "Source C", "SpecifiesPointY|DisplayAsPercentage", 1.0, -0.5, 1.5);

DeclareFloatParam (D_Opacity, "Opacity", "Source D", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (D_Group, "Crop / size grouping", "Source D", 1, "Only use D settings|Follow source A group settings");
DeclareFloatParam (D_Size, "Size", "Source D", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (D_Crop_X, "Symmetrical crop", "Source D", "SpecifiesPointX", 1.0, 0.0, 1.0);
DeclareFloatParam (D_Crop_Y, "Symmetrical crop", "Source D", "SpecifiesPointY", 1.0, 0.0, 1.0);
DeclareFloatParam (D_Position_X, "Position", "Source D", "SpecifiesPointX|DisplayAsPercentage", 0.75, -0.5, 1.5);
DeclareFloatParam (D_Position_Y, "Position", "Source D", "SpecifiesPointY|DisplayAsPercentage", 1.0, -0.5, 1.5);

DeclareFloatParam (BorderWidth, "Width", "Border", kNoFlags, 0.025, 0.0, 0.1);
DeclareColourParam (BorderColour, "Colour", "Border", kNoFlags, 0.694, 0.255, 0.710);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s, float2 uv)
{
   if (any (uv < 0.0) || any (uv > 1.0)) return float2 (0.0,1.0).xxxy;

   return tex2D (s, uv);
}

float4 fn_miniDVE (sampler s, float2 uv, float3 group, float4 vid, float a, float b)
{
   float2 xy1 = uv / group.z;
   float2 xy2 = abs (xy1 - 0.5.xx) * 2.0;
   float2 border = group.xy - float2 (b, b * _OutputAspectRatio) / group.z;

   float4 retval = (xy2.x <= border.x) && (xy2.y <= border.y) ? tex2D (s, xy1) :
                   (xy2.x <= group.x)  && (xy2.y <= group.y)  ? BorderColour : kTransparentBlack;

   return lerp (vid, retval, retval.a * a);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Aquad)
{ return fn_tex2D (A, uv1); }

DeclarePass (Bquad)
{ return fn_tex2D (B, uv2); }

DeclarePass (Cquad)
{ return fn_tex2D (C, uv3); }

DeclarePass (Dquad)
{ return fn_tex2D (D, uv4); }

DeclareEntryPoint (QuadSplitPlus)
{
   float4 retval = fn_tex2D (X, uv5);

   // First build an array of the four crop and size settings

   float3 group [4] = { float3 (A_Crop_X, A_Crop_Y, max (A_Size, 1e-6)),
                        float3 (B_Crop_X, B_Crop_Y, max (B_Size, 1e-6)),
                        float3 (C_Crop_X, C_Crop_Y, max (C_Size, 1e-6)),
                        float3 (D_Crop_X, D_Crop_Y, max (D_Size, 1e-6)), };

   // Now generate an index into that array.  In the D case the index will be either 0 or 3.

   int idx = int (saturate (2.0 - A_Group - D_Group)); idx += idx + idx;

   // Scale the border width

   float border = BorderWidth * 0.25;

   // Get the adjusted image position.

   float2 xy = uv6 - float2 (D_Position_X, 1.0 - D_Position_Y);

   // Recover the D video, scaled, cropped, bordered and mixed with the background.

   retval = fn_miniDVE (Dquad, xy, group [idx], retval, D_Opacity, border);

   // Generate the C index into the crop and size array.  In this case it will be either 0 or 2.

   idx = int (saturate (2.0 - A_Group - C_Group)); idx += idx;
   xy = uv6 - float2 (C_Position_X, 1.0 - C_Position_Y);

   retval = fn_miniDVE (Cquad, xy, group [idx], retval, C_Opacity, border);

   // Generate the B index into the crop and size array which will be either 0 or 1.

   idx = int (saturate (2.0 - A_Group - B_Group));
   xy = uv6 - float2 (B_Position_X, 1.0 - B_Position_Y);

   retval = fn_miniDVE (Bquad, xy, group [idx], retval, B_Opacity, border);

   // The A index can only ever be zero, so we can explicitly declare it.

   idx = 0;
   xy = uv6 - float2 (A_Position_X, 1.0 - A_Position_Y);

   return fn_miniDVE (Aquad, xy, group [idx], retval, A_Opacity, border);
}

