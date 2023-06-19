// @Maintainer jwrl
// @Released 2023-06-08
// @Author rakusan
// @Author jwrl
// @Created 2016-02-15

/**
 The effect applies a rotary blur to transition into and out of aan image, and is
 based on original shader code by rakusan (http://kuramo.ch/webgl/videoeffects/).
 The direction, aspect ratio, centring and strength of the blur can all be adjusted.
 It can also be used with titles and other blended images.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SpinTrans.fx
//
// Version history:
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Spin transition", "Mix", "Blur transitions", "Dissolves the images through a blurred spin", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (CW_CCW, "Rotation direction", "Spin", 1, "Anticlockwise|Clockwise");

DeclareFloatParam (blurLen, "Arc (degrees)", "Spin", kNoFlags, 90.0, 0.0, 180.0);
DeclareFloatParam (aspectRatio, "Aspect ratio 1:x", "Spin", kNoFlags, 1.0, 0.01, 10.0);

DeclareFloatParam (CentreX, "Centre", "Spin", "SpecifiesPointX", 0.5, -0.5, 1.5);
DeclareFloatParam (CentreY, "Centre", "Spin", "SpecifiesPointY", 0.5, -0.5, 1.5);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RANGE_1    24
#define RANGE_2    48
#define RANGE_3    72
#define RANGE_4    96
#define RANGE_5    120

#define SAMPLES    120
#define INC_OFFSET 1.0 / SAMPLES
#define RETSCALE   (SAMPLES + 1) / 2.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_FgBlur (sampler F, float2 uv, int base)
{
   int range = base + RANGE_1;

   float blurAngle, Tcos, Tsin;
   float spinAmt  = (radians (blurLen * saturate (Amount + 0.04))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (F, uv);
   float4 image  = retval;

   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * base;

   for (int i = base; i < range; i++) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (F, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   return retval /= RETSCALE;
}

float4 fn_BgBlur (sampler B, float2 uv, int base)
{
   int range = base - RANGE_1;

   float blurAngle, Tcos, Tsin;
   float spinAmt  = (radians (blurLen * saturate (0.96 - Amount))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (B, uv);
   float4 image  = retval;

   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * (1 - base);

   for (int i = base; i > range; i--) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (B, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   return retval /= RETSCALE;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, 0.25, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.5); }
/*
   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }
*/
   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclarePass (Rot_1)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_5) : fn_FgBlur (Fgd, uv3, 0); }

DeclarePass (Rot_2)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_4) : fn_FgBlur (Fgd, uv3, RANGE_1); }

DeclarePass (Rot_3)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_3) : fn_FgBlur (Fgd, uv3, RANGE_2); }

DeclarePass (Rot_4)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_2) : fn_FgBlur (Fgd, uv3, RANGE_3); }

DeclarePass (Fblur)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_1) : fn_FgBlur (Fgd, uv3, RANGE_4); }

DeclarePass (Spin1)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_5); }

DeclarePass (Spin2)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_4); }

DeclarePass (Spin3)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_3); }

DeclarePass (Spin4)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_2); }

DeclarePass (Bblur)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_1); }

DeclareEntryPoint (SpinTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 Fg_vid = tex2D (Fblur, uv3);
   float4 maskBg, retval;

   Fg_vid += tex2D (Rot_1, uv3) + tex2D (Rot_2, uv3);
   Fg_vid += tex2D (Rot_3, uv3) + tex2D (Rot_4, uv3);

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         float amount = SwapDir ? Amount * _LengthFrames / (_LengthFrames - 1.0) : 1.0 - Amount;

         Fg_vid *= 1.4585;
         retval = lerp (Fgnd, Fg_vid, saturate ((1.0 - amount) * 8.0));
         retval.a *= amount;
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      retval  = tex2D (Bblur, uv3);
      retval += tex2D (Spin1, uv3) + tex2D (Spin2, uv3);
      retval += tex2D (Spin3, uv3) + tex2D (Spin4, uv3);
      retval  = lerp (Bgnd, retval, saturate ((1.0 - Amount) * 8.0));
      Fg_vid  = lerp (Fgnd, Fg_vid, saturate (Amount * 8.0));

      float mix = (Amount - 0.5) * 2.0;

      mix = (1.0 + (abs (mix) * mix)) / 2.0;
      retval = lerp (Fg_vid, retval, mix);
      maskBg = Fgnd;
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

