// @Maintainer jwrl
// @Released 2021-12-26
// @Author jwrl
// @Author LWKS Software Ltd
// @Created 2021-08-31
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
// Update 2021-12-26 jwrl.
// Corrected colour opacity bug when the shape is inverted.
// Added opacity setting.
//
// Rewrite 2021-08-31 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Gradient shape";
   string Category    = "Matte";
   string SubCategory = "Border and Crop";
   string Notes       = "Creates colour gradients inside or outside an ellipsoid or rectangular shape";
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

#define Cropped(XY,L,R,T,B) ((XY.x <= L) || (XY.x >= R) || (XY.y <= T) || (XY.y >= B))

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Gradient, s_Colour);

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

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip geometry
// and rotation are handled without too much effort.  With 2022.1.1 it may be redundant.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_grad (float2 uv : TEXCOORD0) : COLOR
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

float4 ps_rectangle_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 Bgnd, Fgnd;

   // Recover and assign the colour and video layers appropriately

   if (Invert) {
      Bgnd = GetPixel (s_Colour, uv);
      Fgnd = GetPixel (s_Input, uv);
      Bgnd = lerp (Fgnd, Bgnd, Bgnd.a * Opacity);
   }
   else {
      Fgnd = GetPixel (s_Colour, uv);
      Bgnd = GetPixel (s_Input, uv);
      Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
   }

   // Calculate the inner rectangle boundaries

   float innerL = CentreX - (Width / (_OutputAspectRatio * 2.0));
   float innerR = innerL + Width / _OutputAspectRatio;
   float innerT = 1.0 - CentreY - (Height / 2.0);
   float innerB = innerT + Height;

   // If the current position is entirely inside the rectangle return the foreground.
   // By forcing an early quit we avoid performing redundant conditional evaluations.

   if (!Cropped (uv, innerL, innerR, innerT, innerB)) return Fgnd;

   // Now we get the softness setting, allowing for the aspect ratio

   float2 softSetting = float2 (Softness / _OutputAspectRatio, Softness);

   // Calculate the outer boundaries allowing for edge softness

   float outerL = innerL - softSetting.x;
   float outerR = innerR + softSetting.x;
   float outerT = innerT - softSetting.y;
   float outerB = innerB + softSetting.y;

   // If the current position falls entirely outside the softness range skip any further
   // processing and just return the background.

   if (Cropped (uv, outerL, outerR, outerT, outerB)) return Bgnd;

   float softness = 1.0;

   // Calculate the softness amount to mix the foreground and background

   if (uv.x < innerL) {
      if (uv.y < innerT) { softness -= length ((uv - float2 (innerL, innerT)) / softSetting); }
      else if (uv.y > innerB) { softness -= length ((uv - float2 (innerL, innerB)) / softSetting); }
      else softness = (uv.x - outerL) / softSetting.x;
   }
   else if (uv.x > innerR) {
      if (uv.y < innerT) { softness -= length ((uv - float2 (innerR, innerT)) / softSetting); }
      else if (uv.y > innerB) { softness -= length ((uv - float2 (innerR, innerB)) / softSetting); }
      else softness = (outerR - uv.x) / softSetting.x;
   }
   else if (uv.y < innerT) { softness = (uv.y - outerT) / softSetting.y; }
   else softness = (outerB - uv.y) / softSetting.y;

   // Return a mix of background and foreground depending on softness.  The softness can
   // go negative on the corners so it must be limited to zero to prevent artefacts.

   return lerp (Bgnd, Fgnd, max (softness, 0.0));
}

float4 ps_ellipse_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 Bgnd, Fgnd;

   // Recover and assign the colour and video layers appropriately

   if (Invert) {
      Bgnd = GetPixel (s_Colour, uv);
      Fgnd = GetPixel (s_Input, uv);
      Bgnd = lerp (Fgnd, Bgnd, Bgnd.a * Opacity);
   }
   else {
      Fgnd = GetPixel (s_Colour, uv);
      Bgnd = GetPixel (s_Input, uv);
      Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
   }

   // From here on is largely the original Lightworks effect

   float a = Width / (_OutputAspectRatio * 2.0);
   float b = Height / 2.0;
   float sa = a + (Softness / _OutputAspectRatio);
   float sb = b + Softness;

   float2 pos = uv - float2 (CentreX, 1.0 - CentreY);

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
/*
http://www.slader.com/discussion/question/what-is-the-equation-of-an-ellipse-in-polar-coordinates/
*/
   // I have replaced the original explicit sin() and cos() functions with sincos().  The atan2()
   // operation to produce theta has also been placed inside the sincos() function.  In the process
   // I have removed the pow() expressions used to square the sine and cosine values at the expense
   // of two new variables, ab and sab.  This simplifies the following maths slightly - I think!

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
   float softness = (length (pos) - dLower) / (dUpper - dLower);

   // Recover a mix of background and foreground depending on softness.  The softness shouldn't
   // be able to go negative but we limit it just in case.

   return lerp (Fgnd, Bgnd, max (softness, 0.0));
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique GradShape_0
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = Gradient;"; > ExecuteShader (ps_grad)
   pass P_2 ExecuteShader (ps_rectangle_main)
}

technique GradShape_1
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = Gradient;"; > ExecuteShader (ps_grad)
   pass P_2 ExecuteShader (ps_ellipse_main)
}

