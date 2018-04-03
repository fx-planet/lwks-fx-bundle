// @Maintainer jwrl
// @Released 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Dx_Colour.fx
//
// Written by LW user jwrl 31 July 2016
// @Author jwrl
// @Created "31 July 2016"
//
// This effect is a complete rewrite of my Dip2colour.fx to
// add the ability to adjust effect centering, to improve the
// linearity of the transition to colour, and to expand the
// colour field modes considerably.
//
// It dissolves through a user-selected colour field from one
// clip to another.  The colour percentage can be adjusted
// from 0% when the effect perform as a standard dissolve, to
// 100% which fades to the colour field then to the second
// video stream.  Values between 100% and 0% will make the
// colour more or less opaque, giving quite subtle colour
// blends through the transition.  Transition centering can
// also be adjusted.  Thanks khaver for the idea, although
// this algorithm and implementation is entirely my own.
//
// The colour field can be set up to be a single flat colour
// or a wide range of gradients.  In the gradients that blend
// to the centre, the centre point is also fully adjustable.
// Asymmetrical colour transitions can be created by changing
// keyframing of the effect centre, opacity, transition curve,
// gradient centre and colour values.
//
// Update August 4 2017 by jwrl.
// All samplers fully defined to avoid differences in their
// default states between Windows and Linux/Mac compilers.
//
// Update August 10 2017 by jwrl - renamed from DissThruColour.fx
// for consistency across the dissolve range.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Dissolve through colour";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state
{ 
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state
{
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

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

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define PI 3.141593

#define HALF_PI 1.570796

//--------------------------------------------------------------//
// Pixel Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 uv : TEXCOORD1) : COLOR
{
   float4 colDx, gradient;

   float Mix = (FxCentre + 1.0) / 2;

   Mix = (Mix <= 0.0) ? (Amount / 2.0) + 0.5 :
         (Mix >= 1.0) ? Amount / 2.0 :
         (Mix > Amount) ? Amount / (2.0 * Mix) : ((Amount - Mix) / (2.0 * (1.0 - Mix))) + 0.5;

   float4 fgPix = tex2D (FgSampler, uv);
   float4 bgPix = tex2D (BgSampler, uv);
   float4 rawDx = lerp (fgPix, bgPix, Mix);

   if (cGradient == 0) { gradient = topLeft; }
   else {
      float buff_1, buff_2, horiz, vert = 1.0 - OffsY;
      float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                     (OffsX >= 1.0)  ? uv.x / 2.0 :
                     (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

      if ((cGradient == 2) || (cGradient == 6) || (cGradient == 8) || (cGradient == 9)) horiz = sin (PI * buff_0);
      else {
         sincos (HALF_PI * buff_0, buff_1, buff_2);
         buff_2 = 1.0 - buff_2;
         horiz = lerp (buff_1, buff_2, buff_0);
      }

      buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
               (vert >= 1.0) ? uv.y / 2.0 :
               (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

      if ((cGradient == 4) || (cGradient == 6) || (cGradient == 7) || (cGradient == 9)) vert = sin (PI * buff_0);
      else {
         sincos (HALF_PI * buff_0, buff_1, buff_2);
         buff_2 = 1.0 - buff_2;
         vert = lerp (buff_1, buff_2, buff_0);
      }

      if ((cGradient == 3) || (cGradient == 4)) { gradient = lerp (topLeft, botLeft, vert); }
      else {
         gradient = lerp (topLeft, topRight, horiz);
   
         if (cGradient == 9) gradient = lerp (topLeft, gradient, vert);
         else if (cGradient > 4) {
            float4 botRow = lerp (botLeft, botRight, horiz);
            gradient = lerp (gradient, botRow, vert);
         }
      }
   }

   float nonLin = sin (Mix * PI);

   Mix *= 2.0;

   if (Mix > 1.0) {
      Mix = lerp ((2.0 - Mix), nonLin, cCurve);
      colDx = lerp (bgPix, gradient, Mix);
   }
   else {
      Mix = lerp (Mix, nonLin, cCurve);
      colDx = lerp (fgPix, gradient, Mix);
   }

   return lerp (rawDx, colDx, cAmount);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique DissolveThruColour
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

