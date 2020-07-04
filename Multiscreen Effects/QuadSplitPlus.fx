// @Maintainer jwrl
// @Released 2020-07-04
// @Author jwrl
// @Created 2020-06-22
// @see https://www.lwks.com/media/kunena/attachments/6375/QuadSplitPlus_640.png

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
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadSplitPlus.fx
//
// Version history:
//
// Modified 2020-07-04 jwrl:
// Allow individual crop/size settings to be ungrouped from A group settings.
//
// Modified 2020-06-23 jwrl:
// Extended position parameter ranges from 0% - 100% to -50% - 150%.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Quad split plus";
   string Category    = "DVE";
   string SubCategory = "Multiscreen Effects";
   string Notes       = "Produces four split screen images with borders over an optional daisy-chained background";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture A;
texture B;
texture C;
texture D;

texture X;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input_A = sampler_state { Texture = <A>; };
sampler s_Input_B = sampler_state { Texture = <B>; };
sampler s_Input_C = sampler_state { Texture = <C>; };
sampler s_Input_D = sampler_state { Texture = <D>; };

sampler s_Background = sampler_state { Texture = <X>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float A_Opacity
<
   string Group = "Source A";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int A_Group
<
   string Group = "Source A";
   string Description = "Crop / size grouping";
   string Enum = "Set each input individually,Use source A settings for all";
> = 0;

float A_Size
<
   string Group = "Source A";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float A_Crop_X
<
   string Group = "Source A";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float A_Crop_Y
<
   string Group = "Source A";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float A_Position_X
<
   string Group = "Source A";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.0;

float A_Position_Y
<
   string Group = "Source A";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 1.0;

float B_Opacity
<
   string Group = "Source B";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int B_Group
<
   string Group = "Source B";
   string Description = "Crop / size grouping";
   string Enum = "Only use B settings,Follow source A group settings";
> = 1;

float B_Size
<
   string Group = "Source B";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float B_Crop_X
<
   string Group = "Source B";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float B_Crop_Y
<
   string Group = "Source B";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float B_Position_X
<
   string Group = "Source B";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.25;

float B_Position_Y
<
   string Group = "Source B";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 1.0;

float C_Opacity
<
   string Group = "Source C";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int C_Group
<
   string Group = "Source C";
   string Description = "Crop / size grouping";
   string Enum = "Only use C settings,Follow source A group settings";
> = 1;

float C_Size
<
   string Group = "Source C";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float C_Crop_X
<
   string Group = "Source C";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float C_Crop_Y
<
   string Group = "Source C";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float C_Position_X
<
   string Group = "Source C";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.5;

float C_Position_Y
<
   string Group = "Source C";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 1.0;

float D_Opacity
<
   string Group = "Source D";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int D_Group
<
   string Group = "Source D";
   string Description = "Crop / size grouping";
   string Enum = "Only use D settings,Follow source A group settings";
> = 1;

float D_Size
<
   string Group = "Source D";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float D_Crop_X
<
   string Group = "Source D";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float D_Crop_Y
<
   string Group = "Source D";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float D_Position_X
<
   string Group = "Source D";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.75;

float D_Position_Y
<
   string Group = "Source D";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 1.0;

float BorderWidth
<
   string Group = "Border";
   string Description = "Width";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.1;
> = 0.025;

float4 BorderColour
<
   string Group = "Border";
   string Description = "Colour";
   bool SupportsAlpha = false;
> = { 0.694, 0.255, 0.710, 1.0 };

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH   // Only available in version 14.5 and up
Bad_LW_version    // Forces a compiler error if the Lightworks version is bad.
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLANK  0.0.xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_miniDVE (sampler s_Input, float2 uv, float3 group, float4 vid, float a, float b)
{
   float2 xy1 = uv / group.z;
   float2 xy2 = abs (xy1 - 0.5.xx) * 2.0;
   float2 border = group.xy - float2 (b, b * _OutputAspectRatio) / group.z;

   float4 retval = (xy2.x <= border.x) && (xy2.y <= border.y) ? tex2D (s_Input, xy1) :
                   (xy2.x <= group.x)  && (xy2.y <= group.y)  ? BorderColour : BLANK;

   return lerp (vid, retval, retval.a * a);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Background, uv);

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

   float2 xy = uv - float2 (D_Position_X, 1.0 - D_Position_Y);

   // Recover the D video, scaled, cropped, bordered and mixed with the background.

   retval = fn_miniDVE (s_Input_D, xy, group [idx], retval, D_Opacity, border);

   // Generate the C index into the crop and size array.  In this case it will be either 0 or 2.

   idx = int (saturate (2.0 - A_Group - C_Group)); idx += idx;
   xy = uv - float2 (C_Position_X, 1.0 - C_Position_Y);

   retval = fn_miniDVE (s_Input_C, xy, group [idx], retval, C_Opacity, border);

   // Generate the B index into the crop and size array which will be either 0 or 1.

   idx = int (saturate (2.0 - A_Group - B_Group));
   xy = uv - float2 (B_Position_X, 1.0 - B_Position_Y);

   retval = fn_miniDVE (s_Input_B, xy, group [idx], retval, B_Opacity, border);

   // The A index can only ever be zero, so we can explicitly declare it.

   idx = 0;
   xy = uv - float2 (A_Position_X, 1.0 - A_Position_Y);

   return fn_miniDVE (s_Input_A, xy, group [idx], retval, A_Opacity, border);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuadSplitPlus
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
