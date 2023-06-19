// @Maintainer jwrl
// @Released 2023-06-14
// @Author jwrl
// @Created 2018-06-13

/**
 This mimics the Lightworks squeeze effect but transitions alpha and delta keys in or out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SqueezeTrans.fx
//
// Version history:
//
// Updated 2023-06-14 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
// Changed subcategory from "DVE transitions" to "Transform transitions".
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Squeeze transition", "Mix", "Transform transitions", "Mimics the Lightworks squeeze effect with the blended foreground", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Type", kNoGroup, 0, "Squeeze Right|Squeeze Down|Squeeze Left|Squeeze Up");

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Crawl/Roll/Title/Image key|Video/External image");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (B, xy2);
      Bgnd = ReadPixel (F, xy1);
   }
   else {
      Fgnd = ReadPixel (F, xy1);
      Bgnd = ReadPixel (B, xy2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// SqueezeRight

DeclarePass (Fg_R)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeRight)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_R, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
                              : float2 ((uv3.x - 1.0) / (1.0 - Amount) + 1.0, uv3.y);
      }
      else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 (uv3.x / Amount, uv3.y);

      Bgnd = tex2D (Bg_R, uv3);
      Fgnd = ReadPixel (Fg_R, xy);
   }

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// SqueezeDown

DeclarePass (Fg_D)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_D)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeDown)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_D, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / (1.0 - Amount) + 1.0);
      }
      else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y / Amount);

      Bgnd = tex2D (Bg_D, uv3);
      Fgnd = ReadPixel (Fg_D, xy);
   }

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// SqueezeLeft

DeclarePass (Fg_L)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_L)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeLeft)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_L, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (2.0, uv3.y) : float2 (uv3.x  / (1.0 - Amount), uv3.y);
      }
      else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 ((uv3.x - 1.0) / Amount + 1.0, uv3.y);

      Bgnd = tex2D (Bg_L, uv3);
      Fgnd = ReadPixel (Fg_L, xy);
   }

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// SqueezeUp

DeclarePass (Fg_U)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_U)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeUp)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_U, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y  / (1.0 - Amount));
      }
      else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / Amount + 1.0);

      Bgnd = tex2D (Bg_U, uv3);
      Fgnd = ReadPixel (Fg_U, xy);
   }

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

