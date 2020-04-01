// @Maintainer jwrl
// @Released 2020-04-01
// @Author jwrl
// @Author Editshare
// @Created 2020-03-29
// @see https://www.lwks.com/media/kunena/attachments/6375/GradShape_640.png

/**
 This effect is built around Editshare's effect "Simple 2D Shape".  In this version three
 additional colour parameters have been added to allow a colour gradient to be produced
 inside the shape.  The horizontal and vertical linearity of the gradient can be adjusted,
 and the full gradient will display inside the 2D shape, regardless of the size of the
 shape and the amount of softness applied.

 Another addition is a means of inverting the shape to reveal the background video over
 the colour gradient.  In that mode the gradient functions in a similar way to Editshare's
 "Corner Gradient" effect, and occupies the full frame.  The linearity in that mode is
 adjustable in the same way as the non-inverted version.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GradShape.fx
//
// Based on shapes3.fx, copyright (c) EditShare EMEA.  All Rights Reserved
//
// This is just the original Editshare effect, with an additional shader added to create
// the gradient.  A preamble has been added to both the rectangle and ellipse shaders to
// allow the gradient to be used as either the inner or outer area of the frame.
//
// Modified April 1 2020 jwrl:
// Corrected a bug that meant that scaling beyond full screen could return an incorrect
// colour address if the position was panned up or left.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Gradient shape";
   string Category    = "Matte";
   string SubCategory = "Border and Crop";
   string Notes       = "Creates colour gradients inside or outside an ellipsoid or rectangular shape";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Inp;

texture Gradient : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Input  = sampler_state { Texture = <Inp>; };
sampler s_Colour = sampler_state { Texture = <Gradient>; };

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Shape";
   string Enum = "Rectangle,Ellipse";
> = 0;

float CentreX
<
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float CentreY
<
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Width
<
   string Description = "Width";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 0.5;

float Height
<
   string Description = "Height";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 0.5;

float Softness
<
   string Description = "Softness";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.01;

float4 TLcolour
<
   string Description = "Top left";
   string Group = "Colours";
   bool SupportsAlpha = true;
> = { 1.0, 0.17, 0.0, 1.0 };

float4 TRcolour
<
   string Description = "Top right";
   string Group = "Colours";
   bool SupportsAlpha = true;
> = { 0.66, 0.0, 1.0, 1.0 };

float4 BLcolour
<
   string Description = "Bottom left";
   string Group = "Colours";
   bool SupportsAlpha = true;
> = { 0.33, 1.0, 0.0, 1.0 };

float4 BRcolour
<
   string Description = "Bottom right";
   string Group = "Colours";
   bool SupportsAlpha = true;
> = { 0.0, 0.83, 1.0, 1.0 };

float Hlin
<
   string Description = "Gradient linearity";
   string Group = "Colours";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 0.5;
> = 0.0;

float Vlin
<
   string Description = "Gradient linearity";
   string Group = "Colours";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -0.5;
   float MaxVal = 0.5;
> = 0.0;

bool Invert
<
   string Description = "Invert mask";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_make_gradient (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = uv;

   if (!Invert) {
      // In this mode the gradient is range limited to the size of the shape.  We
      // therefore get that range into xy, including border softness and position.

      float2 range = float2 (Width / _OutputAspectRatio, Height) / 2.0;

      range += float2 (Softness / _OutputAspectRatio, Softness);

      // Calculate the X and Y range values allowing for position

      xy += float2 (0.5 - CentreX, CentreY - 0.5);
      xy += range - 0.5.xx;
      range += range;
      xy /= range;
   }

   // Calculate the X and Y gradient linearity

   float X_linearity = Hlin < 0.0 ? 1.0 / (1.0 + (2.0 * abs (Hlin))) : 1.0 + (2.0 * Hlin);
   float Y_linearity = Vlin < 0.0 ? 1.0 + (2.0 * abs (Vlin)) : 1.0 / (1.0 + (2.0 * Vlin));

   // Set up the X gradient amount, allowing for the gradient linearity

   float amt = pow (xy.x, X_linearity);

   // Create upper and lower edge colour gradients

   float4 retval = lerp (TLcolour, TRcolour, amt);
   float4 retsub = lerp (BLcolour, BRcolour, amt);

   // Now set up the Y gradient amount

   amt = pow (xy.y, Y_linearity);

   // Use it to return the composite colour gradient

   return lerp (retval, retsub, amt);
}

float4 ps_rectangle_main (float2 xy : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   // Recover and assign the colour and video layers appropriately

   float4 FGColour = tex2D (s_Colour, xy);
   float4 ret, bg = tex2D (s_Input, xy1);

   if (Invert) {
      // In full screen (inverted) mode the colour gradient must be blended with the background
      // in advance to correctly support the colour alpha channels.

      ret = bg;
      bg = lerp (ret, FGColour, FGColour.a);
      FGColour = ret;
   }

   // From here on is the original Editshare effect

   // Calc exact rectangle bounds

   float l = CentreX - (Width / (_OutputAspectRatio * 2.0));
   float r = l + Width / _OutputAspectRatio;
   float t = 1.0 - CentreY - (Height / 2.0);
   float b = t + Height;

   if (xy.x >= l && xy.x <= r && xy.y >= t && xy.y <= b) { ret = lerp (bg, FGColour, FGColour.a); }
   else {
      float2 softness = float2 (Softness / _OutputAspectRatio, Softness);

      // calc outer bounds

      float l2 = l - softness.x;
      float r2 = r + softness.x;
      float t2 = t - softness.y;
      float b2 = b + softness.y;

      if (xy.x < l2 || xy.x > r2 || xy.y < t2 || xy.y > b2) { ret = bg; }
      else {
         float amt = 1.0;

         if (xy.x < l) {
            if (xy.y < t) { amt = 1.0 - (length ((xy - float2 (l, t)) / softness)); }
            else if (xy.y > b) { amt = 1.0 - (length ((xy - float2 (l, b)) / softness)); }
            else amt = (xy.x - l2) / softness.x;
         }
         else if (xy.x > r) {
            if (xy.y < t) { amt = 1.0 - (length ((xy - float2 (r, t)) / softness)); }
            else if (xy.y > b) { amt = 1.0 - (length ((xy - float2 (r, b)) / softness)); }
            else amt = (r2 - xy.x) / softness.x;
         }
         else if (xy.y < t) { amt = (xy.y - t2) / softness.y; }
         else amt = (b2 - xy.y) / softness.y;

         ret = lerp (bg, FGColour, max (amt, 0.0) * FGColour.a);
      }
   }

   return ret;
}

float4 ps_ellipse_main (float2 xy : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   float4 FGColour = tex2D (s_Colour, xy);
   float4 ret, bg = tex2D (s_Input, xy1);

   if (Invert) {
      ret = bg;
      bg = lerp (ret, FGColour, FGColour.a);
      FGColour = ret;
   }

   // From here on is the original Editshare effect

   float a = Width / (_OutputAspectRatio * 2.0);
   float b = Height / 2.0;

   float sa = ((Width / _OutputAspectRatio) / 2.0) + (Softness / _OutputAspectRatio);
   float sb = (Height / 2.0) + Softness;

   float2 pos = xy - float2 (CentreX, 1.0 - CentreY);

   // https://www.mathwarehouse.com/ellipse/equation-of-ellipse.php
   //
   // ((x * x) / (a * a)) + ((y * y) / (b * b)) = 1
   //

   float2 posSq = pos * pos;

   float v1 = (posSq.x / (a * a)) + (posSq.y / (b * b));
   float v2 = (posSq.x / (sa * sa)) + (posSq.y / (sb * sb));

   if (v1 < 1.0) { ret = lerp (bg, FGColour, FGColour.a); }
   else if (v2 > 1.0) { ret = bg; }
   else {
      // http://www.slader.com/discussion/question/what-is-the-equation-of-an-ellipse-in-polar-coordinates/

      float theta = atan2 (pos.y, pos.x);

      float cosThetaSq = pow (cos (theta), 2.0);
      float sinThetaSq = pow (sin (theta), 2.0);

      float dLower = (a * b) / sqrt ((b *  b * cosThetaSq) + (a * a * sinThetaSq));
      float dUpper = (sa * sb) / sqrt ((sb * sb * cosThetaSq) + (sa * sa * sinThetaSq));
      float d      = length (pos);

      ret = lerp (bg, FGColour, (1.0 - ((d - dLower) / (dUpper - dLower))) * FGColour.a);
   }

   return ret;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique GradShape_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Gradient;"; >
   { PixelShader = compile PROFILE ps_make_gradient (); }

   pass P_2
   { PixelShader = compile PROFILE ps_rectangle_main (); }
}

technique GradShape_1
{
   pass P1
   < string Script = "RenderColorTarget0 = Gradient;"; >
   { PixelShader = compile PROFILE ps_make_gradient (); }

   pass P_2
   { PixelShader = compile PROFILE ps_ellipse_main (); }
}
