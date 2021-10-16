// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Dx_Colour_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/DissolveThruColour.mp4

/**
 This effect dissolves through a user-selected colour field from one clip to another.
 The colour percentage can be adjusted from 0% when the effect perform as a standard
 dissolve, to 100% which fades to the colour field then to the second video stream.
 Values between 100% and 0% will make the colour more or less opaque, giving quite
 subtle colour blends through the transition.  Transition centering can also be adjusted.

 The colour field can be set up to be a single flat colour or a wide range of gradients.
 In the gradients that blend to the centre, the centre point is also fully adjustable.
 Asymmetrical colour transitions can be created by changing keyframing of the effect
 centre, opacity, transition curve, gradient centre and colour values.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Colour_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dissolve thru colour";
   string Category    = "Mix";
   string SubCategory = "Colour transitions";
   string Notes       = "Dissolves through a user-selected colour field from one clip to another";
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

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
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
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Gradient, s_Gradient);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float FxCentre
<
   string Description = "Transition centre";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float cAmount
<
   string Group = "Colour setup";
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float cCurve
<
   string Group = "Colour setup";
   string Description = "Trans. curve";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

int cGradient
<
   string Group = "Colour setup";
   string Description = "Gradient";
   string Enum = "Flat (uses only the top left colour),Horizontal blend (top left > top right),Horizontal blend to centre (TL > TR > TL),Vertical blend (top left > bottom left),Vertical blend to centre (TL > BL > TL),Four way gradient,Four way gradient to centre,Four way gradient to centre (horizontal),Four way gradient to centre (vertical),Radial (TL outer > TR centre)";
> = 5;

float OffsX
<
   string Group = "Colour setup";
   string Description = "Colour gradient midpoint";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.00;
> = 0.5;

float OffsY
<
   string Group = "Colour setup";
   string Description = "Colour gradient midpoint";
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

//-----------------------------------------------------------------------------------------//
// Pixel Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_colour (float2 uv0 : TEXCOORD0) : COLOR
{
   if (cGradient == 0) return topLeft;

   float4 retval;

   float buff_1, buff_2, horiz, vert = 1.0 - OffsY;
   float buff_0 = (OffsX <= 0.0)  ? (uv0.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv0.x / 2.0 :
                  (OffsX > uv0.x) ? uv0.x / (2.0 * OffsX) : ((uv0.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   if ((cGradient == 2) || (cGradient == 6) || (cGradient == 8) || (cGradient == 9)) horiz = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      horiz = lerp (buff_1, buff_2, buff_0);
   }

   buff_0 = (vert <= 0.0) ? (uv0.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv0.y / 2.0 :
            (vert > uv0.y) ? uv0.y / (2.0 * vert) : ((uv0.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   if ((cGradient == 4) || (cGradient == 6) || (cGradient == 7) || (cGradient == 9)) vert = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      vert = lerp (buff_1, buff_2, buff_0);
   }

   if ((cGradient == 3) || (cGradient == 4)) { retval = lerp (topLeft, botLeft, vert); }
   else {
      retval = lerp (topLeft, topRight, horiz);
   
      if (cGradient == 9) retval = lerp (topLeft, retval, vert);
      else if (cGradient > 4) {
         float4 botRow = lerp (botLeft, botRight, horiz);
         retval = lerp (retval, botRow, vert);
      }
   }

   return retval;
}

float4 ps_main (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float Mix = (FxCentre + 1.0) / 2;

   Mix = (Mix <= 0.0) ? (Amount / 2.0) + 0.5 :
         (Mix >= 1.0) ? Amount / 2.0 :
         (Mix > Amount) ? Amount / (2.0 * Mix) : ((Amount - Mix) / (2.0 * (1.0 - Mix))) + 0.5;

   float4 Fgnd   = GetPixel (s_Foreground, uv1);
   float4 Bgnd   = GetPixel (s_Background, uv2);
   float4 colour = GetPixel (s_Gradient, uv3);
   float4 rawDx  = lerp (Fgnd, Bgnd, Mix);
   float4 colDx;

   float nonLin = sin (Mix * PI);

   Mix *= 2.0;

   if (Mix > 1.0) {
      Mix = lerp ((2.0 - Mix), nonLin, cCurve);
      colDx = lerp (Bgnd, colour, Mix);
   }
   else {
      Mix = lerp (Mix, nonLin, cCurve);
      colDx = lerp (Fgnd, colour, Mix);
   }

   return lerp (rawDx, colDx, cAmount);
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique Colour_Dx
{
   pass P_1 < string Script = "RenderColorTarget0 = Gradient;"; > ExecuteShader (ps_colour)
   pass P_2 ExecuteShader (ps_main)
}

