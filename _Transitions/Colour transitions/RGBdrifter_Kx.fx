// @Maintainer jwrl
// @Released 2023-02-01
// @Author jwrl
// @Created 2023-02-01

/**
 This transitions a blended foreground image in or out using different curves for each of
 red, green and blue.  One colour and alpha is always linear, and the other two can be set
 using the colour profile selection.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdrifter_Kx.fx
//
// Version history:
//
// Built 2023-02-01 jwrl.
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
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key|At start if non-delta|Standard transitions");

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

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Bgnd, Fgnd = tex2D (F, xy);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = tex2D (B, xy);
      }
      else Bgnd = tex2D (B, xy);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   if (CropEdges && IsOutOfBounds (xy)) Fgnd.a = 0.0;

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_Kx_R_B

DeclarePass (Fg_R_B)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_R_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_R_B)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg_R_B, Bg_R_B, uv3);
   float4 Bgnd   = (Ttype == 0) ? tex2D (Fg_R_B, uv3) : tex2D (Bg_R_B, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_Kx_B_R

DeclarePass (Fg_B_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_B_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_B_R)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg_B_R, Bg_B_R, uv3);
   float4 Bgnd   = (Ttype == 0) ? tex2D (Fg_B_R, uv3) : tex2D (Bg_B_R, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_Kx_R_G

DeclarePass (Fg_R_G)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_R_G)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_R_G)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (1.0 - amount, CURVE);
   float amt_G  = pow (amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg_R_G, Bg_R_G, uv3);
   float4 Bgnd   = (Ttype == 0) ? tex2D (Fg_R_G, uv3) : tex2D (Bg_R_G, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (vidIn.r, Bgnd.r, amt_R);
   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_Kx_G_R

DeclarePass (Fg_G_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_G_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_G_R)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_R  = pow (amount, CURVE);
   float amt_G  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg_G_R, Bg_G_R, uv3);
   float4 Bgnd   = (Ttype == 0) ? tex2D (Fg_G_R, uv3) : tex2D (Bg_G_R, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.r = lerp (Bgnd.r, vidIn.r, amt_R);
   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_Kx_G_B

DeclarePass (Fg_G_B)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_G_B)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_G_B)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_G  = pow (1.0 - amount, CURVE);
   float amt_B  = pow (amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg_G_B, Bg_G_B, uv3);
   float4 Bgnd   = (Ttype == 0) ? tex2D (Fg_G_B, uv3) : tex2D (Bg_G_B, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (vidIn.g, Bgnd.g, amt_G);
   retval.b = lerp (Bgnd.b, vidIn.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdrifter_Kx_B_G

DeclarePass (Fg_B_G)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_B_G)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (RGBdrifter_B_G)
{
   float amount = (Ttype == 2) ? 1.0 - Amount : Amount;
   float amt_G  = pow (amount, CURVE);
   float amt_B  = pow (1.0 - amount, CURVE);

   float4 Fgnd   = fn_keygen (Fg_B_G, Bg_B_G, uv3);
   float4 Bgnd   = (Ttype == 0) ? tex2D (Fg_B_G, uv3) : tex2D (Bg_B_G, uv3);
   float4 vidIn  = lerp (Bgnd, Fgnd, Fgnd.a);
   float4 retval = lerp (Bgnd, vidIn, amount);

   retval.g = lerp (Bgnd.g, vidIn.g, amt_G);
   retval.b = lerp (vidIn.b, Bgnd.b, amt_B);
   Fgnd.a   = (Fgnd.a > 0.0) ? lerp (Fgnd.a, 1.0, amount) : 0.0;

   return lerp (Bgnd, retval, Fgnd.a);
}

