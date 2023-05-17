// @Maintainer jwrl
// @Released 2023-05-17
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
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Squeeze transition", "Mix", "DVE transitions", "Mimics the Lightworks squeeze effect with the blended foreground", CanSize);

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

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

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

   return Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{ return SwapDir && (Source == 0) ? ReadPixel (F, xy1) : ReadPixel (B, xy2); }

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// SqueezeRight

DeclarePass (Fg_R)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SqueezeRight)
{
   float2 xy;

   if (!SwapDir) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
                           : float2 ((uv3.x - 1.0) / (1.0 - Amount) + 1.0, uv3.y);
   }
   else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 (uv3.x / Amount, uv3.y);

   float4 Bgnd = tex2D (Bg_R, uv3);
   float4 Fgnd = ReadPixel (Fg_R, xy);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// SqueezeDown

DeclarePass (Fg_D)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_D)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SqueezeDown)
{
   float2 xy;

   if (!SwapDir) {
      xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / (1.0 - Amount) + 1.0);
   }
   else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y / Amount);

   float4 Bgnd = tex2D (Bg_D, uv3);
   float4 Fgnd = ReadPixel (Fg_D, xy);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// SqueezeLeft

DeclarePass (Fg_L)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_L)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SqueezeLeft)
{
   float2 xy;

   if (!SwapDir) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y) : float2 (uv3.x  / (1.0 - Amount), uv3.y);
   }
   else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 ((uv3.x - 1.0) / Amount + 1.0, uv3.y);

   float4 Bgnd = tex2D (Bg_L, uv3);
   float4 Fgnd = ReadPixel (Fg_L, xy);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// SqueezeUp

DeclarePass (Fg_U)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_U)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SqueezeUp)
{
   float2 xy;

   if (!SwapDir) {
      xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y  / (1.0 - Amount));
   }
   else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / Amount + 1.0);

   float4 Bgnd = tex2D (Bg_U, uv3);
   float4 Fgnd = ReadPixel (Fg_U, xy);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Mask, uv3).x);
}

