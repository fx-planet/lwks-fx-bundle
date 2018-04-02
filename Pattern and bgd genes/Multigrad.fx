//--------------------------------------------------------------//
// Lightworks user effect Multigrad.fx
//
// Written by LW user jwrl 31 July 2016
// @Author: jwrl
// @CreationDate: "31 July 2016"
//
// This creates a colour field which can be set up to be just
// a flat colour or a wide range of gradients.  If the gradient
// blends to the centre, the centre point is fully adjustable.
//
// Bug fix by LW user jwrl 14 July 2017 - previously this
// effect didn't work reliably on Linux/Mac platforms.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Multigradient";
   string Category    = "Matte";
   string SubCategory = "Patterns";
> = 0;

//--------------------------------------------------------------//
// Params
//--------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.00;
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
   float MaxVal = 1.00;
> = 0.5;

float OffsY
<
   string Description = "Gradient centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float4 topLeft
<
   string Group = "Colour setup";
   string Description = "Top left";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 0.0, 1.0 };

float4 topRight
<
   string Group = "Colour setup";
   string Description = "Top right";
   bool SupportsAlpha = false;
> = { 0.5, 0.0, 1.0, 0.8 };

float4 botLeft
<
   string Group = "Colour setup";
   string Description = "Bottom left";
   bool SupportsAlpha = false;
> = { 0.0, 0.0, 1.0, 1.0 };

float4 botRight
<
   string Group = "Colour setup";
   string Description = "Bottom right";
   bool SupportsAlpha = false;
> = { 0.0, 0.8, 1.0, 0.5 };

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define PI      3.141593

#define HALF_PI 1.570796

//--------------------------------------------------------------//
// Pixel Shaders
//--------------------------------------------------------------//

float4 ps_main_0 (float2 uv : TEXCOORD1) : COLOR
{
   return lerp (tex2D (FgSampler, uv), topLeft, Amount);
}

float4 ps_main_1 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   float4 Fgd = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, topRight, horiz);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_2 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 Fgd = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, topRight, horiz);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_3 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 Fgd = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, botLeft, vert);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_4 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 Fgd = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, botLeft, vert);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_5 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 Fgd      = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   gradient = lerp (gradient, botRow, vert);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_6 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 Fgd      = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   gradient = lerp (gradient, botRow, vert);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_7 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0) ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0) ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;

   float horiz = lerp (buff_1, buff_2, buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 Fgd      = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   gradient = lerp (gradient, botRow, vert);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_8 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_1, buff_2;
   float buff_0 = (OffsX <= 0.0) ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0) ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   sincos (HALF_PI * buff_0, buff_1, buff_2);
   buff_2 = 1.0 - buff_2;
   vert = lerp (buff_1, buff_2, buff_0);

   float4 Fgd      = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, topRight, horiz);
   float4 botRow   = lerp (botLeft, botRight, horiz);

   gradient = lerp (gradient, botRow, vert);

   return lerp (Fgd, gradient, Amount);
}

float4 ps_main_9 (float2 uv : TEXCOORD1) : COLOR
{
   float buff_0 = (OffsX <= 0.0) ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0) ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   float horiz = sin (PI * buff_0);
   float vert  = 1.0 - OffsY;

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   vert = sin (PI * buff_0);

   float4 Fgd = tex2D (FgSampler, uv);
   float4 gradient = lerp (topLeft, topRight, horiz);

   gradient = lerp (topLeft, gradient, vert);

   return lerp (Fgd, gradient, Amount);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique Flat
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique Horizontal_L_R
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_1 (); }
}

technique Horizontal_C
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_2 (); }
}

technique Vertical_T_B
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_3 (); }
}

technique Vertical_C
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_4 (); }
}

technique Four_way
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_5 (); }
}

technique Four_way_C
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_6 (); }
}

technique Four_way_H_C
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_7 (); }
}

technique Four_way_V_C
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_8 (); }
}

technique Radial
{
   pass P_1
   { PixelShader = compile PROFILE ps_main_9 (); }
}

