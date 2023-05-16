// @Maintainer jwrl
// @Released 2023-05-17
// @Author jwrl
// @Created 2018-04-14

/**
 This transitions two images or a blended foreground image in or out using different curves
 for each of red, green and blue.  One colour and alpha is always linear, and the other two
 can be set using the colour profile selection.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBdriftTrans.fx
//
// Version history:
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("RGB drift transition", "Mix", "Colour transitions", "Mixes sources using different curves for each of red, green and blue", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Select colour profile", kNoGroup, 0, "Red to blue|Blue to red|Red to green|Green to red|Green to blue|Blue to green");

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

#define CURVE 4.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_setFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Blended) {
      float4 Bgnd = ReadPixel (B, xy2);

      if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
      else {
         if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

         Fgnd.rgb = SwapDir ? Bgnd.rgb : lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a);
      }
      Fgnd.a = pow (Fgnd.a, 0.1);
   }
   else Fgnd.a = 1.0;

   return Fgnd;
}

float4 fn_setBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = ReadPixel (B, xy2);

   if (Blended && SwapDir) {

      if (Source > 0) {
         float4 Fgnd = ReadPixel (F, xy1);

         if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

         Bgnd = lerp (Bgnd, Fgnd, Fgnd.a);
      }
   }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique RGBdriftTrans_R_B

DeclarePass (Fg_R_B)
{ return fn_setFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R_B)
{ return fn_setBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (RGBdriftTrans_R_B)
{
   float4 Fgnd = tex2D (Fg_R_B, uv3);
   float4 Bgnd = tex2D (Bg_R_B, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float amt_R = pow (1.0 - Amount, CURVE);
      float amt_B = pow (Amount, CURVE);

      retval.ga = lerp (Fgnd.ga, Bgnd.ga, Amount);
      retval.r  = lerp (Bgnd.r, Fgnd.r, amt_R);
      retval.b  = lerp (Fgnd.b, Bgnd.b, amt_B);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdriftTrans_B_R

DeclarePass (Fg_B_R)
{ return fn_setFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_B_R)
{ return fn_setBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (RGBdriftTrans_B_R)
{
   float4 Fgnd = tex2D (Fg_B_R, uv3);
   float4 Bgnd = tex2D (Bg_B_R, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float amt_R = pow (Amount, CURVE);
      float amt_B = pow (1.0 - Amount, CURVE);

      retval.ga = lerp (Fgnd.ga, Bgnd.ga, Amount);
      retval.r  = lerp (Fgnd.r, Bgnd.r, amt_R);
      retval.b  = lerp (Bgnd.b, Fgnd.b, amt_B);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdriftTrans_R_G

DeclarePass (Fg_R_G)
{ return fn_setFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R_G)
{ return fn_setBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (RGBdriftTrans_R_G)
{
   float4 Fgnd = tex2D (Fg_R_G, uv3);
   float4 Bgnd = tex2D (Bg_R_G, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float amt_R = pow (1.0 - Amount, CURVE);
      float amt_G = pow (Amount, CURVE);

      retval.ba = lerp (Fgnd.ba, Bgnd.ba, Amount);
      retval.r  = lerp (Bgnd.r, Fgnd.r, amt_R);
      retval.g  = lerp (Fgnd.g, Bgnd.g, amt_G);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdriftTrans_G_R

DeclarePass (Fg_G_R)
{ return fn_setFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_G_R)
{ return fn_setBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (RGBdriftTrans_G_R)
{
   float4 Fgnd = tex2D (Fg_G_R, uv3);
   float4 Bgnd = tex2D (Bg_G_R, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float amt_R = pow (Amount, CURVE);
      float amt_G = pow (1.0 - Amount, CURVE);

      retval.ba = lerp (Fgnd.ba, Bgnd.ba, Amount);
      retval.r  = lerp (Fgnd.r, Bgnd.r, amt_R);
      retval.g  = lerp (Bgnd.g, Fgnd.g, amt_G);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdriftTrans_G_B

DeclarePass (Fg_G_B)
{ return fn_setFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_G_B)
{ return fn_setBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (RGBdriftTrans_G_B)
{
   float4 Fgnd = tex2D (Fg_G_B, uv3);
   float4 Bgnd = tex2D (Bg_G_B, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float amt_G = pow (1.0 - Amount, CURVE);
      float amt_B = pow (Amount, CURVE);

      retval.ra = lerp (Fgnd.ra, Bgnd.ra, Amount);
      retval.g  = lerp (Bgnd.g, Fgnd.g, amt_G);
      retval.b  = lerp (Fgnd.b, Bgnd.b, amt_B);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

//-----------------------------------------------------------------------------------------//

// technique RGBdriftTrans_B_G

DeclarePass (Fg_B_G)
{ return fn_setFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_B_G)
{ return fn_setBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (RGBdriftTrans_B_G)
{
   float4 Fgnd = tex2D (Fg_B_G, uv3);
   float4 Bgnd = tex2D (Bg_B_G, uv3);
   float4 maskBg = Blended && !SwapDir ? Bgnd : Fgnd;
   float4 retval = Bgnd;

   if (Fgnd.a > 0.0) {
      float amt_G = pow (Amount, CURVE);
      float amt_B = pow (1.0 - Amount, CURVE);

      retval.ra = lerp (Fgnd.ra, Bgnd.ra, Amount);
      retval.g  = lerp (Fgnd.g, Bgnd.g, amt_G);
      retval.b  = lerp (Bgnd.b, Fgnd.b, amt_B);
   }

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}

