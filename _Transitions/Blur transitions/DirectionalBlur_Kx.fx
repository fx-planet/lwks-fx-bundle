// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This effect applies a directional (motion) blur to a blended foreground, the angle
 and strength of which can be adjusted.  It then progressively reduces the blur to
 reveal the blended foreground or increases it as it fades the blend out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DirectionalBlur_Kx.fx
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Directional blur dissolve (keyed)", "Mix", "Blur transitions", "Directionally blurs the foreground as it fades in or out", CanSize);

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

DeclareFloatParam (Spread, "Spread", "Blur settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle, "Angle", "Blur settings", kNoFlags, 0.0, -180.00, 180.0);
DeclareFloatParam (Strength, "Strength", "Blur settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI        3.1415926536

#define SAMPLES   30
#define SAMPSCALE 61

#define STRENGTH  0.005

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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique DirectionalBlur_Kx_F

DeclarePass (Bg_F)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Title_F)
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

DeclareEntryPoint (DirectionalBlur_Kx_F)
{
   float4 retval = tex2D (Title_F, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle), blur.y, blur.x);
      blur   *= (1.0 - saturate (Amount)) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (Title_F, xy1);
         retval += tex2D (Title_F, xy2);
      }

   retval /= SAMPSCALE;
   }

   retval.a *= saturate (((Amount - 0.5) * ((Strength * 3.0) + 1.5)) + 0.5);

   if (CropEdges && IsOutOfBounds (uv1)) retval = kTransparentBlack;

   return lerp (tex2D (Bg_F, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique DirectionalBlur_Kx_I

DeclarePass (Bg_I)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_I)
{ return fn_keygen (Bg_I, uv1, uv3); }

DeclareEntryPoint (DirectionalBlur_Kx_I)
{
   float4 retval = tex2D (Title_I, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle), blur.y, blur.x);
      blur   *= (1.0 - saturate (Amount)) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (Title_I, xy1);
         retval += tex2D (Title_I, xy2);
      }

   retval /= SAMPSCALE;
   }

   retval.a *= saturate (((Amount - 0.5) * ((Strength * 3.0) + 1.5)) + 0.5);

   if (CropEdges && IsOutOfBounds (uv2)) retval = kTransparentBlack;

   return lerp (tex2D (Bg_I, uv3), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique DirectionalBlur_Kx_O

DeclarePass (Bg_O)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Title_O)
{ return fn_keygen (Bg_O, uv1, uv3); }

DeclareEntryPoint (DirectionalBlur_Kx_O)
{
   float4 retval = tex2D (Title_O, uv3);

   if (Spread > 0.0) {

      float2 blur, xy1 = uv3, xy2 = uv3;

      sincos (radians (Angle + 180.0), blur.y, blur.x);
      blur   *= saturate (Amount) * Spread * STRENGTH;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < SAMPLES; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (Title_O, xy1);
         retval += tex2D (Title_O, xy2);
      }

   retval /= SAMPSCALE;
   }

   retval.a *= 1.0 - saturate (((Amount - 0.5) * ((Strength * 3.0) + 1.5)) + 0.5);

   if (CropEdges && IsOutOfBounds (uv2)) retval = kTransparentBlack;

   return lerp (tex2D (Bg_O, uv3), retval, retval.a);
}

