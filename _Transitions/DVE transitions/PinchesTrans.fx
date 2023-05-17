// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2017-09-08

/**
 This effect is a range of linear, radial and X pinches that pinch the outgoing video
 to a user-defined point to reveal the incoming shot.  It can also reverse the process
 to bring in the incoming video.

 The direction swap for the X pinch has been deliberately made asymmetric.  Subjectively
 it looked better to have the pinch established before the zoom out started, but to run
 the zoom in through the entire un-pinch process.  Trig functions are used on the effect
 progress to make the acceleration smoother.

 It can also be used to pinch an outgoing blended foreground to clear the background
 video.  It can also reverse the process to bring in the foreground.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect PinchTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Pinch transitions", "Mix", "DVE transitions", "Pinches video to a user-defined point to either hide or reveal it", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Linear pinch|Radial pinch|X pinch");

DeclareBoolParam (ChangeDir, "Change pinch direction", kNoGroup, true);

DeclareFloatParam (centreX, "Position", "Pinch centre", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (centreY, "Position", "Pinch centre", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");

DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);

DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define MID_PT     (0.5).xx
#define HALF_PI    1.5707963268
#define QUARTER_PI 0.7853981634

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (Blended) {
      if ((Source == 0) && SwapDir) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (B, xy2);
      }
      else Bgnd = ReadPixel (B, xy2);

      if (Source == 0) {
         Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
         Fgnd.rgb *= Fgnd.a;
      }
      else if (Source == 1) {
         Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
         Fgnd.rgb /= Fgnd.a;
      }

      if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;
   }
   else Fgnd.a = 1.0;

   return Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 retval;

   if (Blended && SwapDir && (Source == 0)) { retval = ReadPixel (F, xy1); }
   else retval = ReadPixel (B, xy2);

   if (!Blended) retval.a = 1.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique PinchTrans_L

DeclarePass (Fg_L)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_L)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Pinch_L)
{
   float4 Fgnd = tex2D (Fg_L, uv3);
   float4 Bgnd = tex2D (Bg_L, uv3);
   float4 maskBg, retval;

   float2 centre, scale, xy;

   float amount;

   if (Blended) {
      maskBg = Bgnd;
      amount = Amount * 0.5;

      if (SwapDir) {
         amount += 0.5;

         centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, amount);
         xy = (uv3 - centre) * (1.0 + pow ((1.0 - sin (amount * HALF_PI)), 4.0) * 128.0);
         scale = pow (abs (xy * 2.0), -cos ((amount + 0.01) * HALF_PI));
      }
      else {
         centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), amount);
         xy = (uv3 - centre) * (1.0 + pow ((1.0 - cos (amount * HALF_PI)), 4.0) * 128.0);
         scale = pow (abs (xy * 2.0), -sin (amount * HALF_PI));
      }

      xy *= scale;
      xy += MID_PT;

      Fgnd = ReadPixel (Fg_L, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }
   else {
      maskBg = Fgnd;

      if (ChangeDir) {
         centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
         xy = (uv3 - centre) * (1.0 + pow ((1.0 - sin (Amount * HALF_PI)), 4.0) * 128.0);
         scale = pow (abs (xy * 2.0), -cos ((Amount + 0.01) * HALF_PI));

         xy *= scale;
         xy += MID_PT;

         retval = ReadPixel (Bg_L, xy);
         retval = lerp (Fgnd, retval, retval.a);
      }
      else {
          centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);
          xy = (uv3 - centre) * (1.0 + pow ((1.0 - cos (Amount * HALF_PI)), 4.0) * 128.0);
          scale = pow (abs (xy * 2.0), -sin (Amount * HALF_PI));

         xy *= scale;
         xy += MID_PT;

         retval = ReadPixel (Fg_L, xy);
         retval = lerp (Bgnd, retval, retval.a);
      }
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique PinchTrans_R

DeclarePass (Fg_R)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (PinchTrans_R)
{
   float4 Fgnd = tex2D (Fg_R, uv3);
   float4 Bgnd = tex2D (Bg_R, uv3);
   float4 maskBg, retval;

   float2 xy;

   float progress, rfrnc, scale;

   if (Blended) {
      maskBg = lerp (Bgnd, Fgnd, Fgnd.a);

      if (SwapDir) {
         progress = (1.0 - Amount) / 2.14;
         rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
         scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);
      }
      else {
         progress = Amount / 2.14;
         rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
         scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);
      }

      xy = (uv3 - MID_PT) * scale;
      xy *= scale;
      xy += MID_PT;

      Fgnd = ReadPixel (Fg_R, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }
   else {
      maskBg = Fgnd;

      progress = ChangeDir ? Amount / 2.14 : (1.0 - Amount) / 2.14;
      rfrnc = (distance (uv3, MID_PT) * 32.0) + 1.0;
      scale = lerp (1.0, pow (rfrnc, -1.0) * 24.0, progress);

      xy  = (uv3 - MID_PT) * scale;
      xy *= scale;
      xy += MID_PT;

      if (ChangeDir) {
         retval = ReadPixel (Fg_R, xy);
         retval = lerp (Bgnd, retval, retval.a);
      }
      else {
         retval = ReadPixel (Bg_R, xy);
         retval = lerp (Fgnd, retval, retval.a);
      }
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique PinchTrans_X

DeclarePass (Fg_X)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_X)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Pinch)
{
   float progress, amount = SwapDir ? 1.0 - Amount : Amount;

   if (Blended) { progress = sin (amount * QUARTER_PI); }
   else progress = ChangeDir ? sin (Amount * HALF_PI) : cos (Amount * HALF_PI);

   float dist  = (distance (uv3, MID_PT) * 32.0) + 1.0;
   float scale = lerp (1.0, pow (dist, -1.0) * 24.0, progress);

   float2 xy = ((uv3 - MID_PT) * scale) + MID_PT;

   return !(Blended || ChangeDir) ? ReadPixel (Bg_X, xy) : ReadPixel (Fg_X, xy);
}

DeclareEntryPoint (xPinch_Fx_I)
{
   float4 Fgnd = tex2D (Fg_X, uv3);
   float4 Bgnd = tex2D (Bg_X, uv3);
   float4 maskBg, retval;

   float progress;

   if (Blended) {
      maskBg = Bgnd;

      if (SwapDir) { progress = 1.0 - cos (sin ((1.0 - Amount) * QUARTER_PI)); }
      else progress = 1.0 - cos (sin (Amount * QUARTER_PI));
   }
   else {
      maskBg = Fgnd;

      if (ChangeDir) { progress = 1.0 - cos (max (0.0, Amount - 0.25) * HALF_PI); }
      else {
         progress = 1.0 - sin (Amount * HALF_PI);
         Bgnd = Fgnd;
      }
   }

   float scale = 1.0 + (progress * (32.0 + progress * 32.0));

   float2 xy = ((uv3 - MID_PT) * scale) + MID_PT;

   Fgnd = ReadPixel (Pinch, xy);
   retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

