// @Maintainer jwrl
// @Released 2020-03-29
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
//
// Author's note: since I originally just threw resources at this to make it work it can
// almost certainly be refined,  It is by no means elegant, and if I can work out how to
// I will fix it.  The functionality will not change!!!
//
// Modified 28 March 2020 jwrl.
// Increased range of width and height to 200% to allow for aspect ratio limits.
// Added "DisplayAsPercentage" flag to width and height for version 2020+.
//
// Modified 29 March 2020 jwrl.
// Split the colour gradient sections into a separate shader.  This reduced the amount of
// redundant code in the effect without changing the functionality.
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

sampler s_Input = sampler_state { Texture = <Inp>; };
sampler s_Color = sampler_state { Texture = <Gradient>; };

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

float4 ps_grad (float2 uv : TEXCOORD0) : COLOR
{
   float2 xy = uv;

   if (!Invert) {
      // In this mode the gradient is range limited to the size of the shape.
      // We must therefore get that range into xy, including border softness

      float2 range = float2 (Width / _OutputAspectRatio, Height) / 2.0;

      range += float2 (Softness / _OutputAspectRatio, Softness);

      // Calculate the X and Y range values

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

float4 ps_main_0 (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   float4 Bgnd, Fgnd, retval;

   if (Invert) {
      // Recover and assign the colour and video layers appropriately.  In the full screen
      // (inverted) mode the colour gradient must be blended with the background to correctly
      // support the colour alpha channels.

      retval = tex2D (s_Color, xy1);
      Fgnd = tex2D (s_Input, xy1);
      Bgnd = lerp (Fgnd, retval, retval.a);
   }
   else {
      // This time the colour recovery process must respect the X/Y position so get that first.
      // It's range limited to run between 0 and 1 which in extreme cases may cause a one pixel
      // error in colour at the edge of frame.  That shouldn't be significant.

      float2 uv = saturate (xy0 + float2 (0.5 - CentreX, CentreY - 0.5));

      Fgnd = tex2D (s_Color, uv);
      Bgnd = tex2D (s_Input, xy1);
   }

   // Get the border width as set with Softness and correct it for the aspect ratio.

   float2 border = float2 (Softness / _OutputAspectRatio, Softness);

   // Get rectangle crop edges, allowing for the aspect ratio

   float top = 1.0 - CentreY - (Height / 2.0);
   float bottom = top + Height;
   float left = CentreX - (Width / (_OutputAspectRatio * 2.0));
   float right = left + (Width / _OutputAspectRatio);

   // Get the outer boundaries and extend them by the softness setting

   float outer_l = left - border.x;
   float outer_r = right + border.x;
   float outer_t = top - border.y;
   float outer_b = bottom + border.y;

   // This section is identical to the Editshare effect which wasn't commented

   if ((xy0.x >= left) && (xy0.x <= right) && (xy0.y >= top) && (xy0.y <= bottom)) {
      retval = lerp (Bgnd, Fgnd, Fgnd.a); }
   else {
      if (xy0.x < outer_l || xy0.x > outer_r || xy0.y < outer_t || xy0.y > outer_b) { retval = Bgnd; }
      else {
         float amt = 1.0;

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

         retval = lerp (Bgnd, Fgnd, max (amt, 0.0) * Fgnd.a);
      }
   }

   return retval;
}

float4 ps_main_1 (float2 xy0 : TEXCOORD0, float2 xy1 : TEXCOORD1) : COLOR
{
   float4 Bgnd, Fgnd, retval;

   if (Invert) {
      retval = tex2D (s_Color, xy0);
      Fgnd = tex2D (s_Input, xy1);
      Bgnd = lerp (Fgnd, retval, retval.a);
   }
   else {
      float2 uv = saturate (xy0 + float2 (0.5 - CentreX, CentreY - 0.5));

      Fgnd = tex2D (s_Color, uv);
      Bgnd = tex2D (s_Input, xy1);
   }

   // Get the border width and the centre of the circle/ellpise

   float2 border = float2 (Softness / _OutputAspectRatio, Softness);
   float2 uv1 = xy0 - float2 (CentreX, 1.0 - CentreY);

   // Now calulate the X and Y radii and the X and Y softness radii

   float Xradius = Width / (_OutputAspectRatio * 2.0);
   float Yradius = Height / 2.0;
   float Xsofts  = Xradius + border.x;
   float Ysofts  = Yradius + border.y;

   // Get the colour boundaries including any softness range

   float top = 1.0 - CentreY - Ysofts;
   float bottom = Ysofts - CentreY + 1.0;
   float left = CentreX - Xsofts;
   float right = CentreX + Xsofts;

   // This is my implementation of the standard equation for an ellipse: (x / a)² + (y / b)² = c.
   // First we divide both X and Y by their respective radii and square the result.

   float2 uv2 = pow (uv1 / float2 (Xradius, Yradius), 2.0);

   // We now add the squared values to each other, thus completing the equation (v1 = c).

   float v1 = uv2.x + uv2.y;

   // We repeat the equation for the X and Y softness radii (this time v2 = c).

   uv2 = pow (uv1 / float2 (Xsofts, Ysofts), 2.0);

   float v2 = uv2.x + uv2.y;

   // From here on is effectively what was done in the Editshare version, although their single
   // comment has been expanded.  Also sincos() has been used instead of separate sin() and cos().

   if (v1 < 1.0) { retval = lerp (Bgnd, Fgnd, Fgnd.a); }
   else if (v2 > 1.0) { retval = Bgnd; }
   else {
      // This next converts the ellipse into our workspace, using a method found at
      // http://www.shader.com/discussion/question/what-is-the-equation-of-an-ellipse-in-polar-coordinates/

      float Xedge, Yedge, theta = atan2 (uv1.y, uv1.x);

      sincos (theta, Xedge, Yedge);

      float Xblend = Xedge * Xsofts;
      float Yblend = Yedge * Ysofts;

      Xedge *= Xradius;
      Yedge *= Yradius;

      float dLower = (Xradius * Yradius) / sqrt ((Yedge * Yedge) + (Xedge * Xedge));
      float dUpper = (Xsofts * Ysofts) / sqrt ((Yblend * Yblend) + (Xblend * Xblend));
      float range  = length (uv1);

      retval = lerp (Bgnd, Fgnd, (1.0 - ((range - dLower) / (dUpper - dLower))) * Fgnd.a);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique GradShape_0
{
   pass P_1
   < string Script = "RenderColorTarget0 = Gradient;"; >
   { PixelShader = compile PROFILE ps_grad (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_0 (); }
}

technique GradShape_1
{
   pass P1
   < string Script = "RenderColorTarget0 = Gradient;"; >
   { PixelShader = compile PROFILE ps_grad (); }

   pass P_2
   { PixelShader = compile PROFILE ps_main_1 (); }
}
