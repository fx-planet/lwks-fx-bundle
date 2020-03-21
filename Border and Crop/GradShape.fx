// @Maintainer jwrl
// @Released 2020-03-20
// @Author jwrl
// @Author Editshare
// @Created 2020-03-20
// @see https://www.lwks.com/media/kunena/attachments/6375/GradShape_640.png

/**
 This effect is based on Editshare's effect "Simple 2D Shape", although it has had a fair
 amount of reworking.  In this version three additional colour parameters have been added
 to allow a colour gradient to be produced inside the shape.  The horizontal and vertical
 linearity of the gradient can be adjusted, and the full gradient will display inside the
 2D shape, regardless of the size of the shape and the amount of softness applied.

 Another addition is a means of inverting the shape to reveal the background video over
 the colour gradient.  In that mode the gradient functions in a similar way to Editshare's
 "Corner Gradient" effect, and occupies the full frame.  The linearity in that mode is
 adjustable in the same way as the non-inverted version.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GradShape.fx
//
// Based on shapes3.fx, copyright (c) EditShare EMEA.  All Rights Reserved
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
// Inputs and Samplers
//-----------------------------------------------------------------------------------------//

texture Inp;

sampler s_Input = sampler_state { Texture = <Inp>; };

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
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Height
<
   string Description = "Height";
   float MinVal = 0.0;
   float MaxVal = 1.0;
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

float4 ps_main_0 (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   float2 border = float2 (1.0 / _OutputAspectRatio, 1.0) * Softness;

   // Get rectangle crop edges

   float top = 1.0 - CentreY - (Height / 2.0);
   float bottom = top + Height;
   float left = CentreX - (Width / (_OutputAspectRatio * 2.0));
   float right = left + (Width / _OutputAspectRatio);

   // Get outer boundaries caused by softness setting

   float outer_l = left - border.x;
   float outer_r = right + border.x;
   float outer_t = top - border.y;
   float outer_b = bottom + border.y;

   // Calculate the X and Y linearity

   float X_linearity = Hlin < 0.0 ? 1.0 / (1.0 + (2.0 * abs (Hlin))) : 1.0 + (2.0 * Hlin);
   float Y_linearity = Vlin < 0.0 ? 1.0 + (2.0 * abs (Vlin)) : 1.0 / (1.0 + (2.0 * Vlin));
   float amt;

   float4 Bgnd, colour, retval;

   if (Invert) {
      // Calculate the X mix amount (amt), allowing for the X linearity

      amt = pow (xy0.x, X_linearity);

      // Get the bottom and top colour gradients

      colour = lerp (BLcolour, BRcolour, amt);
      retval = lerp (TLcolour, TRcolour, amt);

      // Combine them to produce a vertical gradient

      amt = pow (xy0.y, Y_linearity);
      retval = lerp (retval, colour, amt);

      // Now assign the colour and video layers appropriately.  In this mode the colour gradient
      // must be premixed with the background to correctly support the colour alpha channels.

      colour = tex2D (s_Input, xy1);
      Bgnd   = lerp (colour, retval, retval.a);
   }
   else {
      // This time amt is scaled between the left and right edges of frame.

      amt = pow ((xy0.x - outer_l) / (outer_r - outer_l), X_linearity);

      colour = lerp (BLcolour, BRcolour, amt);
      retval = lerp (TLcolour, TRcolour, amt);

      // Now amt is scaled between the top and bottom of frame

      amt = pow ((xy0.y - outer_t) / (outer_b - outer_t), Y_linearity);

      // The colour and Bgnd values are reversed so that the shape is a solid overlaying
      // the video frame.  This also means that we don't need to premix Bgnd this time.

      colour = lerp (retval, colour, amt);
      Bgnd = tex2D (s_Input, xy1);
   }

   if ((xy0.x >= left) && (xy0.x <= right) && (xy0.y >= top) && (xy0.y <= bottom)) {
      retval = lerp (Bgnd, colour, colour.a); }
   else {
      if (xy0.x < outer_l || xy0.x > outer_r || xy0.y < outer_t || xy0.y > outer_b) { retval = Bgnd; }
      else {
         amt = 1.0;

         if (xy0.x < left) {
            if (xy0.y < top) { amt -= (length ((xy0 - float2 (left, top)) / border)); }
            else if (xy0.y > bottom) { amt -= (length ((xy0 - float2 (left, bottom)) / border)); }
            else amt = (xy0.x - outer_l) / border.x;
         }
         else if (xy0.x > right) {
            if (xy0.y < top) { amt -= (length ((xy0 - float2 (right, top)) / border)); }
            else if (xy0.y > bottom) { amt -= (length ((xy0 - float2 (right, bottom)) / border)); }
            else amt = (outer_r - xy0.x) / border.x;
         }
         else if (xy0.y < top) { amt = (xy0.y - outer_t) / border.y; }
         else amt = (outer_b - xy0.y) / border.y;

         retval = lerp (Bgnd, colour, max (amt, 0.0) * colour.a);
      }
   }

   return retval;
}

float4 ps_main_1 (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   float2 border = float2 (1.0 / _OutputAspectRatio, 1.0) * Softness;
   float2 uv1 = xy0 - float2 (CentreX, 1.0 - CentreY);

   // Get the X and Y radii

   float Xradius = Width / (_OutputAspectRatio * 2.0);
   float Yradius = Height / 2.0;
   float Xsofts  = Xradius + (Softness / _OutputAspectRatio);
   float Ysofts  = Yradius + Softness;

   // Get the colour boundaries including softness setting

   float top = 1.0 - CentreY - Ysofts;
   float bottom = Ysofts - CentreY + 1.0;
   float left = CentreX - Xsofts;
   float right = CentreX + Xsofts;

   float X_linearity = Hlin < 0.0 ? 1.0 / (1.0 + (2.0 * abs (Hlin))) : 1.0 + (2.0 * Hlin);
   float Y_linearity = Vlin < 0.0 ? 1.0 + (2.0 * abs (Vlin)) : 1.0 / (1.0 + (2.0 * Vlin));
   float amt;

   float4 Bgnd, colour, retval;

   if (Invert) {
      amt = pow (xy0.x, X_linearity);

      colour = lerp (BLcolour, BRcolour, amt);
      retval = lerp (TLcolour, TRcolour, amt);

      amt = pow (xy0.y, Y_linearity);
      retval = lerp (retval, colour, amt);

      colour = tex2D (s_Input, xy1);
      Bgnd   = lerp (colour, retval, retval.a);
   }
   else {
      amt = pow ((xy0.x - left) / (right - left), X_linearity);

      colour = lerp (BLcolour, BRcolour, amt);
      retval = lerp (TLcolour, TRcolour, amt);

      amt = pow ((xy0.y - top) / (bottom - top), Y_linearity);

      colour = lerp (retval, colour, amt);
      Bgnd = tex2D (s_Input, xy1);
   }

   // This is an implementation of the standard equation for an ellipse: (x / a)² + (y / b)² = c.

   float2 uv2 = pow (uv1 / float2 (Xradius, Yradius), 2.0);

   float v1 = uv2.x + uv2.y;

   // We now repeat the process for the feathered boundary

   uv2 = pow (uv1 / float2 (Xsofts, Ysofts), 2.0);

   float v2 = uv2.x + uv2.y;

   if (v1 < 1.0) { retval = lerp (Bgnd, colour, colour.a); }
   else if (v2 > 1.0) { retval = Bgnd; }
   else {
      // This next converts the ellipse to our workspace, using a method found at
      // http://www.shader.com/discussion/question/what-is-the-equation-of-an-ellipse-in-polar-coordinates/

      float theta  = atan2 (uv1.y, uv1.x);
      float Xedge  = sin (theta);
      float Yedge  = cos (theta);
      float Xblend = Xedge * Xsofts;
      float Yblend = Yedge * Ysofts;

      Xedge *= Xradius;
      Yedge *= Yradius;

      float dLower = (Xradius * Yradius) / sqrt ((Yedge * Yedge) + (Xedge * Xedge));
      float dUpper = (Xsofts * Ysofts) / sqrt ((Yblend * Yblend) + (Xblend * Xblend));
      float range  = length (uv1);

      retval = lerp (Bgnd, colour, (1.0 - ((range - dLower) / (dUpper - dLower))) * colour.a);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique GradShape_0
{
   pass P1 { PixelShader = compile PROFILE ps_main_0 (); }
}

technique GradShape_1
{
   pass P1 { PixelShader = compile PROFILE ps_main_1 (); }
}

