// @Maintainer jwrl
// @Released 2023-01-31
// @Author jwrl
// @Created 2023-01-31

/**
 This effect stretches the blended foreground horizontally or vertically to transition in
 or out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
        Unlike LW transitions there is no mask, because I cannot see a reason for it.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Stretch_Fx.fx
//
// Version history:
//
// Built 2023-01-31 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Stretch transition (keyed)", "Mix", "DVE transitions", "Stretches the foreground horizontally or vertically to reveal or remove it", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 2, "At start if delta key folded|At start if non-delta unfolded|Standard transitions");
DeclareIntParam (SetTechnique, "Transition direction", kNoGroup, 0, "Stretch horizontal|Stretch vertical");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareFloatParam (Stretch, "Size", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define CENTRE  0.5.xx

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen_F (sampler F, sampler B, float2 xy)
{
   float4 Fgnd = tex2D (F, xy);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 fn_keygen (sampler F, sampler B, float2 xy)
{
   float4 Fgnd = tex2D (F, xy);

   if (Source == 0) {
      float4 Bgnd = tex2D (B, xy);

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

// technique Stretch_Fx_H

DeclarePass (Fg_H)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_H)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_H)
{ return Ttype == 0 ? fn_keygen_F (Fg_H, Bg_H, uv3) : fn_keygen (Fg_H, Bg_H, uv3); }

DeclareEntryPoint (Stretch_Fx_H)
{
   float2 uv, xy = uv3 - CENTRE;

   float4 Bgnd;

   if (Ttype == 0) {
      uv = uv1;
      Bgnd = tex2D (Fg_H, uv3);
   }
   else {
      uv = uv2;
      Bgnd = tex2D (Bg_H, uv3);
   }

   float amount  = Ttype == 2 ? Amount : 1.0 - Amount;
   float stretch = Stretch * amount;
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y  = lerp (xy.y, distort, stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv)) ? kTransparentBlack : tex2D (Super_H, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - amount));
}

//-----------------------------------------------------------------------------------------//

// technique Stretch_Fx_V

DeclarePass (Fg_V)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_V)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_V)
{ return Ttype == 0 ? fn_keygen_F (Fg_V, Bg_V, uv3) : fn_keygen (Fg_V, Bg_V, uv3); }

DeclareEntryPoint (Stretch_Fx_V)
{
   float2 uv, xy = uv3 - CENTRE;

   float4 Bgnd;

   if (Ttype == 0) {
      uv = uv1;
      Bgnd = tex2D (Fg_V, uv3);
   }
   else {
      uv = uv2;
      Bgnd = tex2D (Bg_V, uv3);
   }

   float amount  = Ttype == 2 ? Amount : 1.0 - Amount;
   float stretch = Stretch * amount;
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv)) ? kTransparentBlack : tex2D (Super_V, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a * (1.0 - amount));
}

