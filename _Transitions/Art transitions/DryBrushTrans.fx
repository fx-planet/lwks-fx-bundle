// @Maintainer jwrl
// @Released 2023-05-16
// @Author jwrl
// @Created 2018-05-06

/**
 This mimics the Photoshop angled brush stroke effect to reveal or remove a clip.
 The stroke length and angle can be independently adjusted.  Keyframing the progress
 while the transition proceeds can also make the effect more dynamic.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DryBrushTrans.fx
//
// Version history:
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Dry brush transition", "Mix", "Art transitions", "Mimics the Photoshop angled brush effect to reveal the next video", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Length, "Stroke length", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle, "Stroke angle", kNoGroup, kNoFlags, 45.0, -180.0, 180.0);

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

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_rnd (float2 uv)
{
   return frac (sin (dot (uv - 0.5.xx, float2 (12.9898, 78.233))) * 43758.5453);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Bgnd, Fgnd = ReadPixel (Fg, uv1);

   if (Blended) {
      if ((Source == 0) && SwapDir) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (Bg, uv2);
      }
      else Bgnd = ReadPixel (Bg, uv2);

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

DeclarePass (Bgd)
{
   float4 retval;

   if (Blended && SwapDir && (Source == 0)) { retval = ReadPixel (Fg, uv1); }
   else retval = ReadPixel (Bg, uv2);

   if (!Blended) retval.a = 1.0;

   return retval;
}

DeclareEntryPoint (DryBrushTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float stroke = (Length * 0.1) + 0.02;
   float amount, angle = radians (Angle + 135.0);

   float2 xy1, xy2, xy3;

   sincos (angle, xy1.x, xy1.y);

   if (Blended) {
      amount = SwapDir ? Amount : 1.0 - Amount;
      maskBg = Bgnd;

      xy2 = fn_rnd (uv3) * stroke * (1.0 - amount);
      xy3.x = uv3.x + (xy2.x * xy1.x) + (xy2.y * xy1.y);
      xy3.y = uv3.y + (xy2.y * xy1.x) - (xy2.x * xy1.y);

      Fgnd = tex2D (Fgd, xy3);
      retval = lerp (Bgnd, Fgnd, Fgnd.a * amount);
   }
   else {
      amount = Amount;
      maskBg = Fgnd;

      xy2 = fn_rnd (uv3 - 0.5.xx) * stroke * amount;
      xy3.x = uv3.x + (xy2.x * xy1.x) + (xy2.y * xy1.y);
      xy3.y = uv3.y + (xy2.y * xy1.x) - (xy2.x * xy1.y);

      float2 xy4;

      xy2 = fn_rnd (uv3 - 0.5.xx) * stroke * (1.0 - amount);
      xy4.x = uv3.x + (xy2.x * xy1.x) + (xy2.y * xy1.y);
      xy4.y = uv3.y + (xy2.y * xy1.x) - (xy2.x * xy1.y);

      Bgnd = tex2D (Bgd, xy4);

      Fgnd = tex2D (Fgd, xy3);
      retval = lerp (Fgnd, Bgnd, Fgnd.a * amount);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

