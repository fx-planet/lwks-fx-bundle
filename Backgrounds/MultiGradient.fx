// @Maintainer jwrl
// @Released 2023-01-01
// @Author jwrl
// @Created 2023-01-01

/**
 This effect creates a colour field which can be set up to be just a flat colour or a wide
 range of gradients.  Gradient choices are horizontal, horizontal to center and back, vertical,
 vertical to centre and back, a four way gradient from the corners, and several variants of a
 four way gradient to the centre and back.  There's also a radially blended colour gradiant.
 If the gradient blends to the centre, the position of the centre point can be adjusted.
 All gradieants are produced at the sequence resolution and are opaque.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MultiGradient.fx
//
// Version history:
//
// Built 2023-01-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Multicolour gradient", "Mattes", "Backgrounds", "Creates a colour field with a wide range of possible gradients", "CanSize|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Gradient", kNoGroup, 5, "Flat, uses top left colour|Horizontal blend, top left > top right|Horizontal blend to centre, TL > TR > TL|Vertical blend, top left > bottom left|Vertical blend to centre, TL > BL > TL|Four way gradient|Four way gradient to centre|Four way gradient to centre, horizontal|Four way gradient to centre, vertical|Radial, TL outer > TR centre");

DeclareFloatParam (OffsX, "Gradient centre", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (OffsY, "Gradient centre", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareColourParam (topLeft, "Top left", "Colour setup", kNoFlags, 0.25, 0.12, 0.74);
DeclareColourParam (topRight, "Top right", "Colour setup", kNoFlags, 0.38, 0.12, 0.97);
DeclareColourParam (botLeft, "Bottom left", "Colour setup", kNoFlags, 0.26, 0.31, 0.96);
DeclareColourParam (botRight, "Bottom right", "Colour setup", kNoFlags, 0.05, 0.84, 0.92);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float make_buffer (float2 xy)
{
   return (OffsX <= 0.0) ? (xy.x / 2.0) + 0.5
        : (OffsX >= 1.0) ? xy.x / 2.0
        : (OffsX > xy.x) ? xy.x / (2.0 * OffsX)
                         : ((xy.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Flat

DeclareEntryPoint (MultiGradientFlat)
{
   float4 retval = float4 (topLeft.rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Horizontal left > right

DeclareEntryPoint (MultiGradientHoriz_LR)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   float4 retval = float4 (lerp (topLeft, topRight, horiz).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Horizontal to centre

DeclareEntryPoint (MultiGradientHoriz_C)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 retval = float4 (lerp (topLeft, topRight, horiz).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);


   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Vertical top > bottom

DeclareEntryPoint (MultiGradientVert_TB)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 retval = float4 (lerp (topLeft, botLeft, vert).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Vertical to centre

DeclareEntryPoint (MultiGradientVert_C)
{

   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 retval = float4 (lerp (topLeft, botLeft, vert).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Four way

DeclareEntryPoint (MultiGradientFourWay)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   float4 retval = float4 (lerp (gradient, botRow, vert).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Four way to centre

DeclareEntryPoint (MultiGradientFourWay_C)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   float4 retval = float4 (lerp (gradient, botRow, vert).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Four way to horizontal centre

DeclareEntryPoint (MultiGradientFourWay_HC)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   float4 retval = float4 (lerp (gradient, botRow, vert).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Four way to vertical centre

DeclareEntryPoint (MultiGradientFourWay_VC)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   float4 retval = float4 (lerp (gradient, botRow, vert).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

// Radial

DeclareEntryPoint (MultiGradientRadial)
{
   float buff_0 = make_buffer (uv2);
   float buff_1, buff_2;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv2.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv2.y / 2.0 :
            (vert > uv2.y) ? uv2.y / (2.0 * vert) : ((uv2.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);

   float4 retval = float4 (lerp (topLeft, gradient, vert).rgb, 1.0);
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (Fgd, retval, tex2D (Mask, uv1));
}

