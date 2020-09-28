// @Maintainer jwrl
// @Released 2020-09-28
// @Author jwrl
// @Author LWKS Software Ltd
// @Created 2020-03-29
// @see https://www.lwks.com/media/kunena/attachments/6375/GradShape_640.png

/**
 This effect is built around the Lightworks effect "Simple 2D Shape".  In this version 3
 additional colour parameters have been added to allow a colour gradient to be produced
 inside the shape.  The horizontal and vertical linearity of the gradient can be adjusted,
 and the full gradient will display inside the 2D shape, regardless of the size of the
 shape and the amount of softness applied.

 Another addition is a means of inverting the shape to reveal the background video over
 the colour gradient.  In that mode the gradient functions in a similar way to Lightworks'
 "Corner Gradient" effect, and occupies the full frame.  The linearity in that mode is
 adjustable in the same way as the non-inverted version.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GradShape.fx
//
// Based on shapes3.fx, copyright (c) LWKS Software Ltd.  All Rights Reserved
//
// This began as the original Lightworks effect, with an additional shader added to create
// the gradient.  A preamble was added to both the rectangle and ellipse shaders to allow
// the gradient to be used as either the inner or outer area of the frame.
//
// Version history:
//
// Update 2020-09-28 jwrl.
// Reformatted header block.
//
// Modified April 2 2020 jwrl:
// Restructured the rectangle and ellipse shaders to simplify the execution slightly.
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
      // therefore scale xy by the range, adding an allowance for border softness.

      float2 range = float2 (Width / _OutputAspectRatio, Height) / 2.0;

      range += float2 (Softness / _OutputAspectRatio, Softness);

      // Add the range to xy and simultaneously adjust it for position, then divide
      // by double the range value.  Doing this scales xy to fit the shape boundaries.

      xy += range - float2 (CentreX, 1.0 - CentreY);
      xy /= range + range;
   }

   // Calculate the X and Y gradient linearity

   float linearity = Hlin < 0.0 ? 1.0 / (1.0 + (2.0 * abs (Hlin))) : 1.0 + (2.0 * Hlin);

   // Set up the X gradient linearity and use it to offset the mix value

   float amount = pow (xy.x, linearity);

   // Create upper and lower edge colour gradients

   float4 retval = lerp (TLcolour, TRcolour, amount);
   float4 retsub = lerp (BLcolour, BRcolour, amount);

   // Now set up the Y gradient linearity

   linearity = Vlin < 0.0 ? 1.0 + (2.0 * abs (Vlin)) : 1.0 / (1.0 + (2.0 * Vlin));
   amount = pow (xy.y, linearity);

   // Use it to return the composite XY colour gradient

   return lerp (retval, retsub, amount);
}

float4 ps_rectangle_main (float2 xy : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   // Recover and assign the colour and video layers appropriately

   float4 temp = tex2D (s_Colour, xy);
   float4 Bgnd = tex2D (s_Input, xy1);
   float4 Fgnd = lerp (Bgnd, temp, temp.a);

   if (Invert) {
      // In full screen (inverted) mode the colour gradient and background are swapped.

      temp = Bgnd;
      Bgnd = Fgnd;
      Fgnd = temp;
   }

   // Calculate the inner rectangle boundaries

   float innerL = CentreX - (Width / (_OutputAspectRatio * 2.0));
   float innerR = innerL + Width / _OutputAspectRatio;
   float innerT = 1.0 - CentreY - (Height / 2.0);
   float innerB = innerT + Height;

   // If the current position is entirely inside the rectangle return the foreground.
   // By forcing an early quit we avoid performing redundant conditional evaluations.

   if ((xy.x >= innerL) && (xy.x <= innerR) && (xy.y >= innerT) && (xy.y <= innerB)) return Fgnd;

   // Now we get the softness, allowing for the aspect ratio

   float2 softness = float2 (Softness / _OutputAspectRatio, Softness);

   // Calculate the outer boundaries allowing for edge softness

   float outerL = innerL - softness.x;
   float outerR = innerR + softness.x;
   float outerT = innerT - softness.y;
   float outerB = innerB + softness.y;

   // If the current position falls entirely outside the softness mix return the background.

   if ((xy.x < outerL) || (xy.x > outerR) || (xy.y < outerT) || (xy.y > outerB)) return Bgnd;

   float amount = 1.0;

   // Calculate the amount to mix the foreground and background

   if (xy.x < innerL) {
      if (xy.y < innerT) { amount -= length ((xy - float2 (innerL, innerT)) / softness); }
      else if (xy.y > innerB) { amount -= length ((xy - float2 (innerL, innerB)) / softness); }
      else amount = (xy.x - outerL) / softness.x;
   }
   else if (xy.x > innerR) {
      if (xy.y < innerT) { amount -= length ((xy - float2 (innerR, innerT)) / softness); }
      else if (xy.y > innerB) { amount -= length ((xy - float2 (innerR, innerB)) / softness); }
      else amount = (outerR - xy.x) / softness.x;
   }
   else if (xy.y < innerT) { amount = (xy.y - outerT) / softness.y; }
   else amount = (outerB - xy.y) / softness.y;

   // Return a mix of background and foreground depending on softness.  The mix amount can
   // go negative on the corners so it must be limited to zero to prevent artefacts there.

   return lerp (Bgnd, Fgnd, max (amount, 0.0));
}

float4 ps_ellipse_main (float2 xy : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   float4 temp = tex2D (s_Colour, xy);
   float4 Bgnd = tex2D (s_Input, xy1);
   float4 Fgnd = lerp (Bgnd, temp, temp.a);

   if (Invert) {
      temp = Bgnd;
      Bgnd = Fgnd;
      Fgnd = temp;
   }

   // From here on is largely the original Lightworks effect

   float a = Width / (_OutputAspectRatio * 2.0);
   float b = Height / 2.0;

   float sa = a + (Softness / _OutputAspectRatio);
   float sb = b + Softness;

   float2 pos = xy - float2 (CentreX, 1.0 - CentreY);

   // https://www.mathwarehouse.com/ellipse/equation-of-ellipse.php
   //
   // ((x * x) / (a * a)) + ((y * y) / (b * b)) = 1
   //

   float2 posSq = pos * pos;

   // Somewhat restructured code from here on, so I've commented what I've done - jwrl.

   // Check whether the current position is within the ellipse range, i.e., < 1.0

   float range = (posSq.x / (a * a)) + (posSq.y / (b * b));

   // If the current position is entirely within the ellipse we return the foreground.

   if (range < 1.0) return Fgnd;

   // Now calculate whether the position is outside the legal ellipse range including softness

   range = (posSq.x / (sa * sa)) + (posSq.y / (sb * sb));

   // If it's entirely outside the soft edge of the ellipse we return the background.

   if (range > 1.0) return Bgnd;

   // http://www.slader.com/discussion/question/what-is-the-equation-of-an-ellipse-in-polar-coordinates/

   // I have replaced the original explicit sin() and cos() functions with sincos().  The atan2()
   // operation to produce theta has also been placed inside the sincos() function.  In the process
   // I have removed the pow() expressions used to square the sine and cosine values at the expense
   // of two new variables, ab and sab.  This simplifies the calculations slightly - I think!

   float ab  = a * b;
   float sab = sa * sb;
   float cosTheta, sinTheta;

   sincos (atan2 (pos.y, pos.x), sinTheta, cosTheta);
   a  *= sinTheta;
   b  *= cosTheta;
   sa *= sinTheta;
   sb *= cosTheta;

   float dLower = ab / sqrt ((a * a) + (b * b));
   float dUpper = sab / sqrt ((sa * sa) + (sb * sb));
   float amount = (length (pos) - dLower) / (dUpper - dLower);

   return lerp (Fgnd, Bgnd, amount);
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
