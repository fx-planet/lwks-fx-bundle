// @Maintainer jwrl
// @Released 2021-12-28
// @Author jwrl
// @Created 2021-12-28
// @see https://forum.lwks.com/attachments/vignettegrade_640-png.40173/

/**
 It may not look much like it, but this effect is built around the Lightworks effect
 "Simple 2D Shape".  In this version additional parameters have been added to perform
 a limited amount of colour grading inside the vignette shape.  Gamma, contrast, gain,
 brightness and saturation can be adjusted as you would expect with a colourgrade tool.

 In addition it's possible to independently adjust the saturation of midtones, blacks
 and whites.  The individual red, green and blue values of the grade can also be fine
 tuned, and the full grade can display either inside or outside the 2D shape.  Finally
 the grade opacity can be adjusted to fade the effect in or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VignetteGrade.fx
//
// Based on shapes3.fx, copyright (c) LWKS Software Ltd.  All Rights Reserved
//
// Version history:
//
// Created 2021-12-28 jwrl.
// Based on VignetteGrade, which is in turn based on the Lightworks effect shown above.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Graded vignette";
   string Category    = "Colour";
   string SubCategory = "Colour Tools";
   string Notes       = "Performs colour grades inside or outside an ellipsoid or rectangular shape";
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

#define PI 3.1415926536

float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Inputs and targets
//-----------------------------------------------------------------------------------------//

DefineInput (Inp, s_RawInp);

DefineTarget (FixInp, s_Input);
DefineTarget (Grade, s_Grade);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Shape";
   string Enum = "Rectangle,Ellipse";
> = 1;

float Opacity
<
   string Description = "Opacity";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

bool Invert
<
   string Group = "Vignette";
   string Description = "Invert mask";
> = false;

float CentreX
<
   string Group = "Vignette";
   string Description = "Position";
   string Flags = "SpecifiesPointX|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float CentreY
<
   string Group = "Vignette";
   string Description = "Position";
   string Flags = "SpecifiesPointY|DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 2.0;
> = 0.5;

float Width
<
   string Group = "Vignette";
   string Description = "Width";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 0.5;

float Height
<
   string Group = "Vignette";
   string Description = "Height";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 0.5;

float Softness
<
   string Group = "Vignette";
   string Description = "Softness";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 0.5;
> = 0.0;

float Gamma
<
   string Group = "Master levels";
   string Description = "Gamma";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Contrast
<
   string Group = "Master levels";
   string Description = "Contrast";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Gain
<
   string Group = "Master levels";
   string Description = "Gain";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Brightness
<
   string Group = "Master levels";
   string Description = "Brightness";
   string Flags = "DisplayAsPercentage";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;

float Saturation
<
   string Group = "Master levels";
   string Description = "Saturation";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_W
<
   string Group = "Saturation zones";
   string Description = "Whites";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_M
<
   string Group = "Saturation zones";
   string Description = "Mids";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Saturate_B
<
   string Group = "Saturation zones";
   string Description = "Blacks";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Trim_R
<
   string Group = "RGB fine tuning";
   string Description = "Red trim";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Trim_G
<
   string Group = "RGB fine tuning";
   string Description = "Green trim";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

float Trim_B
<
   string Group = "RGB fine tuning";
   string Description = "Blue trim";
   string Flags = "DisplayAsPercentage";
   float MinVal = 0.0;
   float MaxVal = 2.0;
> = 1.0;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 fn_hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// This pass maps the foreground clip to TEXCOORD2, so that variations in clip geometry
// and rotation are handled without too much effort.  With 2022.1.1 it may be redundant.

float4 ps_initInp (float2 uv : TEXCOORD1) : COLOR { return GetPixel (s_RawInp, uv); }

float4 ps_grade (float2 uv : TEXCOORD2) : COLOR
{
   // This grading operation is done in the HSV domain because it makes life a lot easier
   // when dealing with saturation.  Immediately we get the video we convert it.

   float4 inp = GetPixel (s_Input, uv);
   float4 hsv = fn_rgb2hsv (inp);

   // Now we obtain the three overlapping grading zones.

   float mids = 0.5 + (cos (smoothstep (0.0, 0.5, abs (0.5 - hsv.z)) * PI) * 0.5);
   float high = (hsv.z > 0.5) ? 1.0 - mids : 0.0;
   float lows = (hsv.z < 0.5) ? 1.0 - mids : 0.0;

   // Saturation is now adjusted in the three zones, then the master saturation
   // is applied.

   hsv.y = lerp (hsv.y, hsv.y * Saturate_W, high);
   hsv.y = lerp (hsv.y, hsv.y * Saturate_M, mids);
   hsv.y = lerp (hsv.y, hsv.y * Saturate_B, lows);
   hsv.y = hsv.y * Saturation;

   // Now we adjust the luminance gamma, gain, brightness and contrast

   hsv.z = ((((pow (hsv.z, 1.0 / Gamma) * Gain) + Brightness) - 0.5) * Contrast) + 0.5;

   // The graded RGB version is now recovered into retval, and the amount red, green and
   // blue adjustment is set.  Then we ensure that retval is legal and return.

   float4 retval = fn_hsv2rgb (hsv);

   retval.r = lerp (inp.r, retval.r, Trim_R);
   retval.g = lerp (inp.g, retval.g, Trim_G);
   retval.b = lerp (inp.b, retval.b, Trim_B);
   retval.a = inp.a;

   return saturate (retval);
}

float4 ps_rectangle_main (float2 uv : TEXCOORD2) : COLOR
{
   float4 Bgnd, Fgnd;

   // Recover and assign the colour and video layers appropriately

   if (Invert) {
      Fgnd = GetPixel (s_Grade, uv);
      Bgnd = GetPixel (s_Input, uv);
      Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
   }
   else {
      Bgnd = GetPixel (s_Grade, uv);
      Fgnd = GetPixel (s_Input, uv);
      Bgnd = lerp (Fgnd, Bgnd, Bgnd.a * Opacity);
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
      Fgnd = GetPixel (s_Grade, uv);
      Bgnd = GetPixel (s_Input, uv);
      Fgnd = lerp (Bgnd, Fgnd, Fgnd.a * Opacity);
   }
   else {
      Bgnd = GetPixel (s_Grade, uv);
      Fgnd = GetPixel (s_Input, uv);
      Bgnd = lerp (Fgnd, Bgnd, Bgnd.a * Opacity);
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

technique VignetteGrade_0
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = Grade;"; > ExecuteShader (ps_grade)
   pass P_2 ExecuteShader (ps_rectangle_main)
}

technique VignetteGrade_1
{
   pass Pin < string Script = "RenderColorTarget0 = FixInp;"; > ExecuteShader (ps_initInp)
   pass P_1 < string Script = "RenderColorTarget0 = Grade;"; > ExecuteShader (ps_grade)
   pass P_2 ExecuteShader (ps_ellipse_main)
}

