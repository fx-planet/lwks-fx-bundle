// @Maintainer jwrl
// @Released 2020-11-14
// @Author jwrl
// @Created 2020-07-05
// @see https://www.lwks.com/media/kunena/attachments/6375/VisualQuad_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Visualquadsettings.mp4

/**
 This simple effect produces individually sized, cropped and positioned images of up to four
 sources at a time from the inputs A, B, C and D.  Input X (for eXternal) is a background
 source that can be used for video or to daisy chain other instances of this effect to
 produce much more than four images on screen.  The order of the various parameters in the
 user interface is the order in which the images are layered, so images will be overlaid
 with that priority.

 The images can be individually cropped to create differing aspect ratios of the source
 media.  To make sizing, cropping and position adjustment simpler for the user, those
 settings can all be made by dragging pin points on the edit viewer when in VFX mode.
 Because of limitations with the Lightworks effects engine, for this reason the numerical
 values of the various parameters don't make a lot of sense.  It would be wisest to just
 minimise them and solely use the pins on-screen.

 The size and crop pin points will always be in the upper left quadrant for the A channel,
 the upper right for the B, the lower left for the C and the lower right for the D channel
 regardless of the actual position and size of the images.  This is another characteristic
 of the way that the Lightworks effects engine works and cannot be changed.

 Size adjustment is performed by dragging the selected input's size pin point towards or
 away from the centre of the screen.  Dragging away from the centre enlarges it, and
 towards the centre reduces it.  The aspect ratio can be optionally set to track X and Y
 positions of the size pin.  The default is to adjust both by the X position of the pin.
 A hard edged border which erodes the image by the border thickness has also been provided
 and applies to all images.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VisualQuadSplit.fx
//
// Version history:
//
// Updated 2020-11-14 jwrl.
// Added CanSize switch for LW 2021 support.
//
// Modified 2020-07-08 jwrl.
// Placed the border settings immediately under the opacity settings.  This was done to
// give the channel settings the lowest priority in the UI.
// Commented the source code.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Visual quad split";
   string Category    = "DVE";
   string SubCategory = "Simple visual tools";
   string Notes       = "Produces four split screen images with borders using visual dragging to set size, crop and position";
   bool CanSize       = true;
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
   string Description = "A opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float B_Opacity
<
   string Description = "B opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float C_Opacity
<
   string Description = "C opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float D_Opacity
<
   string Description = "D opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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

bool A_Lock_AR
<
   string Group = "Source A settings";
   string Description = "Lock size aspect ratio";
> = true;

float A_Size_X
<
   string Group = "Source A settings";
   string Description = "Size A";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.3125;

float A_Size_Y
<
   string Group = "Source A settings";
   string Description = "Size A";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.5;
   float MaxVal = 1.0;
> = 0.6875;

float A_Crop_UX
<
   string Group = "Source A settings";
   string Description = "Crop A 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.45;

float A_Crop_UY
<
   string Group = "Source A settings";
   string Description = "Crop A 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.95;

float A_Crop_LX
<
   string Group = "Source A settings";
   string Description = "Crop A 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.05;

float A_Crop_LY
<
   string Group = "Source A settings";
   string Description = "Crop A 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.55;

float A_Position_X
<
   string Group = "Source A settings";
   string Description = "Position A";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.25;

float A_Position_Y
<
   string Group = "Source A settings";
   string Description = "Position A";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.75;

bool B_Lock_AR
<
   string Group = "Source B settings";
   string Description = "Lock size aspect ratio";
> = true;

float B_Size_X
<
   string Group = "Source B settings";
   string Description = "Size B";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.5;
   float MaxVal = 1.0;
> = 0.6875;

float B_Size_Y
<
   string Group = "Source B settings";
   string Description = "Size B";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.5;
   float MaxVal = 1.0;
> = 0.6875;

float B_Crop_UX
<
   string Group = "Source B settings";
   string Description = "Crop B 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.55;

float B_Crop_UY
<
   string Group = "Source B settings";
   string Description = "Crop B 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.95;

float B_Crop_LX
<
   string Group = "Source B settings";
   string Description = "Crop B 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.95;

float B_Crop_LY
<
   string Group = "Source B settings";
   string Description = "Crop B 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.55;

float B_Position_X
<
   string Group = "Source B settings";
   string Description = "Position B";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.75;

float B_Position_Y
<
   string Group = "Source B settings";
   string Description = "Position B";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.75;

bool C_Lock_AR
<
   string Group = "Source C settings";
   string Description = "Lock size aspect ratio";
> = true;

float C_Size_X
<
   string Group = "Source C settings";
   string Description = "Size C";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.3125;

float C_Size_Y
<
   string Group = "Source C settings";
   string Description = "Size C";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.3125;

float C_Crop_UX
<
   string Group = "Source C settings";
   string Description = "Crop C 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.05;

float C_Crop_UY
<
   string Group = "Source C settings";
   string Description = "Crop C 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.45;

float C_Crop_LX
<
   string Group = "Source C settings";
   string Description = "Crop C 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.45;

float C_Crop_LY
<
   string Group = "Source C settings";
   string Description = "Crop C 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.05;

float C_Position_X
<
   string Group = "Source C settings";
   string Description = "Position C";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.25;

float C_Position_Y
<
   string Group = "Source C settings";
   string Description = "Position C";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.25;

bool D_Lock_AR
<
   string Group = "Source D settings";
   string Description = "Lock size aspect ratio";
> = true;

float D_Size_X
<
   string Group = "Source D settings";
   string Description = "Size D";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.5;
   float MaxVal = 1.0;
> = 0.6875;

float D_Size_Y
<
   string Group = "Source D settings";
   string Description = "Size D";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.3125;

float D_Crop_UX
<
   string Group = "Source D settings";
   string Description = "Crop D 1";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.95;

float D_Crop_UY
<
   string Group = "Source D settings";
   string Description = "Crop D 1";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.45;

float D_Crop_LX
<
   string Group = "Source D settings";
   string Description = "Crop D 2";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.55;
   float MaxVal = 0.95;
> = 0.55;

float D_Crop_LY
<
   string Group = "Source D settings";
   string Description = "Crop D 2";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.05;
   float MaxVal = 0.45;
> = 0.05;

float D_Position_X
<
   string Group = "Source D settings";
   string Description = "Position D";
   string Flags = "SpecifiesPointX";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.75;

float D_Position_Y
<
   string Group = "Source D settings";
   string Description = "Position D";
   string Flags = "SpecifiesPointY";
   float MinVal = -0.5;
   float MaxVal = 1.5;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH   // This parameter is only available in version 14.5 and up.
Bad_LW_version    // Forces a compiler error if the Lightworks version is 14.0 or less.
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define EMPTY  0.0.xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_DVE (sampler s, float2 uv, float2 z, float2 p, float2 u, float2 l, float2 b)
{
   float2 size = max (z, 1e-6);              // Minimum size is limited to a low positive value
   float2 xy = ((uv - p) / size) + 0.5.xx;   // The pixel coordinates are scaled and positioned
   float2 border = b / size;                 // The border is scaled by the size
   float2 U = u - border;                    // The upper left border is calculated and...
   float2 L = l + border;                    // so is the lower right border

   // If the pixel coordinates fall outside the crop boundaries in u and l zero (transparent
   // black) is returned in RGBA.  If they fall outside the border a flat colour is returned,
   // otherwise the scaled video is returned to the caller.

   return ((xy.x > u.x) || (xy.y < u.y) || (xy.x < l.x) || (xy.y > l.y)) ? EMPTY :
          ((xy.x > U.x) || (xy.y < U.y) || (xy.x < L.x) || (xy.y > L.y)) ? BorderColour
                                                                         : tex2D (s, xy);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   // The master size setting is determined from the X position of the selected input

   float size = ((2.0 * D_Size_X) - 1.0) * 4.0 / 3.0;

   // The main parameters are now set up.  The border is set once and used throughout.
   // The video scaling, V-size is set to either size or by the X and Y position and is
   // set for each input.  In this case we're setting the values for D.  Because each
   // channel is unique they must be set up outside fn_DVE().

   float2 border = float2 (1.0, -_OutputAspectRatio) * BorderWidth * 0.25;
   float2 V_size = D_Lock_AR ? size.xx : float2 (size, (1.0 - (2.0 * D_Size_Y)) * 4.0 / 3.0);
   float2 crop_U = saturate (float2 (D_Crop_UX - 0.55, 0.45 - D_Crop_UY) * 2.5);
   float2 crop_L = saturate (float2 (D_Crop_LX - 0.55, 0.45 - D_Crop_LY) * 2.5);
   float2 position = float2 (D_Position_X, 1.0 - D_Position_Y);

   // We now recover the D input, scaled, positioned and cropped as required.  That is
   // then combined with the background layer from the X input and placed in retval.

   float4 Fgnd = fn_DVE (s_Input_D, uv, V_size, position, crop_U, crop_L, border);
   float4 retval = lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * D_Opacity);

   // Now the C channel settings are derived and applied to retval as in the D input.

   size = (1.0 - (2.0 * C_Size_X)) * 4.0 / 3.0;
   V_size = C_Lock_AR ? size.xx : float2 (size, (1.0 - (2.0 * C_Size_Y)) * 4.0 / 3.0);
   crop_U = saturate (float2 (C_Crop_LX - 0.05, 0.45 - C_Crop_UY) * 2.5);
   crop_L = saturate (float2 (C_Crop_UX - 0.05, 0.45 - C_Crop_LY) * 2.5);
   position = float2 (C_Position_X, 1.0 - C_Position_Y);

   Fgnd = fn_DVE (s_Input_C, uv, V_size, position, crop_U, crop_L, border);

   retval = lerp (retval, Fgnd, Fgnd.a * C_Opacity);

   // B channel

   size = ((2.0 * B_Size_X) - 1.0) * 4.0 / 3.0;
   V_size = B_Lock_AR ? size.xx : float2 (size, ((2.0 * B_Size_Y) - 1.0) * 4.0 / 3.0);
   crop_U = saturate (float2 (B_Crop_LX - 0.55, 0.95 - B_Crop_UY) * 2.5);
   crop_L = saturate (float2 (B_Crop_UX - 0.55, 0.95 - B_Crop_LY) * 2.5);
   position = float2 (B_Position_X, 1.0 - B_Position_Y);

   Fgnd = fn_DVE (s_Input_B, uv, V_size, position, crop_U, crop_L, border);

   retval = lerp (retval, Fgnd, Fgnd.a * B_Opacity);

   // The A channel is the last.  By doing it in this order A will be on top of B,
   // B will be over C, and C will be on top of D which overlays the X channel.

   size = (1.0 - (2.0 * A_Size_X)) * 4.0 / 3.0;
   V_size = A_Lock_AR ? size.xx : float2 (size, ((2.0 * A_Size_Y) - 1.0) * 4.0 / 3.0);
   crop_U = saturate (float2 (A_Crop_UX - 0.05, 0.95 - A_Crop_UY) * 2.5);
   crop_L = saturate (float2 (A_Crop_LX - 0.05, 0.95 - A_Crop_LY) * 2.5);
   position = float2 (A_Position_X, 1.0 - A_Position_Y);

   Fgnd = fn_DVE (s_Input_A, uv, V_size, position, crop_U, crop_L, border);

   return lerp (retval, Fgnd, Fgnd.a * A_Opacity);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique VisualQuadSplit
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}
