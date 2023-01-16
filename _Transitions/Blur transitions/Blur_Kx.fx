// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect performs a blurred transition into or out of a blended foreground source.
 It has been designed from the ground up to handle varying frame sizes and aspect
 ratios.  It can be used with title effects, image keys or other blended video layer(s).

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Blur_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Blur dissolve (keyed)", "Mix", "Blur transitions", "Uses a blur to transition into or out of blended layers", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (Blurriness, "Blurriness", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI        3.1415926536
#define HALF_PI   1.5707963268

#define STRENGTH  0.005

#define SAMPLES   30
#define SAMPSCALE 61

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_blurX (sampler T, float2 uv)
{
   float4 retval = tex2D (T, uv);

   if (Blurriness > 0.0) {

      float2 blur = float2 ((1.0 - Amount) * Blurriness * STRENGTH / _OutputAspectRatio, 0.0);
      float2 xy1 = uv, xy2 = uv;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (T, xy1);
         retval += tex2D (T, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Blur_Kx_F

DeclarePass (Title_F)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

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

DeclarePass (BlurX_F)
{ return fn_blurX (Title_F, uv3); }

DeclareEntryPoint (Blur_Kx_F)
{
   float4 retval = tex2D (BlurX_F, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, (1.0 - Amount) * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (BlurX_F, xy1);
         retval += tex2D (BlurX_F, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   retval.a *= sin (saturate (Amount * 2.0) * HALF_PI);

   if (CropEdges && IsOutOfBounds (uv1)) retval = kTransparentBlack;

   return lerp (ReadPixel (Fg, uv1), retval, retval.a);
}


// technique Blur_Kx_I

DeclarePass (Title_I)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (BlurX_I)
{ return fn_blurX (Title_I, uv3); }

DeclareEntryPoint (Blur_Kx_I)
{
   float4 retval = tex2D (BlurX_I, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, (1.0 - Amount) * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (BlurX_I, xy1);
         retval += tex2D (BlurX_I, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   retval.a *= sin (saturate (Amount * 2.0) * HALF_PI);

   if (CropEdges && IsOutOfBounds (uv2)) retval = kTransparentBlack;

   return lerp (ReadPixel (Bg, uv2), retval, retval.a);
}


// technique Blur_Kx_O

DeclarePass (Title_O)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclarePass (BlurX_O)
{
   float4 retval = tex2D (Title_O, uv3);

   if (Blurriness > 0.0) {

      float2 blur = float2 (Amount * Blurriness * STRENGTH / _OutputAspectRatio, 0.0);
      float2 xy1 = uv3, xy2 = uv3;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (Title_O, xy1);
         retval += tex2D (Title_O, xy2);
      }

      retval /= SAMPSCALE;
   }

   return retval;
}

DeclareEntryPoint (Blur_Kx_O)
{
   float4 retval = tex2D (BlurX_O, uv3);

   if (Blurriness > 0.0) {

      float2 xy1 = uv3, xy2 = uv3;
      float2 blur = float2 (0.0, Amount * Blurriness * STRENGTH);

      for (int i = 0; i < SAMPLES; i++) {
         xy1 -= blur;
         xy2 += blur;
         retval += tex2D (BlurX_O, xy1);
         retval += tex2D (BlurX_O, xy2);
      }
    
      retval /= SAMPSCALE;
   }

   retval.a *= cos (saturate (Amount - 0.5) * PI);

   if (CropEdges && IsOutOfBounds (uv2)) retval = kTransparentBlack;

   return lerp (ReadPixel (Bg, uv2), retval, retval.a);
}

