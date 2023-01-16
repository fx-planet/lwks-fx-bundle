// @Maintainer jwrl
// @Released 2023-01-16
// @Author jwrl
// @Created 2023-01-16

/**
 This rotates a blended foreground such as a title or image key out or in.  It's a
 combination of the functionality of two previous effects, Rotate_Ax and Rotate_Adx.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Rotating_Kx.fx
//
// Version history:
//
// Built 2023-01-16 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Rotating trans (keyed)", "Mix", "Geometric transitions", "Rotates a title, image key or other blended foreground in or out", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Source, "Source", kNoGroup, 0, "Extracted foreground (delta key)|Crawl/Roll/Title/Image key|Video/External image");
DeclareIntParam (Ttype, "Transition position", kNoGroup, 0, "At start if delta key folded|At start of effect|At end of effect");

DeclareBoolParam (CropEdges, "Crop effect to background", kNoGroup, false);

DeclareIntParam (SetTechnique, "Transition type", kNoGroup, 0, "Rotate Right|Rotate Down|Rotate Left|Rotate Up");

DeclareFloatParam (KeyGain, "Key trim", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (Source == 0) {
      if (Ttype == 0) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (B, xy2);
      }
      else Bgnd = ReadPixel (B, xy2);

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

// technique Rotate_Right

DeclarePass (Super_R)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Rotate_Right)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0, ((uv3.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.y) * uv3.x * sin (Amount * HALF_PI));
      Bgnd = ReadPixel (Bg, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x / Amount) - ((1.0 - Amount) * 0.2), ((uv3.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.y) * uv3.x * cos (Amount * HALF_PI));

      if (Ttype == 0) {
         Bgnd = ReadPixel (Fg, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = ReadPixel (Bg, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_R, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Rotate_Down

DeclarePass (Super_D)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Rotate_Down)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.x) * uv3.y * sin (Amount * HALF_PI), (uv3.y - 1.0) / (1.0 - Amount) - (Amount * 0.2) + 1.0);
      Bgnd = ReadPixel (Bg, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.x) * uv3.y * cos (Amount * HALF_PI), (uv3.y / Amount) - ((1.0 - Amount) * 0.2));

      if (Ttype == 0) {
         Bgnd = ReadPixel (Fg, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = ReadPixel (Bg, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_D, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Rotate_Left

DeclarePass (Super_L)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Rotate_Left)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (uv3.x / (1.0 - Amount) + (Amount * 0.2), ((uv3.y - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.y) * (1.0 - uv3.x) * sin (Amount * HALF_PI));
      Bgnd = ReadPixel (Bg, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 ((uv3.x - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2), ((uv3.y - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.y) * (1.0 - uv3.x) * cos (Amount * HALF_PI));

      if (Ttype == 0) {
         Bgnd = ReadPixel (Fg, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = ReadPixel (Bg, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_L, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}


// technique Rotate_Up

DeclarePass (Super_U)
{ return fn_keygen (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Rotate_Up)
{
   float4 Bgnd;

   float2 xy, bgd;

   if (Ttype == 2) {
      xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) * (1.0 + Amount)) + 0.5 + (0.5 - uv3.x) * (1.0 - uv3.y) * sin (Amount * HALF_PI), uv3.y / (1.0 - Amount) + (Amount * 0.2));
      Bgnd = ReadPixel (Bg, uv2);
      bgd = uv2;
   }
   else {
      xy = (Amount == 0.0) ? float2 (2.0, uv3.y)
         : float2 (((uv3.x - 0.5) / (2.0 - Amount)) + 0.5 + (0.5 - uv3.x) * (1.0 - uv3.y) * cos (Amount * HALF_PI), (uv3.y - 1.0) / Amount + 1.0 + ((1.0 - Amount) * 0.2));

      if (Ttype == 0) {
         Bgnd = ReadPixel (Fg, uv1);
         bgd = uv1;
      }
      else {
         Bgnd = ReadPixel (Bg, uv2);
         bgd = uv2;
      }
   }

   float4 Fgnd = (CropEdges && IsOutOfBounds (bgd)) ? kTransparentBlack : ReadPixel (Super_U, xy);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

