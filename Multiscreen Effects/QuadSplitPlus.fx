// @Maintainer jwrl
// @Released 2020-06-22
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

float Amt_A
<
   string Group = "Source A";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Group = "Source A";
   string Description = "Crop / size";
   string Enum = "Set each input individually,Use source A settings for all";
> = 0.25;

float Size_A
<
   string Group = "Source A";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Crop_A_X
<
   string Group = "Source A";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Crop_A_Y
<
   string Group = "Source A";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Pos_A_X
<
   string Group = "Source A";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Pos_A_Y
<
   string Group = "Source A";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amt_B
<
   string Group = "Source B";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Size_B
<
   string Group = "Source B";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Crop_B_X
<
   string Group = "Source B";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Crop_B_Y
<
   string Group = "Source B";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Pos_B_X
<
   string Group = "Source B";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Pos_B_Y
<
   string Group = "Source B";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amt_C
<
   string Group = "Source C";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Size_C
<
   string Group = "Source C";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Crop_C_X
<
   string Group = "Source C";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Crop_C_Y
<
   string Group = "Source C";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Pos_C_X
<
   string Group = "Source C";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Pos_C_Y
<
   string Group = "Source C";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Amt_D
<
   string Group = "Source D";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Size_D
<
   string Group = "Source D";
   string Description = "Size";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Crop_D_X
<
   string Group = "Source D";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Crop_D_Y
<
   string Group = "Source D";
   string Description = "Symmetrical crop";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Pos_D_X
<
   string Group = "Source D";
   string Description = "Position";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.75;

float Pos_D_Y
<
   string Group = "Source D";
   string Description = "Position";
   string Flags = "SpecifiesPointY";
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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define BLANK  0.0.xxxx

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D_multi (sampler s_Input, float2 xy1, float2 xy2, float2 xy3)
{
   float2 uv1 = abs (xy1 - 0.5.xx) * 2.0;

   return (uv1.x <= xy3.x) && (uv1.y <= xy3.y) ? tex2D (s_Input, xy1) :
          (uv1.x <= xy2.x) && (uv1.y <= xy2.y) ? BorderColour : BLANK;
}

float4 fn_tex2D_one (sampler s_Input, float2 xy1, float2 xy2)
{
   float2 uv = abs (xy1 - 0.5.xx) * 2.0;

   return (uv.x <= xy2.x) && (uv.y <= xy2.y) ? tex2D (s_Input, xy1) :
          (uv.x <= Crop_A_X) && (uv.y <= Crop_A_Y) ? BorderColour : BLANK;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   float size = max (Size_D, 1e-6);
   float border = BorderWidth * 0.25 / size;

   float2 xy1 = (uv - float2 (Pos_D_X, 1.0 - Pos_D_Y)) / size;
   float2 xy2 = float2 (Crop_D_X, Crop_D_Y);
   float2 xy3 = xy2 - float2 (border, border * _OutputAspectRatio);

   float4 Fgnd = fn_tex2D_multi (s_Input_D, xy1, xy2, xy3);
   float4 Bgnd = lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amt_D);

   size = max (Size_C, 1e-6);
   border = BorderWidth * 0.25 / size;

   xy1 = (uv - float2 (Pos_C_X, 1.0 - Pos_C_Y)) / size;
   xy2 = float2 (Crop_C_X, Crop_C_Y);
   xy3 = xy2 - float2 (border, border * _OutputAspectRatio);

   Fgnd = fn_tex2D_multi (s_Input_C, xy1, xy2, xy3);
   Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amt_C);

   size = max (Size_B, 1e-6);
   border = BorderWidth * 0.25 / size;

   xy1 = (uv - float2 (Pos_B_X, 1.0 - Pos_B_Y)) / size;
   xy2 = float2 (Crop_B_X, Crop_B_Y);
   xy3 = xy2 - float2 (border, border * _OutputAspectRatio);

   Fgnd = fn_tex2D_multi (s_Input_B, xy1, xy2, xy3);
   Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amt_B);

   size = max (Size_A, 1e-6);
   border = BorderWidth * 0.25 / size;

   xy1 = (uv - float2 (Pos_A_X, 1.0 - Pos_A_Y)) / size;
   xy2 = float2 (Crop_A_X, Crop_A_Y);
   xy3 = xy2 - float2 (border, border * _OutputAspectRatio);

   Fgnd = fn_tex2D_multi (s_Input_A, xy1, xy2, xy3);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amt_A);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float size = max (Size_A, 1e-6);
   float border = BorderWidth * 0.25 / size;

   float2 xy1 = (uv - float2 (Pos_D_X, 1.0 - Pos_D_Y)) / size;
   float2 xy2 = float2 (Crop_A_X - border, Crop_A_Y - (border * _OutputAspectRatio));

   float4 Fgnd = fn_tex2D_one (s_Input_D, xy1, xy2);
   float4 Bgnd = lerp (tex2D (s_Background, uv), Fgnd, Fgnd.a * Amt_D);

   xy1 = (uv - float2 (Pos_C_X, 1.0 - Pos_C_Y)) / size;
   Fgnd = fn_tex2D_one (s_Input_C, xy1, xy2);

   Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amt_C);

   xy1 = (uv - float2 (Pos_B_X, 1.0 - Pos_B_Y)) / size;
   Fgnd = fn_tex2D_one (s_Input_B, xy1, xy2);

   Bgnd = lerp (Bgnd, Fgnd, Fgnd.a * Amt_B);

   xy1 = (uv - float2 (Pos_A_X, 1.0 - Pos_A_Y)) / size;
   Fgnd = fn_tex2D_one (s_Input_A, xy1, xy2);

   return lerp (Bgnd, Fgnd, Fgnd.a * Amt_A);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique QuadSplitPlus_0
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique QuadSplitPlus_1
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}

