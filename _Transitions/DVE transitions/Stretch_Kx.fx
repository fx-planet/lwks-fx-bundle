// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This effect stretches the blended foreground horizontally or vertically to transition in
 or out.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Stretch_Fx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
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
DeclareIntParam (SetTechnique, "Transition position", kNoGroup, 0, "H start (delta folded)|V start (delta folded)|At start (horizontal)|At end (horizontal)|At start (vertical)|At end (vertical)");

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

float4 fn_keygen_F (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      float4 Bgnd = ReadPixel (B, xy2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique Hstretch_Fx_F

DeclarePass (Super_Hf)
{ return fn_keygen_F (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Horiz_F)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Super_Hf, xy);

   return lerp (ReadPixel (Fg, uv1), Fgnd, Fgnd.a * Amount);
}


// technique Vstretch_Fx_F

DeclarePass (Super_Vf)
{ return fn_keygen_F (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Vert_F)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : ReadPixel (Super_Vf, xy);

   return lerp (ReadPixel (Fg, uv1), Fgnd, Fgnd.a * Amount);
}


// technique Hstretch_Fx_I

DeclarePass (Super_Hi)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Horiz_I)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_Hi, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * Amount);
}


// technique Hstretch_Fx_O

DeclarePass (Super_Ho)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Horiz_O)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y  = lerp (xy.y, distort, stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_Ho, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * (1.0 - Amount));
}


// technique Vstretch_Fx_I

DeclarePass (Super_Vi)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Vert_I)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_Vi, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * Amount);
}


// technique Vstretch_Fx_O

DeclarePass (Super_Vo)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Vert_O)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x  = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : ReadPixel (Super_Vo, xy);

   return lerp (ReadPixel (Bg, uv2), Fgnd, Fgnd.a * (1.0 - Amount));
}

