// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This transitions a blended foreground image in or out using different curves for each of
 red, green and blue.  One colour and alpha is always linear, and the other two can be set
 using the colour profile selection.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdrifter_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("RGB drifter (keyed)", "Mix", "Colour transitions", "Mixes a blended foreground image in or out using different curves for each of red, green and blue", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (SetTechnique, "Select colour profile", kNoGroup, 0, "Red to blue|Blue to red|Red to green|Green to red|Green to blue|Blue to green");

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define CURVE 4.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   float2 uv = xy2;

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (B, xy2);
         uv = xy1;
      }
      else Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   if (CropEdges && IsOutOfBounds (uv)) Fgnd.a = 0.0;

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RGBdrifter_R_B)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg, uv1, Bg, uv2);
   float4 Bgnd   = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

DeclareEntryPoint (RGBdrifter_B_R)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg, uv1, Bg, uv2);
   float4 Bgnd   = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

DeclareEntryPoint (RGBdrifter_R_G)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_G  = pow (amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg, uv1, Bg, uv2);
   float4 Bgnd   = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

DeclareEntryPoint (RGBdrifter_G_R)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_G  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg, uv1, Bg, uv2);
   float4 Bgnd   = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

DeclareEntryPoint (RGBdrifter_G_B)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_G  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg, uv1, Bg, uv2);
   float4 Bgnd   = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

DeclareEntryPoint (RGBdrifter_B_G)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_G  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg, uv1, Bg, uv2);
   float4 Bgnd   = (Ttype == 0) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

