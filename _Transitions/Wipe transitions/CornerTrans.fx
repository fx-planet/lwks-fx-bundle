// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2017-08-25

/**
 This is a four-way split which moves the image to or from the corners of the frame.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect CornerTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Corner split transition", "Mix", "Wipe transitions", "Splits an image four ways to or from the corners of the frame", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition", kNoGroup, 0, "Corner open|Corner close");

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

#define OPEN false
#define SHUT true

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

float4 fn_trans (sampler V, float2 uv, bool mode)
{
   float posAmt = mode ? Amount : 1.0 - Amount;
   float negAmt = posAmt / 2.0;

   posAmt = 1.0 - negAmt;

   float2 xy1 = uv - posAmt.xx + 0.5.xx;
   float2 xy2 = float2 (uv.x - negAmt + 0.5, xy1.y);
   float2 xy3 = float2 (xy1.x, uv.y - negAmt + 0.5);
   float2 xy4 = float2 (xy2.x, xy3.y);

   return (uv.x > posAmt) && (uv.y > posAmt) ? tex2D (V, xy1) :
          (uv.x < negAmt) && (uv.y > posAmt) ? tex2D (V, xy2) :
          (uv.x > posAmt) && (uv.y < negAmt) ? tex2D (V, xy3) :
          (uv.x < negAmt) && (uv.y < negAmt) ? tex2D (V, xy4) : kTransparentBlack;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Open

DeclarePass (Fg_0)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_0)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Open)
{
   float4 Fgnd = tex2D (Fg_0, uv3);
   float4 Bgnd = tex2D (Bg_0, uv3);
   float4 maskBg, retval;

   if (Blended) {
      maskBg = Bgnd;
      Fgnd = fn_trans (Fg_0, uv3, SwapDir);
   }
   else {
      maskBg = Fgnd;
      Fgnd = fn_trans (Fg_0, uv3, OPEN);
   }

   retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique Shut

DeclarePass (Fg_1)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_1)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Shut)
{
   float4 Fgnd = tex2D (Fg_1, uv3);
   float4 Bgnd = tex2D (Bg_1, uv3);
   float4 maskBg, retval;

   if (Blended) {
      maskBg = Bgnd;
      Fgnd = fn_trans (Fg_1, uv3, SwapDir);
      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }
   else {
      maskBg = Fgnd;
      Bgnd = fn_trans (Bg_1, uv3, SHUT);
      retval = lerp (Fgnd, Bgnd, Bgnd.a);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

