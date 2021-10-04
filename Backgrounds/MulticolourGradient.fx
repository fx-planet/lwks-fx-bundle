// @Maintainer jwrl
// @Released 2021-09-04
// @Author jwrl
// @Created 2021-09-04
// @see https://www.lwks.com/media/kunena/attachments/6375/Multigrad_640.png

/**
 This effect creates a colour field which can be set up to be just a flat colour or a wide
 range of gradients.  Gradient choices are horizontal, horizontal to center and back, vertical,
 vertical to centre and back, a four way gradient from the corners, and several variants of a
 four way gradient to the centre and back.  There's also a radially blended colour gradiant.
 If the gradient blends to the centre, the position of the centre point can be adjusted.

 This is a rewrite of the earlier multicolour gradient effect to support Lightworks 2021 and
 higher.  It can be compiled and will run on LW 14.5 and 2020, but to enable the resolution
 independence of 2021 it will need to be installed on that release of Lightworks.  Any earlier
 versions of this effect will need to be deleted before installing this version.

 NOTE: Backgrounds are newly created media and are produced at the sequence resolution.
 They are then cropped to the background resolution.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MulticolourGradient.fx
//
// Version history:
//
// Rewrite 2021-09-04 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Multicolour gradient";
   string Category    = "Matte";
   string SubCategory = "Backgrounds";
   string Notes       = "Creates a colour field with a wide range of possible gradients";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, SAMPLER) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY) (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI      3.1415926536

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

int SetTechnique
<
   string Description = "Gradient";
   string Enum = "Flat (uses only the top left colour),Horizontal blend (top left > top right),Horizontal blend to centre (TL > TR > TL),Vertical blend (top left > bottom left),Vertical blend to centre (TL > BL > TL),Four way gradient,Four way gradient to centre,Four way gradient to centre (horizontal),Four way gradient to centre (vertical),Radial (TL outer > TR centre)";
> = 5;

float OffsX
<
   string Description = "Gradient centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float OffsY
<
   string Description = "Gradient centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float4 topLeft
<
   string Group = "Colour setup";
   string Description = "Top left";
   bool SupportsAlpha = false;
> = { 0.25, 0.12, 0.74, -1.0 };

float4 topRight
<
   string Group = "Colour setup";
   string Description = "Top right";
   bool SupportsAlpha = false;
> = { 0.38, 0.12, 0.97, -1.0 };

float4 botLeft
<
   string Group = "Colour setup";
   string Description = "Bottom left";
   bool SupportsAlpha = false;
> = { 0.26, 0.31, 0.96, -1.0 };

float4 botRight
<
   string Group = "Colour setup";
   string Description = "Bottom right";
   bool SupportsAlpha = false;
> = { 0.05, 0.84, 0.92, -1.0 };

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_flat (float2 uv : TEXCOORD1) : COLOR
{
   return lerp (GetPixel (s_Input, uv), float4 (topLeft.rgb, 1.0), Amount);
}

float4 ps_horiz_LR (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   float4 colour = float4 (lerp (topLeft, topRight, horiz).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_horiz_C (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 colour = float4 (lerp (topLeft, topRight, horiz).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_vert_TB (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 colour = float4 (lerp (topLeft, botLeft, vert).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_vert_C (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 colour = float4 (lerp (topLeft, botLeft, vert).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_4way (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);
   float4 colour   = float4 (lerp (gradient, botRow, vert).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_4way_C (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);
   float4 colour   = float4 (lerp (gradient, botRow, vert).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_4way_HC (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0) ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0) ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);
   float4 colour   = float4 (lerp (gradient, botRow, vert).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_4way_VC (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0) ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0) ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);
   float4 colour   = float4 (lerp (gradient, botRow, vert).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

float4 ps_radial (float2 uv0 : TEXCOORD, float2 uv2 : TEXCOORD2) : COLOR
{
   float buff_0 = (OffsX <= 0.0) ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0) ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 colour   = float4 (lerp (topLeft, gradient, vert).rgb, 1.0);

   return lerp (tex2D (s_Input, uv2), colour, Amount);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Flat
{
   pass P_1 ExecuteShader (ps_flat)
}

technique Horizontal_L_R
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_horiz_LR)
}

technique Horizontal_C
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_horiz_C)
}

technique Vertical_T_B
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_vert_TB)
}

technique Vertical_C
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_vert_C)
}

technique Four_way
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_4way)
}

technique Four_way_C
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_4way_C)
}

technique Four_way_H_C
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_4way_HC)
}

technique Four_way_V_C
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_4way_VC)
}

technique Radial
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 ExecuteShader (ps_radial)
}

