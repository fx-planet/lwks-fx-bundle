// @Maintainer jwrl
// @Released 2023-02-01
// @Author Robert Schütze
// @Author jwrl
// @Created 2022-06-01

/**
 This effect uses a fractal-like pattern to transition between two sources.  It supports
 titles and other blended effects.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
 Unlike with LW transitions there is no mask.  Instead the ability to crop the effect
 to the background is provided, which dissolves between the cropped areas during the
 transition.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fractal_Kx.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Schütze (trirop) 07.12.2015.  This effect is a combination of two earlier effects,
// Fractals_Ax.fx and Fractals_Adx.fx.
//
// Version history:
//
// Built 2023-02-01 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Fractal dissolve (keyed)", "Mix", "Abstract transitions", "Uses a fractal-like pattern to transition between two sources", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta|Standard transitions");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (fractalOffset, "Offset", "Fractal settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Rate, "Rate", "Fractal settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Border, "Edge size", "Fractal settings", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Feather, "Feather", "Fractal settings", kNoFlags, 0.1, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler B, float2 xy1, float2 xy2)
{
   float4 Fgnd = ReadPixel (Fg, xy1);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_fractal (float2 uv)
{
   float3 offset  = float3 (1.0.xx, Amount * Rate * 0.5);
   float3 fractal = float3 (uv.x / _OutputAspectRatio, uv.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - offset)));
   }

   return float4 (saturate (fractal), 1.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Fractal_Kx_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Super_F)
{
   float4 Fgnd = tex2D (Bg_F, uv3);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (Bg, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

DeclarePass (Fractal_F)
{ return fn_fractal (uv0); }

DeclareEntryPoint (Fractal_Kx_F)
{
   float4 Ovly = tex2D (Fractal_F, uv3);
   float4 Fgnd = tex2D (Super_F, uv3);
   float4 Bgnd = tex2D (Bg_F, uv3);

   float amount  = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + Feather)) return Bgnd;

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / Feather;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Fgnd : lerp (Fgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Bgnd, fracAmt); }

   retval = lerp (Bgnd, retval, Fgnd.a);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Fractal_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclarePass (Fractal_I)
{ return fn_fractal (uv0); }

DeclareEntryPoint (Fractal_Kx_I)
{
   float4 Ovly = tex2D (Fractal_I, uv3);
   float4 Fgnd = tex2D (Super_I, uv3);
   float4 Bgnd = tex2D (Bg_I, uv3);

   float amount  = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + Feather)) return Bgnd;

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / Feather;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Fgnd : lerp (Fgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Bgnd, fracAmt); }

   retval = lerp (Bgnd, retval, Fgnd.a);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Fractal_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclarePass (Fractal_O)
{ return fn_fractal (uv0); }

DeclareEntryPoint (Fractal_Kx_O)
{
   float4 Ovly = tex2D (Fractal_O, uv3);
   float4 Fgnd = tex2D (Super_O, uv3);
   float4 Bgnd = tex2D (Bg_O, uv3);

   float amount = (Amount + 3.0) / 4.0;
   float fractal = saturate (Ovly.a * ((amount * 0.666667) + 0.333333));

   if (fractal > (amount + Feather)) return ReadPixel (Fg, uv1);

   float bdWidth = Border * 0.1;
   float fracAmt = (fractal - amount) / Feather;

   float4 retval = (fractal <= (Amount - bdWidth)) ? Bgnd : lerp (Bgnd, Ovly, fracAmt);

   if (fractal > (Amount + bdWidth)) { retval = lerp (retval, Fgnd, fracAmt); }

   retval = lerp (Bgnd, retval, Fgnd.a);

   if (CropEdges) {
      Fgnd = IsOutOfBounds (uv1) ? kTransparentBlack : retval;
      Bgnd = IsOutOfBounds (uv2) ? kTransparentBlack : retval;

      retval = lerp (Fgnd, Bgnd, 1.0 - Amount);
   }

   return retval;
}

