// @Maintainer jwrl
// @Released 2023-01-28
// @Author jwrl
// @Created 2023-01-28

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
// Built 2023-01-28 jwrl.
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

float4 fn_keygen_F (sampler F, sampler B, float2 xy)
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

// technique Hstretch_Fx_F

DeclarePass (Fg_Hf)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_Hf)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Hf)
{ return fn_keygen_F (Fg_Hf, Bg_Hf, uv3); }

DeclareEntryPoint (Horiz_F)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_Hf, xy);

   return lerp (tex2D (Fg_Hf, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Vstretch_Fx_F

DeclarePass (Fg_Vf)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_Vf)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Vf)
{ return fn_keygen_F (Fg_Vf, Bg_Vf, uv3); }

DeclareEntryPoint (Vert_F)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv1)) ? kTransparentBlack : tex2D (Super_Vf, xy);

   return lerp (tex2D (Fg_Vf, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Hstretch_Fx_I

DeclarePass (Fg_Hi)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_Hi)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Hi)
{ return fn_keygen_F (Fg_Hi, Bg_Hi, uv3); }

DeclareEntryPoint (Horiz_I)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y = lerp (xy.y, distort, stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_Hi, xy);

   return lerp (tex2D (Bg_Hi, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Hstretch_Fx_O

DeclarePass (Fg_Ho)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_Ho)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Ho)
{ return fn_keygen_F (Fg_Ho, Bg_Ho, uv3); }

DeclareEntryPoint (Horiz_O)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.y * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x /= 1.0 + (5.0 * stretch);
   xy.y  = lerp (xy.y, distort, stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_Ho, xy);

   return lerp (tex2D (Bg_Ho, uv3), Fgnd, Fgnd.a * (1.0 - Amount));
}

//-----------------------------------------------------------------------------------------//

// technique Vstretch_Fx_I

DeclarePass (Fg_Vi)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_Vi)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Vi)
{ return fn_keygen_F (Fg_Vi, Bg_Vi, uv3); }

DeclareEntryPoint (Vert_I)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * (1.0 - Amount);
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_Vi, xy);

   return lerp (tex2D (Bg_Vi, uv3), Fgnd, Fgnd.a * Amount);
}

//-----------------------------------------------------------------------------------------//

// technique Vstretch_Fx_O

DeclarePass (Fg_Vo)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg_Vo)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Super_Vo)
{ return fn_keygen_F (Fg_Vo, Bg_Vo, uv3); }

DeclareEntryPoint (Vert_O)
{
   float2 xy = uv3 - CENTRE;

   float stretch = Stretch * Amount;
   float distort = sin (xy.x * PI) * HALF_PI;

   distort = sin (distort) / 2.0;

   xy.x  = lerp (xy.x, distort, stretch);
   xy.y /= 1.0 + (5.0 * stretch);
   xy += CENTRE;

   float4 Fgnd = (CropEdges && IsOutOfBounds (uv2)) ? kTransparentBlack : tex2D (Super_Vo, xy);

   return lerp (tex2D (Bg_Vo, uv3), Fgnd, Fgnd.a * (1.0 - Amount));
}

